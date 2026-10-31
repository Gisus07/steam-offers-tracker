# Fase de investigación — Steam Offers Tracker v2

Fecha: 2026-10-31. Objetivo: confirmar si es viable un sistema personal que notifique descuentos de Steam (nombre, % de descuento, precio antes/después, fecha de fin, link a la tienda) y aprenda de mis gustos, sin scraping pesado.

Leyenda: **[verificado]** = probado en vivo desde un contenedor en esta fecha. **[docs]** = sale de documentación oficial o specs. **[no verificado]** = fuentes secundarias, falta comprobar.

---

## Veredicto

Es viable, y más barato de lo que hacía la v1. Steam expone un endpoint sin API key (`IStoreQueryService/Query`) que devuelve **todos los juegos en oferta con precio original, final, %, fecha de fin y tags**. Un barrido completo son **15 requests en ~30 s**. No hace falta Puppeteer ni navegador headless.

---

## 1. Fuente de datos

### 1.1 Fuente principal: `IStoreQueryService/Query/v1` [verificado]

```
GET https://api.steampowered.com/IStoreQueryService/Query/v1/?input_json=<json>
```

```json
{
  "query": {
    "start": 0, "count": 1000,
    "filters": {
      "type_filters": { "include_games": true },
      "price_filters": { "min_discount_percent": 1 }
    }
  },
  "context": { "language": "spanish", "country_code": "VE" },
  "data_request": {
    "include_basic_info": true,
    "include_all_purchase_options": true,
    "include_tag_count": 20,
    "include_reviews": true
  }
}
```

Resultado medido del barrido completo (country `US`):

| Métrica | Valor |
|---|---|
| Juegos en oferta (`total_matching_records`) | 14 546 |
| Requests necesarias | 15 (tope real: 1000 ítems por página; `count: 5000` devuelve 1000) |
| Tiempo total | ~30 s (con 1 s de pausa entre páginas) |
| Transferencia | ~74 MB con `basic_info` + reviews; ~2,2 MB por página sin `basic_info` |
| Ítems con `discount_end_date` | 14 533 / 14 546 |
| API key | No requerida |

Campos útiles por ítem:

- `appid`, `name`, `store_url_path` → link: `https://store.steampowered.com/app/{appid}/`
- `best_purchase_option.original_price_in_cents`, `final_price_in_cents`, `discount_pct`, `formatted_*`
- `best_purchase_option.active_discounts[].discount_end_date` (Unix timestamp) → **la fecha de fin**
- `tagids` + `tags[{tagid, weight}]` → vector de gustos para el recomendador
- `reviews.summary_filtered.{percent_positive, review_count, review_score_label}`
- `basic_info.short_description`, `developers`, `publishers`
- `content_descriptorids` → permite filtrar contenido adulto (aparece mucho en las ofertas baratas)

Nombres de tags: `IStoreService/GetTagList/v1/?language=spanish` (sin key) [verificado].

Precios regionales: `country_code` cambia moneda y precio (probado `US`, `AR`, `VE`, `MX`) [verificado]. **Falta definir tu país** para fijarlo.

Riesgos:
- Es un endpoint **no documentado oficialmente** (lo usa la propia tienda). Puede cambiar sin aviso. Mitigación: adaptador aislado + fallback.
- Rate limit no publicado. 15 requests por barrido, 1–4 barridos al día, es un volumen insignificante.

### 1.2 Fallbacks

| Fuente | Fecha de fin | Auth | Estado | Uso |
|---|---|---|---|---|
| `search/results/?specials=1&infinite=1&json=1` | No | No | [verificado] 22 593 ítems (incluye DLC/software), HTML a parsear, 100/página | Fallback si Query cae |
| `IStoreBrowseService/GetItems` | Sí (`discount_end_date`) | No [docs] | No probado | Enriquecer appids sueltos |
| `api/featuredcategories` → `specials` | Sí (`discount_expiration`) | No | [verificado] solo 10 ítems | No sirve para cobertura |
| `api/appdetails` | No | No | [verificado] | 1 appid por request, ~200 req/5 min [no verificado]. Solo puntual |
| IsThereAnyDeal API v2 | Sí (`expiry`, puede ser `null`) | API key | [verificado] 403 sin key | ToS: uso privado → "contact us". Útil para histórico de precios mínimos |
| CheapShark | No | No (exige User-Agent descriptivo) | [verificado] | Cross-check USD. No aporta fecha de fin |
| SteamSpy | No | No | No probado | Innecesario: Query ya trae tags |
| SteamDB | — | — | [docs] prohíbe scraping | Descartado |

### 1.3 Detección de "ofertas nuevas"

Ningún endpoint dice "esto empezó hoy". Se resuelve guardando el snapshot y haciendo diff por `(appid, discount_end_date)`:
- aparece → oferta nueva → candidata a notificar.
- desaparece → terminó.
- cambia `discount_pct` → bajó más.

Frecuencia sugerida: cada 6 h. Steam rota ofertas diarias en un horario fijo de la mañana del Pacífico [no verificado]; el diff lo cubre igual.

### 1.4 Señales iniciales de gustos (cold start)

| Endpoint | Key | Estado |
|---|---|---|
| `IPlayerService/GetOwnedGames` (juegos + horas jugadas) | **Sí** | [verificado] 401 sin key |
| `IWishlistService/GetWishlist?steamid=` | No (perfil público) [no verificado] | Respondió vacío con un perfil de prueba; probar con tu SteamID |

