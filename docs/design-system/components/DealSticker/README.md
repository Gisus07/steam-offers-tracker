La calcomanía amarilla con el porcentaje de descuento: lo primero que se lee de cualquier oferta.

## Cuándo usarla
- Una por oferta, pegada sobre la esquina inferior izquierda de la imagen (tarjeta) o junto al precio (detalle).
- Nunca para otra cosa que no sea el descuento: ni etiquetas de "nuevo", ni categorías.

## Qué provee quien la usa
- `pct`: entero de 1 a 100. Se muestra como "−85%" con el signo menos U+2212.
- `size`: `sm` (listas compactas, sin inclinación), `md` (tarjeta), `lg` (detalle).

## Reglas
- Fondo `deal`, texto `on-deal`, estilo `sticker-text`, radio `radius-sticker`, sombra `shadow-sticker`.
- Inclinada −3° en `md` y `lg`; recta en `sm`. Es la única pieza inclinada de la interfaz.
- Etiqueta accesible: "85 por ciento de descuento".

## Movimiento
- **Sello que se asienta**, solo la primera vez que una oferta nueva aparece en pantalla:
  - baja como un sello: escala 1,8 → 1, muelle 340/26;
  - el giro se asienta bamboleando: 16° → −3°, muelle 260/9;
  - la imagen de abajo recibe un golpe: baja 4px y vuelve en 260 ms.
- Nunca al reciclar filas ni al volver a una pantalla.
