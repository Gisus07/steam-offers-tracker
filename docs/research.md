# Fase de investigación — Steam Offers Tracker v2

Última actualización: 2026-10-31 (revisión 3).
Objetivo: confirmar si es viable un sistema que notifique descuentos de Steam (nombre, % de descuento, precio antes/después, fecha de fin, link a la tienda) y aprenda de los gustos de cada usuario, sin scraping pesado.

Leyenda: **[verificado]** = probado en vivo desde un contenedor en esta fecha. **[docs]** = documentación oficial, specs o metadatos de npm. **[no verificado]** = fuentes secundarias, falta comprobar. **[Gisus]** = dato aportado por Gisus (capturas o decisión).

---

## Veredicto

Es viable y más barato que la v1. Steam expone un endpoint sin API key (`IStoreQueryService/Query`) que devuelve **todos los juegos en oferta con precio original, final, %, fecha de fin y tags**. Un barrido completo por país son **15 requests en ~30 s**. No hace falta Puppeteer ni navegador headless.

## Decisiones tomadas

| Tema | Decisión | Estado |
|---|---|---|
| Cliente | **Expo** (React Native). PWA descartada | Confirmado [Gisus] |
| Usuarios | Multiusuario desde el diseño | Confirmado [Gisus] |
| Región | **Cada usuario ve las ofertas de su región**, según su cuenta de Steam | Confirmado [Gisus] |
| Login | Con cuenta de Steam; es la pieza clave | Confirmado [Gisus] |
| Web | Web propia de presentación + lógica compartida con la app | Confirmado [Gisus]; arquitectura en §2.3 |
| Compartir / grupos de amigos | A futuro, fuera del alcance inicial | Confirmado [Gisus] |
| Criterio | El esfuerzo no pesa; el aprendizaje suma | Confirmado [Gisus] |
| ORM | Recomendación: Drizzle 1.0 RC (comparado con TypeORM en §4.5) | A decidir en planificación |
| VPS | Recomendación: Hostgator Snappy 1000 – NVMe 2 | A decidir en planificación |

## Correcciones respecto a revisiones anteriores

- **Expo (rev. 1):** decía SDK 56 como actual. El actual es **SDK 58** (2026-09-29, React Native 0.88) [docs: npm].
- **Hetzner (rev. 2):** la estimación de 3,49–5,49 € por un CX23 está desactualizada. Según las capturas del 31-oct, la línea Cost-Optimized (CX) figura "Currently not available" y la Regular Performance (CPX) arranca en 6,49 € con 1 GB de RAM [Gisus].
- **Hostgator (rev. 2):** usé el sitio de México (MXN). Las capturas son del sitio de EE. UU. (USD) y confirman las specs de cada plan [Gisus].
- **Drizzle (rev. 2):** recomendaba la 0.45 estable. Ahora recomiendo arrancar en **1.0 RC**, porque la 1.0 elimina la API relacional v1 y cambia el formato de migraciones; empezar en 0.45 obliga a migrar después.

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

### 1.2 Región por usuario, barrido por país [verificado]

`country_code` cambia moneda, precio y hasta el catálogo en oferta: el mismo día dio 14 546 (US), 14 541 (AR), 14 474 (VE) y 14 544 (MX) juegos.

- **Para el usuario:** cada uno ve precios y ofertas de su región (decisión de UX).
- **Por dentro:** las ofertas se guardan por `(appid, country)` y el worker barre una vez por país que tenga al menos un usuario. 10 países = ~150 requests por barrido; sumar usuarios del mismo país no cuesta requests extra.

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
| País del perfil | `ISteamUser/GetPlayerSummaries` → `loccountrycode` (solo si el usuario lo cargó en su perfil) | Sí | [docs] no probado (requiere key) |
| Ubicación del perfil (texto libre) | `steamcommunity.com/profiles/<id>/?xml=1` → `<location>` | No | [verificado] devolvió "Bellevue, Washington, United States" para un perfil público |
| Biblioteca + horas jugadas | `IPlayerService/GetOwnedGames` | Sí (una key del servidor) | [verificado] 401 sin key |
| Wishlist | `IWishlistService/GetWishlist?steamid=` | No (perfil público) [docs] | Inconcluso: 2 perfiles públicos devolvieron `{}`; probablemente wishlist privada |

