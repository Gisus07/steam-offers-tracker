La tarjeta de una oferta: imagen del juego, calcomanía, nombre, tags, precio, cuenta regresiva y las acciones Guardar y No me interesa.

## Qué provee quien la usa
- La oferta (`appid`, nombre, imagen, `discount_pct`, precios, moneda, `discount_end_at`), sus tres tags con más peso y el estado del usuario (guardada o no).
- Si viene de la cuota de exploración, `reason="explore"`: la tarjeta suma el chip `info` "Algo distinto".

## Anatomía
- Imagen en proporción 616×353 sobre `surface-raised`; sin imagen, el nombre del juego en `surface-raised`.
- DealSticker `md` pegada sobre el borde inferior izquierdo de la imagen.
- Nombre en `title-md`, dos líneas como máximo; hasta tres chips de tag.
- PriceBlock `card` a la izquierda; CountdownChip encima del precio.
- Acciones a la derecha, al alcance del pulgar, en botones de ícono de 44px (Button, de ícono).
- Fondo `surface`, borde `line`, radio `radius-card`, sombra `shadow-card`.

## Comportamiento
- **Al cargar:** entra con un fundido y 12px de subida, escalonada 70 ms por tarjeta, mientras el esqueleto se desvanece.
- **Tocar:** abre el detalle, que crece desde la tarjeta (escala .9 → 1 y fundido, muelle 300/30). Cerrar lo encoge hacia el mismo punto.
- **Presionar:** escala .98, muelle 600/18. El botón de ícono presionado se aplana según la forma de Button.
- **Guardar:**
  - el ícono `bookmark` se rellena (escala .6 → 1, muelle 420/28), con háptica ligera y estado `good`;
  - el ícono de Guardados de la barra late una vez.
- **No me interesa:** se activa al deslizar a la izquierda o con el ícono `x`.
  - La tarjeta sale hacia la izquierda en 220 ms y la lista se cierra en 260 ms.
  - La barra muestra el aviso con Deshacer. Deshacer abre el espacio y la tarjeta vuelve desde la izquierda.
  - Registra el evento `dismiss`; Deshacer registra `undismiss`.
- **Eventos de uso:** cada vez que la tarjeta queda visible al menos un segundo se registra una `impression`; el tiempo en el detalle se registra como `dwell`.

## No
- No pongas más de tres tags ni la descripción del juego en la tarjeta.
- No escondas Guardar o No me interesa en un menú.
