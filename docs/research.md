# Fase de investigación — Steam Offers Tracker v2

Última actualización: 2026-10-31 (revisión 2).
Objetivo: confirmar si es viable un sistema que notifique descuentos de Steam (nombre, % de descuento, precio antes/después, fecha de fin, link a la tienda) y aprenda de los gustos de cada usuario, sin scraping pesado.

Leyenda: **[verificado]** = probado en vivo desde un contenedor en esta fecha. **[docs]** = documentación oficial, specs o metadatos de npm. **[no verificado]** = fuentes secundarias, falta comprobar.

---

## Veredicto

Es viable y más barato que la v1. Steam expone un endpoint sin API key (`IStoreQueryService/Query`) que devuelve **todos los juegos en oferta con precio original, final, %, fecha de fin y tags**. Un barrido completo por país son **15 requests en ~30 s**. No hace falta Puppeteer ni navegador headless.

## Decisiones tomadas (revisión 2)

| Tema | Decisión | Fuente |
|---|---|---|
| Cliente | App nativa. PWA descartada. Candidatos: Expo o Capacitor | Gisus |
| Usuarios | **Multiusuario desde el diseño**, aunque al inicio lo use una sola persona | Gisus |
| Esfuerzo | No es criterio; el aprendizaje suma | Gisus |
| VPS | Hostgator entra como candidato | Gisus |

## Correcciones respecto a la revisión 1

- **Expo:** la revisión 1 decía SDK 56 como actual. El actual es **SDK 58** (publicado 2026-09-29, React Native 0.88) [docs: npm `expo@58.0.22`].
- **Content mappers:** existen en TS 7.1 (ya corregido en la revisión 1). Además ahora hay un caso de uso concreto: Reylo (sección 4.3).

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
  "context": { "language": "spanish", "country_code": "MX" },
  "data_request": {
    "include_basic_info": true,
    "include_all_purchase_options": true,
    "include_tag_count": 20,
    "include_reviews": true
  }
}
```

Barrido completo medido (country `US`):

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
- `best_purchase_option.active_discounts[].discount_end_date` (Unix) → **fecha de fin**
- `tagids` + `tags[{tagid, weight}]` → vector del juego para el recomendador
- `reviews.summary_filtered.{percent_positive, review_count, review_score_label}`
- `basic_info.short_description`, `developers`, `publishers`
- `content_descriptorids` → filtro de contenido adulto (abunda en las ofertas baratas)

Nombres de tags: `IStoreService/GetTagList/v1/?language=spanish`, sin key [verificado].

Riesgos:
- Endpoint **no documentado oficialmente** (lo usa la propia tienda). Puede cambiar sin aviso. Mitigación: adaptador aislado + fallback.
- Rate limit no publicado. 15 requests por país y barrido es un volumen bajo.

### 1.2 Impacto multiusuario: el costo escala por país, no por usuario [verificado]

`country_code` cambia moneda, precio y hasta el catálogo en oferta: el mismo día dio 14 546 (US), 14 541 (AR), 14 474 (VE) y 14 544 (MX) juegos. Por lo tanto:

- Las ofertas se guardan por `(appid, country)`.
- El worker barre **una vez por cada país que tenga al menos un usuario**: 10 países = ~150 requests por barrido.
- Agregar usuarios del mismo país no cuesta requests extra a Steam.

### 1.3 Fallbacks

| Fuente | Fecha de fin | Auth | Estado | Uso |
|---|---|---|---|---|
| `search/results/?specials=1&infinite=1&json=1` | No | No | [verificado] 22 593 ítems (incluye DLC/software), HTML, 100/página | Fallback si Query cae |
| `IStoreBrowseService/GetItems` | Sí (`discount_end_date`) | No [docs] | No probado | Enriquecer appids sueltos |
| `api/featuredcategories` → `specials` | Sí (`discount_expiration`) | No | [verificado] solo 10 ítems | No sirve para cobertura |
| `api/appdetails` | No | No | [verificado] | 1 appid por request; solo puntual |
| IsThereAnyDeal API v2 | Sí (`expiry`, puede ser `null`) | API key | [verificado] 403 sin key | ToS: uso privado → "contact us". Útil para mínimos históricos |
| CheapShark | No | No (exige User-Agent descriptivo) | [verificado] | Cross-check USD |
| SteamDB | — | — | [docs] prohíbe scraping | Descartado |

### 1.4 Detección de "ofertas nuevas"

Ningún endpoint marca "esto empezó hoy". Se guarda el snapshot y se compara por `(appid, country, discount_end_date)`:
- aparece → oferta nueva → candidata a notificar.
- desaparece → terminó.
- cambia `discount_pct` → bajó más.

Frecuencia sugerida: cada 6 h.

### 1.5 Datos por usuario desde Steam

| Qué | Endpoint | Key | Estado |
|---|---|---|---|
| Login | Steam OpenID 2.0 (`https://steamcommunity.com/openid`) → devuelve el SteamID64 | No | [verificado] endpoint activo |
| Biblioteca + horas jugadas | `IPlayerService/GetOwnedGames` | Sí (una key del servidor) | [verificado] 401 sin key |
| Wishlist | `IWishlistService/GetWishlist?steamid=` | No (perfil público) [docs] | Inconcluso: 2 perfiles públicos conocidos devolvieron `{}`; probablemente wishlist privada |

