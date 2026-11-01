La tarjeta de una oferta: imagen del juego, calcomanía, nombre, tags, precio, cuenta regresiva y las acciones Guardar y No me interesa.

## Qué provee quien la usa
- La oferta (`appid`, nombre, imagen, `discount_pct`, precios, moneda, `discount_end_at`), sus tres tags con más peso y el estado del usuario (guardada o no).
- Si viene de la cuota de exploración, `reason="explore"`: la tarjeta suma el chip `info` "Algo distinto".

## Anatomía
- Imagen en proporción 616×353 sobre `surface-raised`; sin imagen, el nombre del juego en `surface-raised`.
- DealSticker `md` pegada sobre el borde inferior izquierdo de la imagen.
- Nombre en `title-md`, dos líneas como máximo; hasta tres chips de tag.
- PriceBlock `card` a la izquierda y las acciones a la derecha, al alcance del pulgar; CountdownChip debajo del nombre.
- Fondo `surface`, borde `line`, radio `radius-card`, sombra `shadow-card`.

## Comportamiento
- **Tocar:** abre el detalle; la imagen y la calcomanía son elementos compartidos (muelle 300/30).
- **Presionar:** escala .97, muelle 600/18.
- **Guardar:** el ícono `bookmark` se rellena (escala .6 → 1, muelle 420/28), háptica ligera y estado `good`.
- **No me interesa:** deslizar a la izquierda o el ícono `x`. La tarjeta sale hacia la izquierda en 220 ms, la lista se cierra y aparece el Toast con Deshacer. Registra el evento `dismiss`; Deshacer registra `undismiss`.
- Cada vez que la tarjeta queda visible al menos un segundo se registra una `impression`; el tiempo en el detalle se registra como `dwell`.

## No
- No pongas más de tres tags ni la descripción del juego en la tarjeta.
- No escondas Guardar o No me interesa en un menú.
