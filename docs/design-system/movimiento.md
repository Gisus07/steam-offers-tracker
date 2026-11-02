# Movimiento

El sistema de movimiento parte de cómo trabajas en tus otras apps: muelles firmes, sin rebote largo, y nada que bloquee un toque. En la app se implementa con **Reanimated 4**; en la web y en estas previews, con **Motion**. Los números son los mismos en los dos.

## Reglas

- Cada animación **explica un cambio, da continuidad, confirma o señala**. Si no, sobra.
- **Responder:** 150–250 ms. **Cambiar de lugar:** 250–400 ms.
- Muelles firmes, sin rebote largo. Nada bloquea el siguiente toque: una animación en curso se interrumpe y sigue desde donde está.
- Se define una vez por componente (botón, tarjeta, hoja, aviso) y se reutiliza.
- En listas largas solo anima lo que **entra**; al reciclar filas, nada se anima de nuevo.
- "Reducir movimiento" activo: todo desplazamiento pasa a un fundido de 150 ms; los contadores muestran el valor final.

## Recetas

### Toques y estados

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| Presionar botón (cápsula) | El radio baja de la mitad del alto a 16px y `scale: .97`, spring 600/18 | `withSpring` sobre `borderRadius` y `scale` en `onPressIn`; vuelve en `onPressOut` |
| Presionar botón (relieve, si se elige) | Baja 4px y el canto desaparece, en 110 ms | `withTiming` sobre `translateY` y el alto del canto, 110 ms |
| Presionar tarjeta | `scale: .98`, spring 600/18 | `withSpring(0.98, { stiffness: 600, damping: 18 })` en `onPressIn`; vuelve a 1 en `onPressOut` |
| Calcomanía nueva | `scale: .85 → 1`, spring 420/32 | `withSpring(1, { stiffness: 420, damping: 32 })` desde 0.85, solo la primera vez que se ve |
| Guardar | El ícono se rellena con `scale: .6 → 1`, spring 420/28. El ícono de Guardados de la barra late: 1,3 en 150 ms y vuelve con rebote | Igual con `withSpring` y `withSequence`, más `Haptics.performAndroidHapticsAsync(AndroidHaptics.Confirm)` |
| Error en un campo | Tiembla solo el campo, .4 s | `withSequence` de `translateX` ±6px, 400 ms en total |

### Navegación y avisos

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| Aviso en la barra | Abre: la cápsula pasa de 232×64 a 358×124 y de radio 32 a 28, spring 420/28; el mensaje aparece con un fundido de 220 ms a los 160 ms. Cierra: primero se va el mensaje (120 ms) y después vuelve la cápsula | `withSpring` sobre `width`, `height` y `borderRadius`; el mensaje con `withDelay(160, withTiming(1, { duration: 220 }))` |
| Círculo de la navegación | Posición compartida, spring 520/34 | `withSpring(x, { stiffness: 520, damping: 34 })` sobre `translateX` |
| Tarjeta → detalle | Abre: el detalle crece desde la tarjeta, `scale: .9 → 1` con fundido, spring 300/30. Cierra: `.94` con fundido de 180 ms | El detalle se monta sobre la lista. `measure()` da la posición de la tarjeta y `transformOrigin` la usa, con `withSpring` 300/30. No se usa elemento compartido: en Reanimated 4.7.1 sigue experimental y su doc no lo recomienda para producción |

### Listas y carga

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| No me interesa | La tarjeta sale a la izquierda (`x: −110%`) en 220 ms, la lista se cierra en 260 ms y la barra muestra el aviso con Deshacer. Deshacer abre el espacio y la tarjeta vuelve | `ReanimatedSwipeable` o gesto con `withTiming(-width, { duration: 220 })`, y `LinearTransition` en la lista |
| Esqueleto → tarjetas | El esqueleto se desvanece en 220 ms; las tarjetas suben 12px con fundido en 280 ms, escalonadas 70 ms | `entering={FadeInDown.duration(280).delay(i * 70)}` solo en la primera página (entra desde abajo); las filas recicladas no se animan |
| Esqueleto | Brillo de 1,6 s en bucle | `expo-linear-gradient` movido con la API CSS de Reanimated (`animationName` con keyframes de `translateX`, 1,6 s, `infinite`); se apaga con reducir movimiento |
| Desplegar (filtros) | Altura .28 s `[.2, 0, 0, 1]`, filas en cascada de .06 s | `withTiming` con `Easing.bezier(.2, 0, 0, 1)`, retraso por fila de 60 ms |
| Contar cifras (ahorro) | .8 s `[.16, 1, .3, 1]` | `withTiming(valor, { duration: 800, easing: Easing.bezier(.16, 1, .3, 1) })` |

### Bienvenida

Corre solo la primera vez que se abre la app. En la app, cada pieza es un `withDelay` seguido de `withSpring`.

| Pieza | Qué hace | Cuándo empieza |
| --- | --- | --- |
| Tarjetas de la ilustración | Se acomodan en 560 ms | 0, 90 y 180 ms |
| Calcomanías | Se pegan una a una desde `scale: 1.8`, spring 420/32 | 520, 640 y 780 ms |
| Título, texto y botones | Suben 14px con fundido | Entre 900 y 1.060 ms |

## Qué no se anima

- La cuenta regresiva no corre segundo a segundo: se actualiza una vez por minuto, sin animación.
- Nada se anima al hacer scroll más allá de las filas que entran por primera vez.
- No hay animaciones de carga en bucle fuera de los esqueletos.