Steam Web API key: requiere cuenta no limitada (≥ 5 USD gastados), tope 100 000 llamadas/día por key [docs]. Con 1 llamada de biblioteca por usuario y día, el tope no es problema hasta decenas de miles de usuarios.

---

## 2. Cliente móvil: Expo vs Capacitor

Versiones actuales [docs, npm]:

| | Expo (React Native) | Capacitor |
|---|---|---|
| Versión | SDK 58 (`expo@58.0.22`), RN 0.88, React 19.2 | `@capacitor/core@8.6.0`, 9.0 en beta |
| Cadencia 2026 | SDK 56 (20-may), 57 (30-jun), 58 (29-sep) | Una major por año aprox. |
| Render | Componentes nativos (Fabric, Hermes, JSI) | WebView con tu app React DOM adentro |
| Push | `expo-notifications` → FCM directo desde tu backend o Expo Push Service | `@capacitor-firebase/messaging@8.6.0` → FCM |
| SQLite local | `expo-sqlite` (first-party) + Drizzle tiene driver `drizzle-orm/expo-sqlite` [verificado en exports] | `@capacitor-community/sqlite` (comunidad) |
| Señales para el recomendador | `onViewableItemsChanged` de FlatList/FlashList (impresiones y tiempo visible) + `AppState` | `IntersectionObserver` + Page Visibility API |
| Build del APK | `npx expo prebuild` + Gradle local, o EAS (cloud/local) | Android Studio / Gradle |
| Aprendizaje nuevo | Alto: paradigma nativo, New Architecture, Expo Modules (Kotlin/Swift), expo-router | Bajo: es casi todo React DOM que ya conocés |

Las señales y el push empatan: los dos lo resuelven bien.

**Recomendación: Expo SDK 58.**
- Cumple el objetivo de aprendizaje: es otro paradigma (sin DOM, layout con Yoga, módulos nativos). Capacitor es mayormente lo que ya sabés hacer.
- UI nativa en lugar de WebView. Si no te gustan las PWA, Capacitor se les parece en sensación y rendimiento, porque también es una web dentro de un contenedor.
- Los módulos que necesitamos son first-party (notificaciones, SQLite, router, tareas en background), y Drizzle corre sobre `expo-sqlite`. Así hay un mismo ORM en el backend y en el móvil.

Costo concreto: un upgrade de SDK cada 1–3 meses si querés estar al día (en 2026 salieron 3), y Metro como bundler en lugar de Vite. Reylo no sirve en el cliente: no tiene plugin para Metro ni driver para `expo-sqlite`.

Capacitor solo ganaría si quisieras reutilizar el mismo código React DOM en un panel web. Con PWA descartada, no compite.

---

## 3. Multiusuario: identidad, datos y recomendador

### 3.1 Qué es global y qué es por usuario

| Global (compartido) | Por usuario |
|---|---|
| `games` (appid, nombre, tags con peso, reviews, content descriptors) | `users` (SteamID64 vía OpenID) |
| `offers` por `(appid, country)` + historial de snapshots | `user_settings` (país, % mínimo, contenido excluido, horario sin notificaciones, tope diario) |
| `tags` (id → nombre por idioma) | `devices` (tokens de push, uno o varios por usuario) |
| | `events` (append-only: vista, tiempo, guardado, descarte, click a Steam) |
| | `user_profiles` (vector de gustos, recalculado periódicamente) |
| | `wishlist_app`, `notifications_sent` (deduplicación) |

Agregar `user_id` en todas las tablas por usuario desde el día uno cuesta casi nada. Migrar un esquema mono-usuario más adelante cuesta una reestructuración, que es justo lo que querés evitar.

### 3.2 Identidad

- Login con Steam (OpenID 2.0): sin contraseñas y con el SteamID64 que hace falta para importar biblioteca y wishlist. Después, sesión propia de la app (JWT o tokens de sesión) emitida por el backend.
- La app nunca llama a Steam con la key: la Web API key vive solo en el servidor.

### 3.3 Recomendador