**Región de la cuenta:** no encontré un endpoint público que exponga la región de tienda (la que define los precios). Plan: precargar el país con `loccountrycode` (o el locale del dispositivo si el perfil no lo tiene) y que el usuario lo confirme en el onboarding; editable en ajustes.

**Login desde Expo:** Steam usa OpenID 2.0, no OAuth2/OIDC, así que el flujo pasa por el backend. La app abre la página de login de Steam en el navegador del sistema, Steam redirige al callback del backend, el backend verifica la firma (`check_authentication`) y devuelve la sesión a la app por deep link.

Steam Web API key: requiere cuenta no limitada (≥ 5 USD gastados), tope 100 000 llamadas/día por key [docs]. Con 1 llamada de biblioteca por usuario y día, el tope no es problema hasta decenas de miles de usuarios.

---

## 2. Cliente: Expo (confirmado)

### 2.1 Por qué Expo frente a Capacitor

Versiones actuales [docs, npm]:

| | Expo (React Native) | Capacitor |
|---|---|---|
| Versión | SDK 58 (`expo@58.0.22`), RN 0.88, React 19.2 | `@capacitor/core@8.6.0`, 9.0 en beta |
| Cadencia 2026 | SDK 56 (20-may), 57 (30-jun), 58 (29-sep) | Una major por año aprox. |
| Render | Componentes nativos (Fabric, Hermes, JSI) | WebView con tu app React DOM adentro |
| Push | `expo-notifications` → FCM directo desde tu backend o Expo Push Service | `@capacitor-firebase/messaging@8.6.0` → FCM |
| SQLite local | `expo-sqlite` (first-party) + Drizzle trae driver `expo-sqlite` [verificado en el paquete 1.0 RC] | `@capacitor-community/sqlite` (comunidad) |
| Señales para el recomendador | `onViewableItemsChanged` de FlatList/FlashList + `AppState` | `IntersectionObserver` + Page Visibility API |
| Build del APK | `npx expo prebuild` + Gradle local, o EAS | Android Studio / Gradle |
| Aprendizaje nuevo | Alto: paradigma nativo, New Architecture, Expo Modules (Kotlin/Swift), expo-router | Bajo: casi todo React DOM |

Costo concreto de Expo: un upgrade de SDK cada 1–3 meses si querés estar al día, y Metro en lugar de Vite. Reylo no sirve en el cliente (sin plugin para Metro ni driver `expo-sqlite`).

### 2.2 iOS (si el proyecto escala)

Las dos opciones generan apps iOS. Expo tiene tres ventajas concretas:

- **Builds de iOS sin Mac:** EAS Build compila en la nube. Plan gratis: 15 builds de iOS por mes, cola de baja prioridad y timeout de 45 min [no verificado: fuentes secundarias de oct-2026; confirmar en expo.dev/pricing]. Con Capacitor el build de iOS exige Xcode en una Mac o un runner macOS de CI.
- **UI nativa en iOS** en lugar de una WebView.
- **Revisión de la App Store:** la guideline 4.2 pide que la app vaya "más allá de un sitio web reempaquetado". Una app Capacitor tiene que demostrarlo con funciones nativas; una app con UI nativa no carga con esa sospecha.

Costos de iOS con cualquiera de las dos: Apple Developer Program 99 USD/año [no verificado en apple.com], un iPhone para probar y una Mac solo si querés builds locales o el simulador. En iOS el push va por APNs; `expo-notifications` lo maneja.

### 2.3 Web: separada o integrada

La web de presentación es una pieza aparte con cualquier opción: también con Capacitor, las pantallas de la app no son una landing. Lo que cambia es cuánto se comparte. Con Expo hay tres niveles:

