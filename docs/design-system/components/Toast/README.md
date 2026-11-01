Aviso flotante y breve que confirma una acción, ofrece deshacerla o informa de un error, sin empujar el contenido.

## Variantes
- **Confirmación con Deshacer:** "No te mostraremos más este juego" · Deshacer. Ícono `eye-off`.
- **Buena noticia:** "Guardado" con ícono `check` en `good`. Solo cuando la acción no se ve en el mismo control.
- **Error:** fondo `bad-soft`, ícono `circle-alert` en `bad`, qué pasó y la salida: "No pudimos actualizar las ofertas" · Reintentar.

## Reglas
- Flota sobre la navegación, a `space-4` de los lados. Fondo `surface`, borde `line`, radio `radius-notice`, sombra `shadow-float`.
- Uno a la vez: el nuevo reemplaza al anterior. Dura 5 s; con Deshacer, el tiempo se reinicia si el usuario lo toca.
- Texto `body` a 14px, una línea si entra; la acción como botón de texto.

## Movimiento
- Entra desde abajo: `y` 24 → 0 y opacidad, muelle 420/26. Sale con fundido de 150 ms. Con "reducir movimiento", solo fundido.