- **Día 1, por usuario: filtrado basado en contenido.** Vector del juego = tags ponderadas (TF-IDF sobre ~450 tags) + precio, descuento y reviews. Perfil del usuario = suma ponderada de los juegos con los que interactuó, con decaimiento `w · e^(−edad/τ)`, τ ≈ 60–90 días.
- **Con varios usuarios: se suma filtrado colaborativo** item-item (juegos que interesan a la misma gente). La mezcla híbrida se ajusta con un peso por usuario según cuánto historial tenga.
- **Exploración:** 10–20 % del feed fuera del perfil (epsilon-greedy o Thompson sampling por cluster de tags).
- **Cold start:** biblioteca (horas jugadas) + wishlist de Steam + elección de tags en el onboarding.
- **Medir y pulir:** registrar impresiones permite calcular CTR y métricas offline (precision@k, NDCG). Con varios usuarios se pueden comparar variantes del algoritmo por cohortes (A/B).
- **Dónde corre:** en el backend. El móvil solo registra eventos en una cola local (SQLite) y los sube en lotes; así funciona offline y el modelo ve los datos de todos.

Pesos iniciales de señales implícitas (a calibrar):

| Señal | Peso |
|---|---|
| Visto en el feed sin tocar | −0.1 |
| Abrió el detalle | +0.5 |
| Tiempo en detalle | +min(log(s)/3, 1) |
| Click "ir a Steam" | +1.5 |
| Guardado en wishlist de la app | +3 |
| Descartado ("no me interesa") | −2 |
| Comprado / en biblioteca | +4 |

### 3.4 Notificaciones con varios usuarios

Por cada barrido: ofertas nuevas por país × usuarios de ese país → score con su perfil → filtrar por umbrales de `user_settings` → deduplicar contra `notifications_sent` → enviar por FCM en lote. Un tope diario por usuario evita el spam.

Volumen de referencia: 200 eventos/usuario/día × 1000 usuarios = 200 k filas/día. Postgres lo maneja; a esa escala conviene particionar `events` por mes [estimación].

---

## 4. Capa de datos y stack

### 4.1 TypeScript 7 [docs, npm]

- `typescript@7.0.2` es el `latest` (publicado 2026-07-08). `7.1.0-beta` disponible; el estable se espera para fines de noviembre [no verificado].

### 4.2 NestJS con TypeScript 7 [verificado]

NestJS 12.3.2 + TS 7.0.2 con `experimentalDecorators` y `emitDecoratorMetadata`: compila, y la inyección de dependencias resuelve (`design:paramtypes` correcto). Tu stack de backend no se rompe con TS 7.

### 4.3 Reylo [verificado con un spike]

Qué es: importás archivos `.sql` desde TypeScript con tipos inferidos **desde tu base de datos real**, usando los content mappers de TS 7.1. Sin codegen ni watcher. Es de Colin McDonnell (autor de Zod).

Lo que probé: Reylo 0.6.0 + TS 7.1.0-beta + NestJS 12.3.2 + `pg` + Postgres 16 + Node 24:

| Prueba | Resultado |
|---|---|
| Typecheck con `tsc --runExternalCode` | OK |
| Inferencia de filas | `{ appid: number; name: string; discount_pct: number; ... }` correcto |
| Cardinalidad | Query por PK → `Row \| null`; listado → `Row[]` |
| Columna mal escrita en el `.sql` | Error de tipos en el propio `.sql`: `column o.discount_pctt does not exist` |
| Tipo de `timestamptz` | `string` (ISO), no `Date`. Mi código asumía `Date` y el typecheck lo marcó |
| Ejecución dentro de un servicio Nest con DI | OK, con `node --import reylo/register dist/main.js` |
| Tiempo de typecheck | ~12 s en frío, ~0,2 s sin cambios, ~4,7 s tras cambiar un `.sql` |

Límites:
- **Madurez:** versión 0.6.0, primera publicación el 2026-10-03 (4 semanas). Depende de TS 7.1, que sigue en beta.
- **Node 24+** obligatorio.
- **Necesita la base de datos levantada para typecheckear**, también en CI (servicio Postgres en el pipeline).
- **No hace migraciones:** lee el esquema de la DB; las migraciones van por otro lado.
- **Nest no corre con el type-stripping nativo de Node** (decoradores y parameter properties): se compila con `tsc` y se copian los `.sql` a `dist` (en Nest, `assets` en `nest-cli.json`).
- **No aplica al cliente móvil** (sin plugin para Metro ni driver para `expo-sqlite`).

### 4.4 Prisma: lo reescribieron [docs, npm]