1. **Lógica compartida:** monorepo (pnpm workspaces) con `apps/mobile` (Expo), `apps/api` (Nest), `apps/web` (landing) y `packages/shared` (tipos, schemas Zod, cliente de la API, reglas de negocio).
2. **Componentes React DOM compartidos:** los DOM components de Expo (`'use dom'`) permiten usar un componente React DOM dentro de la app nativa (en una WebView) y en web tal cual. Desde SDK 56 usan `@expo/dom-webview` por defecto [docs].
3. **La app entera en web:** Expo Router compila la misma app a web con react-native-web, con salida estática por ruta (`web.output: "static"`) [docs].

**Recomendación:** landing separada dentro del monorepo, porque una web de presentación quiere CSS libre, animaciones y SEO, y react-native-web es más rígido para eso. La lógica se comparte por `packages/shared`. Si más adelante querés la app completa en web, sale de Expo Router sin reescribirla. El framework de la landing se elige en planificación.

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

### 3.2 Identidad

- Login con Steam (OpenID 2.0, §1.5): sin contraseñas y con el SteamID64 que hace falta para región, biblioteca y wishlist. Después, sesión propia de la app emitida por el backend.
- La Web API key de Steam vive solo en el servidor.

### 3.3 Recomendador

- **Día 1, por usuario: filtrado basado en contenido.** Vector del juego = tags ponderadas (TF-IDF sobre ~450 tags) + precio, descuento y reviews. Perfil = suma ponderada de los juegos con los que interactuó, con decaimiento `w · e^(−edad/τ)`, τ ≈ 60–90 días.
- **Con varios usuarios: se suma filtrado colaborativo** item-item. La mezcla híbrida se pondera según cuánto historial tenga cada usuario.
- **Exploración:** 10–20 % del feed fuera del perfil (epsilon-greedy o Thompson sampling por cluster de tags).
- **Cold start:** biblioteca (horas jugadas) + wishlist de Steam + tags elegidas en el onboarding.
- **Medir y pulir:** registrar impresiones permite calcular CTR y métricas offline (precision@k, NDCG) y comparar variantes por cohortes (A/B).
- **Dónde corre:** en el backend. El móvil registra eventos en una cola local (SQLite) y los sube en lotes.

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

Por cada barrido: ofertas nuevas por país × usuarios de ese país → score con su perfil → filtrar por `user_settings` → deduplicar contra `notifications_sent` → enviar por FCM en lote. Un tope diario por usuario evita el spam.

Volumen de referencia: 200 eventos/usuario/día × 1000 usuarios = 200 k filas/día. A esa escala conviene particionar `events` por mes [estimación].

### 3.5 A futuro (fuera del alcance inicial)

- Compartir una oferta a WhatsApp, Telegram o Discord con el share sheet nativo y un deep link a la oferta.
- Grupos de amigos dentro de la app; podrían sembrarse con los amigos de Steam que también la usen.

---

## 4. Capa de datos y stack

### 4.1 TypeScript 7 [docs, npm]

`typescript@7.0.2` es el `latest` (2026-07-08). `7.1.0-beta` disponible; el estable se espera para fines de noviembre [no verificado].

### 4.2 NestJS con TypeScript 7 [verificado]

NestJS 12.3.2 + TS 7.0.2 con `experimentalDecorators` y `emitDecoratorMetadata`: compila y la inyección de dependencias resuelve.

### 4.3 Reylo [verificado con un spike]

Importás archivos `.sql` desde TypeScript con tipos inferidos **desde tu base de datos real**, usando los content mappers de TS 7.1. Sin codegen ni watcher.

Probado con Reylo 0.6.0 + TS 7.1.0-beta + NestJS 12.3.2 + `pg` + Postgres 16 + Node 24:

| Prueba | Resultado |
|---|---|
| Typecheck con `tsc --runExternalCode` | OK |
| Inferencia de filas | `{ appid: number; name: string; discount_pct: number; ... }` correcto |
| Cardinalidad | Query por PK → `Row \| null`; listado → `Row[]` |
| Columna mal escrita en el `.sql` | Error de tipos en el propio `.sql` |
| Tipo de `timestamptz` | `string` (ISO), no `Date` |
| Ejecución dentro de un servicio Nest con DI | OK, con `node --import reylo/register dist/main.js` |
| Tiempo de typecheck | ~12 s en frío, ~0,2 s sin cambios, ~4,7 s tras cambiar un `.sql` |

