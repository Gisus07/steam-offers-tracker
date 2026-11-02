# Librerías

Qué entra en la app y por qué. Las versiones se verificaron el 1 de noviembre de 2026 en npm y en el `bundledNativeModules.json` de Expo 58.0.22.

Cada librería lleva un veredicto:
- **usar:** entra desde el primer día.
- **evaluar:** sirve, pero tiene un riesgo concreto que se revisa antes de adoptarla.
- **no:** no corre en React Native o no aporta acá.

Cómo se usa cada una está en Implementación en la app.

## TanStack

Son librerías headless: ponen la lógica (caché, formularios, tablas, gráficos) y la interfaz la pone este sistema.

- **En la app:** Query y Form.
- **A evaluar:** Charts, para el histórico de precios.
- **Después del MVP:** DB y AI.
- **Fuera del teléfono:** Table, porque estas pantallas no tienen tablas.

| Librería | Versión | ¿Corre en Expo? | Veredicto | Uso |
| --- | --- | --- | --- | --- |
| Query · `@tanstack/react-query` | 5.105.1 | Sí, con guía oficial | usar | Todo lo que viene del servidor: feed, detalle, Explorar, Guardados y ajustes. Guardar y descartar optimistas. Caché sin conexión |
| Form · `@tanstack/react-form` | 1.33.5 | Sí. El foco al primer error se hace con refs | usar | Gustos (mínimo tres), precio máximo, horario de silencio y la confirmación de borrar la cuenta. Valida con el mismo esquema de Zod que el servidor. Los interruptores y segmentados de Ajustes no usan formulario: se guardan al tocarlos con una mutación de Query. La v2 está en alpha y no se usa |
| Charts · `@tanstack/charts` | 1.2.0 | Con un adaptador **experimental** (`@tanstack/charts/react-native`). Pide RN 0.86 u 0.88 y `react-native-svg` 15 | evaluar | Línea escalonada de PriceHistory. Si el adaptador falla en Android, `react-native-wagmi-charts` 3.0.1 |
| DB · `@tanstack/react-db` | 1.0.0-rc.1.1 | Sí, con SQLite y cola sin conexión. Pero su adaptador de Expo pide `expo-sqlite` 55 o 57 y el SDK 58 trae la 58 | evaluar con la 1.0 estable | Guardados y descartados como colecciones vivas, al día en todas las pantallas |
| Pacer · `@tanstack/react-pacer` | 0.24.1, beta | Sin guía para React Native. Pide react-dom como peer, pero no lo importa | evaluar | Debounce del buscador de Explorar |
| AI · `@tanstack/ai` | 1.0.1 | Va en el servidor, no en el teléfono | evaluar, fuera del MVP | Ver "Qué es TanStack AI" |
| Table · `@tanstack/react-table` | 9.3.1 | Headless, sin guía para React Native | solo web | Tablas de un panel de administración, si se hace |
| Start · `@tanstack/react-start` | 1.169.4 (1.0 estable desde el 13 de octubre) | No, es web | evaluar para la landing | Landing con prerender estático. Si se usa, 1.168.60 o más nueva, por la CVE-2026-102989 |
| Virtual, Router, Store, Devtools | — | No: dependen de react-dom o del DOM | no | La app ya tiene FlashList y Expo Router |

### Qué es TanStack AI

Es un SDK de TypeScript, con licencia MIT, para trabajar con modelos de lenguaje de cualquier proveedor desde una misma API.

- **Qué hace:** chat en streaming, herramientas (tool calling), salida estructurada validada contra un esquema de Zod, embeddings, imagen, voz y MCP.
- **Proveedores:** trae 23 adaptadores, entre ellos OpenAI, Anthropic, Gemini, Mistral, Groq, Ollama y OpenRouter.
- **Estado:** el núcleo es 1.0 desde el 22 de octubre de 2026. La parte de agentes sigue en 0.x.
- **Costo:** la librería es gratis. Se pagan los tokens al proveedor, y cada respuesta informa el consumo (`usage`) para medirlo.

En esta app iría en Nest, nunca en el teléfono: la clave del proveedor no puede viajar dentro del APK. Usos con sentido, de más a menos útil:

1. **Buscar con lenguaje natural.** "Roguelikes cortos por menos de 3 dólares" se convierte en filtros (tags, precio máximo) con salida estructurada, y se cachea por consulta.
2. **"Por qué te lo recomiendo".** Una plantilla sobre las señales del puntaje (tags en común, descuento, reseñas) ya lo resuelve gratis y sin inventar nada. El modelo solo lo redactaría mejor.
3. **Resumir reseñas.** Es lo más caro, porque son muchos tokens de entrada, y además hay que conseguir las reseñas. Se haría por lotes y se cachearía por juego.

Para el uso personal no compensa en el MVP. Si se prueba, empieza por la búsqueda, detrás de un flag y con un tope de gasto mensual.

Detalle técnico: `@tanstack/ai` solo se publica como ESM. Nest 12 también, así que encaja si el servidor es ESM.

## App (Expo SDK 58)

Las versiones con `~` son las que fija el SDK. Las demás son la última en npm.

