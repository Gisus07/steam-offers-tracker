La tarjeta de una oferta: imagen del juego, calcomanía, nombre, tags, precio, cuenta regresiva y las acciones Guardar y No me interesa.

## Qué provee quien la usa
- La oferta (`appid`, nombre, imagen, `discount_pct`, precios, moneda, `discount_end_at`), sus tres tags con más peso y el estado del usuario (guardada o no).
- Si viene de la cuota de exploración, `reason="explore"`: la tarjeta suma el chip `info` "Algo distinto".

## Anatomía
- Imagen en proporción 616×353 sobre `surface-raised`; sin imagen, el nombre del juego en `surface-raised`.
- DealSticker `md` pegada sobre el borde inferior izquierdo de la imagen.
- Nombre en `title-md`, dos líneas como máximo; hasta tres chips de tag.
- PriceBlock `card` a la izquierda; CountdownChip encima del precio.
- Acciones a la derecha, al alcance del pulgar, en botones de ícono de 44px con canto (Button, de ícono).
- Fondo `surface`, borde `line`, radio `radius-card`, sombra `shadow-card`.

## Comportamiento
- **Al cargar:** el esqueleto se convierte en la tarjeta. Un brillo la cruza y cada bloque toma la forma de su pieza (ver Skeleton).
- **Calcomanía:** la primera vez que la oferta aparece, baja como un sello y se asienta (ver DealSticker).
- **Presionar:** escala .98 en 120 ms. Los botones de ícono se hunden (Button).
- **Tocar:** abre el detalle con un contenedor que se transforma. La tarjeta crece hasta ocupar la pantalla y la lista de atrás se aleja (ver Movimiento). Cerrar la devuelve a su lugar.
- **Guardar:**
  - el ícono `bookmark` se aplasta, se rellena y estalla en puntos `good`;
  - una copia vuela a Guardados en la barra, que late (ver Movimiento);
  - háptica `Confirm` y estado `good`.
- **No me interesa:** se activa al deslizar a la izquierda o con el ícono `x`.
  - Al agarrarla se levanta (1,03 y más sombra). Al soltarla pasado el umbral, se lanza y se achica; si no, vuelve a su lugar. Con el ícono se lanza sin levantarse.
  - La lista se cierra en 340 ms y la barra muestra el aviso con Deshacer. Deshacer abre el espacio y la tarjeta vuelve.
  - Registra el evento `dismiss`; Deshacer registra `undismiss`.
- **Eventos de uso:** cada vez que la tarjeta queda visible al menos un segundo se registra una `impression`; el tiempo en el detalle se registra como `dwell`.

## No
- No pongas más de tres tags ni la descripción del juego en la tarjeta.
- No escondas Guardar o No me interesa en un menú.