Límites: versión 0.6 con 4 semanas de vida y dependiente de TS 7.1 beta; exige Node 24; necesita la DB levantada para typecheckear (también en CI); no hace migraciones; Nest no corre con el type-stripping nativo de Node (se compila con `tsc` y se copian los `.sql`); no aplica al cliente móvil.

### 4.4 Prisma: lo reescribieron [docs, npm]

Prisma 8 es una reescritura completa en TypeScript, en release candidate (`8.0.0-rc.29`, y `npm install prisma` ya instala el RC). Cambia el esquema ("contract"), la CLI y la forma de las queries. Le faltan `$extends`, filtros en JSON, incremento atómico, la mayoría de los nested writes y niveles de aislamiento. Prisma 7 queda en mantenimiento por 18 meses tras el GA de la 8. No conviene para este proyecto ahora.

### 4.5 TypeORM vs Drizzle [verificado con un spike]

Probé las dos contra el mismo Postgres 16, con TS 7.0.2: **TypeORM 1.1.2** y **Drizzle 1.0.0-rc.5**. Las dos compilan y corren. El mismo esquema y la misma consulta ("ofertas de US con ≥ 50 %, con el nombre del juego"):

**TypeORM**

```ts
import 'reflect-metadata';
import { Column, DataSource, Entity, JoinColumn, ManyToOne, MoreThanOrEqual, PrimaryColumn } from 'typeorm';

@Entity('games')
export class Game {
  @PrimaryColumn('int') appid!: number;
  @Column('text') name!: string;
}

@Entity('offers')
export class Offer {
  @PrimaryColumn('int') appid!: number;
  @PrimaryColumn('char', { length: 2 }) country!: string;
  @Column('smallint', { name: 'discount_pct' }) discountPct!: number;
  @Column('int', { name: 'final_cents' }) finalCents!: number;
  @Column('int', { name: 'original_cents' }) originalCents!: number;
  @Column('timestamptz', { name: 'ends_at', nullable: true }) endsAt!: Date | null;

  @ManyToOne(() => Game)
  @JoinColumn({ name: 'appid' })
  game!: Game;
}

const ds = new DataSource({ type: 'postgres', url: process.env.DATABASE_URL, entities: [Game, Offer] });
await ds.initialize();

const offers = await ds.getRepository(Offer).find({
  where: { country: 'US', discountPct: MoreThanOrEqual(50) },
  relations: { game: true },
  select: { appid: true, discountPct: true, game: { appid: true, name: true } },
  order: { discountPct: 'DESC' },
});

// El tipo es Offer[]: `select` no achica el tipo. Esto compila...
const finalCents: number = offers[0]!.finalCents;
// ...pero en runtime vale undefined.
console.log('TypeORM', JSON.stringify(offers), '| finalCents =', finalCents);
await ds.destroy();
```

**Drizzle**

```ts
import { and, defineRelations, desc, eq, gte } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/node-postgres';
import { char, integer, pgTable, primaryKey, smallint, text, timestamp } from 'drizzle-orm/pg-core';

export const games = pgTable('games', {
  appid: integer('appid').primaryKey(),
  name: text('name').notNull(),
});

export const offers = pgTable('offers', {
  appid: integer('appid').notNull().references(() => games.appid),
  country: char('country', { length: 2 }).notNull(),
  discountPct: smallint('discount_pct').notNull(),
  finalCents: integer('final_cents').notNull(),
  originalCents: integer('original_cents').notNull(),
  endsAt: timestamp('ends_at', { withTimezone: true }),
}, (t) => [primaryKey({ columns: [t.appid, t.country] })]);

export const relations = defineRelations({ games, offers }, (r) => ({
  offers: { game: r.one.games({ from: r.offers.appid, to: r.games.appid }) },
}));

const db = drizzle({ connection: process.env.DATABASE_URL!, relations });

// 1) Query builder estilo SQL: el tipo sale de lo que seleccionás.
const rows = await db
  .select({ appid: offers.appid, discountPct: offers.discountPct, name: games.name })
  .from(offers)
  .innerJoin(games, eq(games.appid, offers.appid))
  .where(and(eq(offers.country, 'US'), gte(offers.discountPct, 50)))
  .orderBy(desc(offers.discountPct));

// @ts-expect-error finalCents no se seleccionó, así que no existe en el tipo.
console.log(rows[0]!.finalCents);

// 2) API relacional (equivalente a find + relations de TypeORM).
const list = await db.query.offers.findMany({
  where: { country: 'US', discountPct: { gte: 50 } },
  orderBy: { discountPct: 'desc' },
  columns: { appid: true, discountPct: true, endsAt: true },
  with: { game: { columns: { name: true } } },
});
const ends: Date | null = list[0]!.endsAt;

console.log('Drizzle select', JSON.stringify(rows));
console.log('Drizzle query ', JSON.stringify(list), '| endsAt es Date:', ends instanceof Date);
await db.$client.end();
```

