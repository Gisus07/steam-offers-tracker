Offers Tracker avisa a cada persona de ofertas de Steam que le van a gustar, en la moneda de su región, antes de que terminen. La app es Android primero (Expo / React Native); estas reglas valen para la app, la web de presentación y cualquier pantalla nueva.

> El nombre público todavía no está decidido. No uses la palabra "Steam" ni el logo de Steam como marca propia: los términos de Valve prohíben dar a entender una relación con Steam. Mientras tanto, el nombre va en texto plano, sin logotipo.

## Principios

- **El descuento manda.** Lo primero que se lee en cualquier oferta es la calcomanía `deal`, después el precio final y después cuándo termina.
- **Un color, un significado.** Cada color dice una sola cosa (tabla abajo). Si algo no tiene significado, va en neutros.
- **Nada afirma lo que no se comprobó.** Si los datos son viejos, la pantalla lo dice ("Actualizado hace 3 h"); si un precio mínimo no está registrado, no se inventa.
- **El movimiento explica.** Cada animación explica un cambio, da continuidad, confirma o señala; si no hace ninguna de esas cuatro cosas, sobra. Detalle en Movimiento.

## Voz y textos

- Español neutro de Latinoamérica, con **tú**: "Te avisamos cuando baje", nunca "os" ni "vos".
- Frases cortas, números primero: "−85% · Termina en 2 d 4 h".
- Sin signos de exclamación, sin emoji, sin "¡Ups!" ni disculpas. Un error dice qué pasó y cómo seguir: "No pudimos actualizar las ofertas. Revisa tu conexión y vuelve a intentarlo."
- Los botones dicen lo que hacen: "Ir a Steam", "Guardar", "No me interesa", "Deshacer". La confirmación usa el mismo verbo: "Guardado".
- Precios con `Intl.NumberFormat` del país y la moneda del usuario: Venezuela muestra "USD 4,99"; Argentina, "US$ 4,99"; México, "$4.99". El peso colombiano va sin decimales.
- El descuento se escribe "−85%" con el signo menos tipográfico (U+2212) en la calcomanía y "85% de descuento" en texto corrido.
- Fechas relativas en la cuenta regresiva ("Termina en 2 d 4 h", "Termina hoy, 18:00") y absolutas en el detalle ("Termina el 12 de noviembre, 13:00").

## Color

| Token | Significa | Nunca |
| --- | --- | --- |
| `deal` / `on-deal` | El descuento. Solo la calcomanía. | Botones, fondos, gráficos |
| `accent` / `on-accent` / `accent-soft` | Lo que se toca: botón primario, links, ícono activo, foco | Texto decorativo, estados |
| `hot` / `hot-soft` | Termina en menos de 24 horas | Errores |
| `good` / `good-soft` | Guardado, mínimo registrado, compra marcada | Cualquier cosa que no sea una buena noticia |
| `bad` / `bad-soft` | Algo falló | Ofertas que terminan |
| `info` / `info-soft` | Información neutra, sin conexión | Llamados a la acción |

- Pinta las pantallas sobre `bg`; las tarjetas, la navegación y las hojas sobre `surface`; campos, chips y esqueletos sobre `surface-raised`.
- Texto principal y precios en `ink`; secundario en `ink-2`; tachado y metadatos en `ink-3`. Las tres pasan 4,5:1 sobre `bg`, `surface` y `surface-raised` en ambos temas.
- El filtro activo se invierte a `ink` sobre fondo y texto `bg`. No se pinta de `accent`: el acento es para tocar, no para estado.
- Sobre un relleno `accent` el texto es `on-accent`, nunca blanco literal: en oscuro el acento es claro y pide texto oscuro.
- `hot`, `good` y `bad` siempre van con ícono o palabra. El color nunca es la única señal.
- El tema oscuro es el principal; el claro sigue las mismas reglas con sus valores.

## Tipografía

- Dos familias: **Big Shoulders Display**, condensada como un cartel de precios, para precios, la calcomanía y el título de pantalla; **Hanken Grotesk** para todo lo demás.
- Precio final en `price-card` (tarjeta) o `price-hero` (detalle); calcomanía en `sticker-text`; título de pantalla en `screen-title`, una sola vez por pantalla.
- Nombre del juego en `title-md` (tarjeta, máximo dos líneas) o `title-lg` (detalle). Texto en `body`; metadatos en `body-sm`; encabezados de sección en `label`, en mayúsculas.
- Cuentas regresivas y cifras que cambian en `caption` con cifras tabulares (`font-variant-numeric: tabular-nums`; en React Native, `fontVariant: ['tabular-nums']`) para que no salten.
- Nunca uses Big Shoulders Display para texto corrido ni por debajo de 18px.

## Espacio, forma y profundidad

- Paso base de 8px con medio paso de 4px: `space-1` a `space-10`. Margen lateral de pantalla `space-4`; entre secciones `space-8`.
- Radios por rol: calcomanía `radius-sticker`, campo `radius-field`, botón `radius-button`, aviso `radius-notice`, tarjeta `radius-card`, navegación `radius-nav`, hoja `radius-sheet`, chips `radius-pill`.
- La calcomanía va inclinada −3° sobre la esquina de la imagen, como una etiqueta pegada a mano. Es la única pieza inclinada de la interfaz.
- Sombras en dos capas: `shadow-card` en reposo, `shadow-float` para lo que flota, `shadow-sticker` para la calcomanía. Bordes de 1px en `line`.
- Toda área táctil mide `size-tap` o más; botones `size-button`; chips de filtro `size-chip`.

## Estados

- **Cargando:** esqueletos con la forma del contenido (Skeleton). Nunca spinners de pantalla completa.
- **Vacío:** un solo diseño (EmptyState): ícono, título, qué pasa y la salida.
- **Error:** aviso flotante con `bad`, qué pasó y qué hacer. Los avisos flotan; nunca empujan el contenido.
- **Sin conexión:** pastilla `info` arriba ("Sin conexión · mostrando lo de las 14:20"). La app sigue funcionando con lo guardado.
- **Desactualizado:** si el último barrido tiene más de 12 horas, el encabezado dice "Actualizado hace N h".

## Íconos

- **Lucide**, trazo 2, extremos redondos. En la app, `lucide-react-native`; en la web, `lucide`. Tamaño `size-icon` (20px) en controles, 16px en chips, 24px en la navegación.
- Íconos que se animan en la app (con Reanimated, ver Movimiento): `bookmark` al guardar, `bell` al llegar un aviso, `refresh-cw` al actualizar, `wifi-off` sin conexión, `check` al confirmar. En la web de presentación se pueden usar AnimateIcons; en la app no, porque dependen de Motion para web.
- Íconos fijos: `clock` (cuenta regresiva), `trending-down` (mínimo registrado), `external-link` (ir a Steam), `x` (no me interesa), `sparkles` (Para ti), `search` (Explorar), `settings` (Ajustes), `circle-alert` (error).
- Sin emoji en la interfaz.

## Foco y accesibilidad

- Anillo de foco: 2px sólido en `accent` con 2px de separación. Pasa 3:1 sobre `bg`, `surface` y `surface-raised` en ambos temas.
- Respeta "reducir movimiento" del sistema: lo que se desplaza pasa a un fundido corto.
- Cada control tiene etiqueta accesible; la calcomanía se lee "85 por ciento de descuento".

## Imágenes

- La imagen de cada juego viene de Steam: cápsula horizontal en la tarjeta y en el detalle. No se recorta el texto del juego: proporción 616×353 o 460×215 según la vista.
- Sin imagen, la tarjeta muestra `surface-raised` con el nombre del juego; nunca un ícono genérico.