- **Prisma 8 es una reescritura completa en TypeScript** y sigue en release candidate (`8.0.0-rc.29`). Desde agosto, `npm install prisma` sin versión instala el RC (el tag `latest` de npm apunta a 8.0.0-rc.29).
- Cambia todo: el esquema pasa a ser un "contract", la CLI no lee `schema.prisma` ni tiene `generate`/`migrate dev`/`db push`, y las queries cambian de forma (`prisma.user.findMany` → `db.orm.public.User.where(...).all()`). Postgres y MongoDB primero; SQLite después.
- Todavía no tiene `$extends`, filtros dentro de JSON, incremento atómico, la mayoría de los nested writes, niveles de aislamiento de transacciones ni los códigos de error tipo P2002.
- Prisma 7 recibe fixes 18 meses desde el GA de Prisma 8. Prisma 6 tiene parches de seguridad hasta el 19-nov-2026.

Conclusión: arrancar hoy con Prisma 7 es arrancar en una rama en mantenimiento, y con Prisma 8 es arrancar sobre un RC al que le faltan features. No conviene para este proyecto ahora.

### 4.5 Recomendación preliminar para la capa de datos

**Drizzle como base + Reylo para las queries pesadas del backend.**
- Drizzle (`drizzle-orm@0.45.4` estable, 1.0 en RC): esquema y migraciones (drizzle-kit), CRUD simple, y el mismo ORM en el móvil sobre `expo-sqlite`.
- Reylo: queries SQL complejas del recomendador (CTEs, window functions, ranking) tipadas contra la DB real. Según su README, `.run()` acepta una instancia de Drizzle [docs].
- Si Reylo se rompe o cambia de API por ser 0.x, esas queries caen a `sql` de Drizzle sin tocar el resto.

Alternativa que compite: todo SQL-first con Reylo + migraciones SQL planas. Es más puro, pero deja sin solución el ORM del móvil.

Se decide en la fase de planificación.

---

## 5. VPS

Estimación de consumo: Postgres + API Nest + worker ≈ 400–700 MB de RAM al inicio [estimación]. Un plan de 2 GB alcanza para arrancar; 4 GB da margen para varios usuarios.

### 5.1 Hostgator México (VPS NVMe) [verificado en hostgator.mx]

Corre sobre **infraestructura de Oracle Cloud**, con acceso root y servidores en América Latina, según su propia página.

| Plan | Precio promocional | Precio regular (mensual / renovación) |
|---|---|---|
| VPS NVMe 2 | desde 76,25 MXN/mes | 150,75 MXN/mes |
| VPS NVMe 4 | desde 134,00 MXN/mes | 350,50 MXN/mes |
| VPS NVMe 8 | desde 229,75 MXN/mes | 517,50 MXN/mes |

- El precio promocional exige pagar 1, 2 o 3 años por adelantado (el de tarjeta dice "por 3 años"); el ciclo mensual queda excluido. **La renovación se cobra al precio regular.**
- La página destacaba además "desde 62,00 MXN/mes" con hasta 73 % OFF, por una promo temporal.
- vCPU/RAM/disco de cada plan NVMe: no figuran en el HTML estático [no verificado]. Una review del plan equivalente en EE. UU. dice NVMe 2 = 1 vCPU, 2 GB RAM, 50 GB NVMe.
- Si tu cuenta no es de México, los precios y planes cambian según el sitio regional.

### 5.2 Hetzner [no verificado]

CX23 (2 vCPU, 4 GB): las fuentes secundarias van de 3,49 a 5,49 €/mes tras las dos subidas de 2026, más 0,50 €/mes por IPv4. No tiene región en LatAm (sí en EE. UU.). Para esta app la latencia importa poco.

Comparación rápida (supuesto: ~19–20 MXN por USD, no verificado): a precio regular, Hostgator NVMe 2 (150,75 MXN ≈ 7,5–8 USD) cuesta más que Hetzner CX23 (≈ 4–6 € con IPv4) y, si se confirma, trae la mitad de RAM (2 GB vs 4 GB). A precio promocional queda parejo, pero atado a 1–3 años de pago adelantado. A favor de Hostgator: servidores en LatAm, soporte en español y facturación en moneda local.

---

## 6. Pendiente de verificar

| Qué | Cómo comprobarlo |
|---|---|
| Wishlist sin key | `curl "https://api.steampowered.com/IWishlistService/GetWishlist/v1/?steamid=<TU_STEAMID64>"` con la wishlist en público |
| Specs de los VPS NVMe de Hostgator | Configurador de hostgator.mx (paso 2 del pedido) |
| Precio actual de Hetzner | hetzner.com/cloud |
| FCM en tu teléfono con APK sideloaded | Prototipo mínimo con Expo (development build) |
| Rate limit real de `Query` | Medir en el worker con backoff ante 429 |
| Fecha del estable de TS 7.1 | Blog de TypeScript / `npm view typescript dist-tags` |
| `.run()` de Reylo sobre una instancia de Drizzle | Extender el spike en la fase de planificación |

## Datos que faltan

- País de tu cuenta de Steam (define la moneda del primer país a barrer y qué sitio de Hostgator aplica).
- Tu SteamID64 (para probar la wishlist).