Salida real:

```
TypeORM [{"appid":4466830,"discountPct":85,"game":{"appid":4466830,"name":"Axe And Claw"}}] | finalCents = undefined
Drizzle select [{"appid":4466830,"discountPct":85,"name":"Axe And Claw"}]
Drizzle query  [{"appid":4466830,"discountPct":85,"endsAt":"2026-11-12T17:00:00.000Z","game":{"name":"Axe And Claw"}}] | endsAt es Date: true
```

| | TypeORM 1.1.2 | Drizzle 1.0 RC |
|---|---|---|
| Modelo | Clases con decoradores (`@Entity`, `@Column`); Data Mapper o Active Record | Tablas como objetos TS (`pgTable`); sin clases ni decoradores |
| Queries | `find({ where, relations, select })` + QueryBuilder con strings | Builder estilo SQL + API relacional (`db.query.x.findMany({ with })`) |
| Tipo del resultado | Siempre la entidad completa: `select` no lo achica. Un campo no pedido compila como `number` y llega `undefined` [verificado] | Sale de lo que pedís: un campo no pedido es error de compilación [verificado] |
| Migraciones | CLI genera el diff desde las entidades; `synchronize` en desarrollo | drizzle-kit `generate` / `migrate` / `push` |
| NestJS | `@nestjs/typeorm@12.0.2`, oficial y maduro | `@nestjs/drizzle@0.0.2`, oficial pero nuevo (publicado sep-2026); o un provider propio |
| Expo / móvil | Driver `expo` sobre la API async de `expo-sqlite` [verificado en el código]; en RN pide plugins de Babel para decoradores y metadata [docs] | Driver `drizzle-orm/expo-sqlite` [verificado en el paquete]; sin decoradores |
| Runtime | Requiere `reflect-metadata` y decoradores legacy | Sin decoradores ni metadata |
| Con Reylo | Sin integración directa | `.run()` de Reylo acepta una instancia de Drizzle [docs] |
| Estado | 1.0 salió el 2026-05-19 tras ~10 años en 0.x; nuevos maintainers desde fines de 2024; buscan financiamiento [docs] | 1.0 en RC (rc.5, 2026-10-21); 0.45.4 estable; la 1.0 cambia la API relacional y las migraciones [docs] |
| Curva para vos | Ya la conocés | Nueva; si sabés SQL se lee directo |

**Recomendación: Drizzle 1.0 RC con versión fijada.**
- El tipo del resultado sigue a la consulta: el error de TypeORM que se ve arriba (campo tipado que llega `undefined`) no puede pasar.
- El mismo ORM en Nest y en Expo, sin decoradores ni configuración de Babel en el móvil.
- Se integra con Reylo para las queries pesadas.
- Arrancar en 1.0 RC evita migrar la API relacional y las migraciones cuando salga la 1.0.

Costo: es un RC (pueden cambiar detalles antes del GA), el módulo de Nest es 0.0.2 (un provider propio alcanza si da problemas) y dejás la familiaridad de TypeORM.