Steam Web API key: requiere cuenta no limitada (≥ 5 USD gastados), tope 100 000 llamadas/día [docs]. Solo hace falta para leer tu biblioteca.

---

## 2. Canal de notificación y cliente

| Opción | Push | Esfuerzo | Captura de señales (vistas, tiempo, guardados) | Dependencia |
|---|---|---|---|---|
| Bot de Telegram | Gratis, inmediato | Bajo | Solo clicks en botones inline | Telegram |
| Bot + Telegram Mini App (React) | Gratis vía bot | Medio | Completa (la Mini App es una web; eventos `activated/deactivated`) [docs] | Telegram |
| React PWA | Web Push (Chrome Android) | Medio | Completa | Ninguna |
| React + Capacitor → APK | FCM (`@capacitor-firebase/messaging`) o UnifiedPush/ntfy | Medio-alto | Completa + SQLite offline | Firebase (si FCM) |
| React Native + Expo (SDK 56) | FCM vía `expo-notifications` | Alto | Completa | Expo/FCM |

Notas:
- FCM funciona con APK sideloaded mientras el teléfono tenga Google Play Services; es gratis [docs + no verificado en dispositivo].
- ntfy self-hosted: un contenedor más en el Compose; sin Google, pero mantiene conexión persistente (algo de batería) [docs].

**Recomendación:** un único front React (Vite) que se publica como PWA y se empaqueta como APK con Capacitor, con push por FCM. Reutiliza tu stack, no depende de Telegram y deja el recomendador con todas las señales. **Alternativa que compite:** Telegram bot + Mini App: misma UI React, cero infraestructura de push y sin build de APK; el costo es depender de Telegram. Se decide en la fase de planificación.

---

## 3. Recomendador (un solo usuario)

Viable con filtrado **basado en contenido**. Filtrado colaborativo no aplica con un solo usuario.

- **Vector del juego:** tags de Steam ponderadas por `weight` (TF-IDF sobre ~450 tags), más precio, % de descuento y score de reseñas como features.
- **Perfil:** suma ponderada de vectores de los juegos con los que interactuaste, con decaimiento temporal `w · e^(−edad/τ)`, τ ≈ 60–90 días.
- **Pesos iniciales de señales implícitas (a calibrar):**

| Señal | Peso |
|---|---|
| Visto en el feed sin tocar | −0.1 |
| Abrió el detalle | +0.5 |
| Tiempo en detalle | +min(log(s)/3, 1) |
| Click "ir a Steam" | +1.5 |
| Guardado en wishlist de la app | +3 |
| Descartado ("no me interesa") | −2 |
| Comprado / en biblioteca | +4 |

- **Ranking:** similitud coseno perfil↔juego × factores (descuento, reseñas, cercanía de la fecha de fin).
- **Exploración:** 10–20 % del feed fuera del perfil (epsilon-greedy o Thompson sampling por cluster de tags) para no encerrarte en una burbuja.
- **Cold start:** biblioteca (horas jugadas) + wishlist de Steam.
- **Infra:** ~15 k juegos × ~450 dimensiones dispersas entran en memoria o en SQL plano. pgvector no hace falta salvo que se agreguen embeddings de descripciones.

---

## 4. Stack: hallazgos puntuales

- **TypeScript 7 (port a Go):** 7.0 estable desde ~julio 2026. **7.1 beta (20-oct-2026) sí trae "content mappers"** [docs, fuentes secundarias]. Me equivoqué al dudarlo. Pero no son mappers de datos: son un punto de extensión para que `tsc` type-checkee archivos embebidos (`.vue`, `.svelte`, Astro, MDX) como TS virtual. **No reemplazan un ORM ni el mapeo de DTOs.** Para eso siguen siendo Prisma/Drizzle/Kysely + Zod/Valibot.
- **Recursos:** Postgres + API + worker (+ ntfy opcional) ≈ 400–700 MB RAM [estimación]. El barrido pesa poco en CPU; lo más grande es la transferencia (~74 MB por barrido completo, reducible pidiendo `basic_info` solo para appids nuevos).
- **VPS:** Hetzner CX23 (2 vCPU / 4 GB) ~5,49 €/mes tras las subidas de 2026; Oracle Always Free recortado a 2 OCPU / 12 GB ARM con reclamo de instancias ociosas [no verificado en el sitio oficial, revisar antes de comprar].

---

## 5. Pendiente de verificar

| Qué | Cómo comprobarlo |
|---|---|
| Wishlist pública sin key | `curl "https://api.steampowered.com/IWishlistService/GetWishlist/v1/?steamid=<TU_STEAMID64>"` |
| `GetItems` con `discount_end_date` | Probarlo en la fase de planificación si se necesita enriquecer appids sueltos |
| Rate limit real de `Query` | Medir en el worker con backoff ante 429 |
| FCM en tu teléfono con APK sideloaded | Prueba mínima con Capacitor en la fase de prototipo |
| Precios de VPS | Revisar hetzner.com / oracle.com al momento de contratar |
| ToS de ITAD para uso privado | Escribirles si se quiere usar como fuente secundaria |

## Datos que faltan

- País de tu cuenta de Steam (define `country_code` y moneda).
- Tu SteamID64 (para wishlist y biblioteca).