| Para qué | Paquete | Versión | Veredicto | Por qué |
| --- | --- | --- | --- | --- |
| Imágenes | `expo-image` | ~58.0.18 | usar | Caché en memoria y disco. `recyclingKey`, para que FlashList no muestre la imagen anterior al reciclar una celda. `transition.skipOnCacheHit`, para que lo cacheado no repita el fundido. `Image.prefetch` |
| Listas | `@shopify/flash-list` | 2.3.2 | usar | No hay que estimar tamaños y el SDK la fija. Legend List 3.7 queda de reserva |
| Animación | `react-native-reanimated` + `react-native-worklets` | 4.7.1 / 0.13.0 | usar | Muelles con `withSpring`. Bucles y cambios de color con su API CSS, que corre en el hilo de UI. Las transiciones de elemento compartido siguen experimentales y no se usan |
| Gestos | `react-native-gesture-handler` | ~3.3.0 | usar | API de hooks y `ReanimatedSwipeable` para deslizar y descartar. El builder `Gesture.Pan()` está deprecado y no se usa en código nuevo |
| Navegación | `expo-router` | ~58.0.29 | usar | Barra flotante propia con `expo-router/ui`. Los filtros van en una hoja nativa (`formSheet`) |
| Avisos | Propio, dentro de la barra | — | usar | El aviso sale de la barra de navegación (ver Toast), y ninguna librería de toasts dibuja eso. La forma se anima con Reanimated y el estado vive en Zustand |
| Estado del cliente | `zustand` | 5.0.16 | usar | Lo que vive solo en el teléfono: sesión, preferencias locales, borrador de Gustos, filtros de Explorar y el aviso de la barra. Persiste en MMKV con `persist` y `createJSONStorage`. Lo que viene del servidor no se copia acá: es de Query. TanStack Store haría lo mismo, pero sigue en alpha y su doc lo ata a ReactDOM |
| Tema y estilos | `react-native-unistyles` | 3.7.0 | usar | Toma los temas generados desde `tokens.json`, tipados y sin providers. Necesita development build |
| Caché local | `react-native-mmkv` | 4.3.2 | usar | Síncrono: el caché de Query y los ajustes se leen al abrir, sin esperar. Comparte `react-native-nitro-modules` con Unistyles |
| Cola de eventos | `expo-sqlite` | ~58.0.15 | usar | Guarda los eventos mientras no hay red y los borra por lotes al enviarlos |
| Sesión | `expo-secure-store` | ~58.0.2 | usar | El token de sesión va en el Keystore de Android |
| Red | `expo-network` | ~58.0.4 | usar | Avisa a Query cuándo hay red |
| Háptica | `expo-haptics` | ~58.0.7 | usar | `performAndroidHapticsAsync` con las respuestas del sistema (`Confirm`, `Reject`, `Segment_Tick`) |
| Avisos | `expo-notifications` | ~58.1.7 | usar | Push con imagen grande, y acciones Guardar y No me interesa que funcionan sin abrir la app |
| Íconos | `lucide-react-native` + `react-native-svg` | 1.66.0 / 15.16.0 | usar | Lucide, como en todo el sistema |
| Gráfico de precios | `@tanstack/charts` | 1.2.0 | evaluar | Ver TanStack |
| Cifras animadas | `number-flow-react-native` | 0.5.1 | evaluar | Anima el ahorro dígito a dígito con `Intl.NumberFormat`. Es 0.x y de un solo autor |
| Errores | `@sentry/react-native` | ~8.28.0 | usar | Cierres inesperados y errores de JS, en el mismo Sentry que el servidor |
| Compilador | React Compiler | incluido en `babel-preset-expo` 58 | usar | Memoiza solo. La plantilla del SDK 58 ya lo trae activado |
| Bundle | Expo Atlas | 0.5.0 | usar | Con `EXPO_ATLAS=true npx expo start` se ve qué ocupa espacio en el bundle |
| Pruebas de punta a punta | Maestro | CLI | usar | Expo documenta cómo correrlo en EAS Workflows |

## Contrato con el servidor

Los hooks de Query no se escriben a mano. El flujo es:

1. Nest describe la API con `@nestjs/swagger` 12, a partir de los esquemas de Zod 4.
2. El CI exporta `openapi.json`.
3. **orval** 8.46 genera los hooks de TanStack Query y el cliente `fetch`.

Si el cliente queda viejo respecto del contrato, el CI falla. openapi-typescript no sirve con TypeScript 7: falla en `ts.factory` (lo probamos). El detalle del servidor está en la investigación, §4.7.

## No

- **Moti:** no declara soporte para Reanimated 4.
- **`@gorhom/bottom-sheet`:** usa la API de gestos deprecada, y `formSheet` alcanza para los filtros.
- **`burnt`:** en Android usa el toast del sistema, que no admite el botón Deshacer.
- **`sonner-native`:** el aviso vive dentro de la barra, y una librería de toasts flota aparte.
- **Notifee:** el repo está archivado.
- **Skia y victory-native:**
  - Skia 3 exige Vulkan, así que Google Play oculta la app en los equipos que no lo tienen.
  - victory-native pide una versión de Skia que el SDK no fija.
- **Tamagui:** es un framework entero.
- **NativeWind:** Unistyles ya cubre el tema, y la v5 sigue en RC.
- **Lottie y Rive:** este sistema no usa ilustraciones.
- **`expo-blur`:** la barra es sólida, y el blur solo rinde bien desde Android 12.

## Para después

- **Widget de Android:** con `react-native-android-widget` 0.26, mostraría lo que termina hoy.
- **Thumbhash:** el barrido lo calcularía por juego para que la imagen cargue sobre una versión borrosa de sí misma. Suma trabajo al servidor.
- **TanStack DB:** cuando salga la 1.0 estable con soporte para el SDK 58.