Alternativa que compite: **TypeORM 1.x**, si preferís lo conocido y el módulo de Nest maduro. Volvió a tener mantenimiento activo y ya es 1.0.

### 4.6 Recomendación preliminar para la capa de datos

**Drizzle 1.0 RC como base + Reylo para las queries pesadas del backend.** Drizzle cubre esquema, migraciones, CRUD y el móvil; Reylo, el SQL complejo del recomendador tipado contra la DB real. Si Reylo cambia de API, esas queries pasan al `sql` de Drizzle sin tocar el resto.

---

## 5. VPS

Estimación de consumo: Postgres + API Nest + worker ≈ 400–700 MB de RAM al inicio [estimación].

### 5.1 Precios (capturas del 31-oct) [Gisus]

**Hostgator (hostgator.com, USD/mes)**

| Plan | vCPU | RAM | NVMe | Promo | Renovación |
|---|---|---|---|---|---|
| Snappy 1000 – NVMe 2 | 1 | 2 GB DDR5 | 50 GB | 3,59 | 4,95 |
| Snappy 2000 – NVMe 4 | 2 | 4 GB DDR5 | 100 GB | 8,49 | 9,35 |
| Snappy 4000 – NVMe 8 | 4 | 8 GB DDR5 | 200 GB | 12,49 | 18,70 |
| Snappy 8000 – NVMe 16 | 8 | 16 GB DDR5 | 450 GB | 25,99 | 39,53 |

Todos con ancho de banda sin medir y 1 IP dedicada.

**Hetzner (EUR/mes, IPv4 incluida, sin IVA)**

| Plan | vCPU | RAM | NVMe | Precio |
|---|---|---|---|---|
| Cost-Optimized (CX) | — | — | — | "Currently not available" (desde 5,99) |
| CPX02 | 1 AMD | 1 GB | 20 GB | 6,49 |
| CPX12 | 1 AMD | 2 GB | 40 GB | 11,99 |
| CPX22 | 2 AMD | 4 GB | 80 GB | 19,99 |
| CPX32 | 4 AMD | 8 GB | 160 GB | 35,99 |

A specs iguales, Hostgator cuesta menos de la mitad: 2 vCPU / 4 GB a 9,35 USD (renovación) contra 19,99 € + IVA; 1 vCPU / 2 GB a 4,95 USD contra 11,99 €.

### 5.2 Recomendación: Hostgator, Snappy 1000 – NVMe 2 para arrancar

- 2 GB alcanzan para Postgres + API + worker, siempre que las imágenes Docker se construyan en CI (GitHub Actions → registry) y en el VPS solo se ejecuten.
- Renueva a 4,95 USD/mes, y coincide con tu familiaridad con Hostgator.
- Pasar a Snappy 2000 (+4,40 USD/mes a precio de renovación) cuando la RAM quede sostenida por encima del 70 %, aparezca swap o se sumen Redis/colas.

Antes de pagar, verificar:
- Que permita Docker: fuentes secundarias dicen KVM con root, pero no lo confirmó ninguna fuente oficial [no verificado].
- Que el upgrade a mitad de período se prorratee.
- Qué plazo exige el precio promocional (el asterisco de la tarjeta).

---

## 6. Pendiente de verificar

| Qué | Cómo comprobarlo |
|---|---|
| Docker en Hostgator Snappy | Soporte de Hostgator o probarlo el primer día (`docker run hello-world`) |
| Prorrateo de upgrade y plazo de la promo | Términos del checkout de Hostgator |
| Wishlist sin key | `curl "https://api.steampowered.com/IWishlistService/GetWishlist/v1/?steamid=<TU_STEAMID64>"` con la wishlist pública |
| `loccountrycode` en GetPlayerSummaries | Con la Web API key, sobre tu propio perfil |
| Límites del plan gratis de EAS | expo.dev/pricing |
| Precio del Apple Developer Program | developer.apple.com/programs |
| FCM en tu teléfono con APK sideloaded | Development build mínima con Expo |
| Rate limit real de `Query` | Medir en el worker con backoff ante 429 |
| `.run()` de Reylo sobre una instancia de Drizzle | Extender el spike en la planificación |
