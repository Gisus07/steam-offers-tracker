Aviso breve que confirma una acción, ofrece deshacerla o informa un error, flotando sin empujar el contenido. Hay tres variantes en evaluación; se elige una.

## Variantes en evaluación
- **A · Cápsula invertida:** pastilla en `ink` con texto `bg` y la acción en `accent-on-inverse`. Se lee en cualquier pantalla porque invierte el tema. Flota sobre la navegación.
- **B · Isla superior:** cápsula chica arriba al centro, en `surface-raised`, que crece para mostrar la acción. No tapa la navegación ni las tarjetas de abajo.
- **C · Barra con tiempo:** tarjeta sobre la navegación con una línea `accent` que se vacía en 5 s: muestra cuánto queda para deshacer.

## Reglas comunes
- Uno a la vez: el nuevo reemplaza al anterior. Dura 5 s; tocarlo pausa el tiempo.
- Ícono de Lucide y una frase: "No te mostraremos más este juego" · Deshacer. Error: ícono `circle-alert` en `bad`, qué pasó y Reintentar.
- Nunca empuja el contenido ni bloquea la lista.

## Movimiento
- A y C entran desde abajo (`y` 24 → 0, muelle 420/26); B baja desde arriba y se expande a lo ancho (muelle 420/28). Salen con fundido de 150 ms. C anima su línea de tiempo de forma lineal en 5 s. Con "reducir movimiento", solo fundido y la línea queda fija.

## En la app
- `sonner-native`, dibujado con `toast.custom()` sobre los tokens. Configuración en Implementación en la app.
- No se usa el toast del sistema de Android: no admite el botón Deshacer.
