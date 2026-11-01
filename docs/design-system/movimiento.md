# Movimiento

El sistema de movimiento parte de cómo trabajas en tus otras apps: muelles firmes, sin rebote largo, y nada que bloquee un toque. En la app se implementa con **Reanimated 4**; en la web y en estas previews, con **Motion**. Los números son los mismos en los dos.

## Reglas

- Cada animación **explica un cambio, da continuidad, confirma o señala**. Si no, sobra.
- **Responder:** 150–250 ms. **Cambiar de lugar:** 250–400 ms.
- Muelles firmes, sin rebote largo. Nada bloquea el siguiente toque: una animación en curso se interrumpe y sigue desde donde está.
- Se define una vez por componente (botón, tarjeta, hoja, toast) y se reutiliza.
- En listas largas solo anima lo que **entra**; al reciclar filas, nada se anima de nuevo.
- "Reducir movimiento" activo: todo desplazamiento pasa a un fundido de 150 ms; los contadores muestran el valor final.

## Recetas

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| Presionar tarjeta o botón | `scale: .97`, spring 600/18 | `withSpring(0.97, { stiffness: 600, damping: 18 })` en `onPressIn`; vuelve a 1 en `onPressOut` |
| Aparecer (toast, aviso) | `y: 24 → 0`, `opacity 0 → 1`, spring 420/26 | `entering={FadeInDown.springify().stiffness(420).damping(26)}` |
| Calcomanía nueva | `scale: .85 → 1`, spring 420/32 | `withSpring(1, { stiffness: 420, damping: 32 })` desde 0.85, solo la primera vez que se ve |
| Pastilla de la navegación | posición compartida, spring 520/34 | `withSpring(x, { stiffness: 520, damping: 34 })` sobre `translateX` y `width` |
| Tarjeta → detalle | elemento compartido, spring 300/30 | transición de elemento compartido de la imagen y la calcomanía; si no está disponible en la versión instalada, entrada del detalle desde la tarjeta con escala .96 → 1 |
| Guardar | el ícono se rellena con `scale: .6 → 1`, spring 420/28, y háptica ligera | igual con `withSpring`, más `Haptics.impactAsync(Light)` |
| No me interesa | la tarjeta sale a la izquierda `x: −100%` en 220 ms y la lista se cierra; aparece el toast con Deshacer | `ReanimatedSwipeable` o gesto con `withTiming(-width, { duration: 220 })` y `LinearTransition` en la lista |
| Desplegar (filtros) | altura .28 s `[.2, 0, 0, 1]`, filas en cascada de .06 s | `withTiming` con `Easing.bezier(.2, 0, 0, 1)`, retraso por fila de 60 ms |
| Contar cifras (ahorro) | .8 s `[.16, 1, .3, 1]` | `withTiming(valor, { duration: 800, easing: Easing.bezier(.16, 1, .3, 1) })` |
| Esqueleto | brillo de 1,6 s en bucle | gradiente animado de 1,6 s; se apaga con reducir movimiento |
| Error en un campo | tiembla solo el campo, .4 s | `withSequence` de `translateX` ±6px, 400 ms en total |

## Qué no se anima

- La cuenta regresiva no corre segundo a segundo: se actualiza una vez por minuto, sin animación.
- Nada se anima al hacer scroll más allá de las filas que entran por primera vez.
- No hay animaciones de carga en bucle fuera de los esqueletos.
