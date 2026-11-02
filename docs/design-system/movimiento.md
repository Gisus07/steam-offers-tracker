# Movimiento

El sistema de movimiento parte de cómo trabajas en tus otras apps: nada bloquea un toque, lo que cambia de lugar lo hace con muelles firmes, y el rebote se guarda para lo que confirma. En la app se implementa con **Reanimated 4**; en la web y en estas previews, con **Motion**. Los números son los mismos en los dos. La excepción es el hundido de los botones en los previews, que va en CSS con una curva que imita el muelle.

Cada receta de abajo es la que se eligió el 2 de noviembre de 2026 en el [Catálogo de movimiento](https://claude.ai/artifact/6uHib8zkYZL6NaeurjmnYq), donde están lado a lado con las demás opciones y se pueden ver a ½× y ¼×.

## Reglas

- Cada animación **explica un cambio, da continuidad, confirma o señala**. Si no, sobra.
- **Responder al toque:** 120–140 ms (el hundido del botón, el aplaste de Guardar). **Confirmar o cambiar de lugar:** 200–400 ms. Una secuencia que cuenta algo, como guardar o la bienvenida, puede durar más, pero nunca bloquea el siguiente toque.
- **Muelles:** firmes en lo que cambia de lugar (rigidez 200–520, amortiguación 24–36). El rebote se guarda para lo que confirma: guardar, la calcomanía, el filtro, el ícono de la barra y el apretón del segmentado.
- Una animación en curso se interrumpe y sigue desde donde está, sin heredar el impulso de un salto.
- Se define una vez por componente (botón, tarjeta, hoja, aviso) y se reutiliza.
- En listas largas solo anima lo que **entra**; al reciclar filas, nada se anima de nuevo.
- "Reducir movimiento" activo: todo desplazamiento pasa a un fundido de 150 ms; los contadores muestran el valor final.

## Recetas

### Toques y estados

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| Presionar un botón (estilo control) | La cara baja 4px en 120 ms y el canto desaparece. Al soltar vuelve con muelle 500/26. El botón de texto no tiene canto: al presionar toma fondo `accent-soft` | `withTiming(4, { duration: 120 })` sobre el `translateY` de la cara y el alto del canto (`4 − d`); `withSpring(0, { stiffness: 500, damping: 26 })` al soltar. El canto es una View debajo de la cara, porque React Native no tiene sombras sólidas desplazadas. Háptica `AndroidHaptics.Virtual_Key` al hundir y `Virtual_Key_Release` al soltar |
| Presionar tarjeta | `scale: .98` en 120 ms; al soltar vuelve con muelle 500/26 | `withTiming(0.98, { duration: 120 })` en `onPressIn`; `withSpring(1, { stiffness: 500, damping: 26 })` en `onPressOut` |
| Guardar: se aplasta, estalla y vuela | 1) El ícono se aplasta (`scaleX` 1,22 y `scaleY` .72) en 140 ms. 2) Se rellena y rebota con muelle 420/14, y 8 puntos `good` se alejan unos 34px y se apagan en 600 ms. 3) A los 180 ms sale una copia que vuela a Guardados en 700 ms: `x` con `easeOut`, `y` con `[.55, 0, .85, .35]` (juntas dibujan un arco) y la escala baja a .55. 4) Al llegar, Guardados se rellena un momento, late (1,3 en 180 ms y vuelve con muelle 380/14) y suelta 5 puntos | `withSequence(withTiming(0.72, { duration: 140 }), withSpring(1, { stiffness: 420, damping: 14 }))` en el aplaste; la copia se mide con `measure()` en un worklet y vuela con `withDelay(320, withTiming(…))` en `x` e `y`, con curvas distintas; Guardados con `withDelay(1020, withSequence(…))`. Háptica `AndroidHaptics.Confirm` |
| Calcomanía nueva: sello que se asienta | Baja como un sello: escala 1,8 → 1 con muelle 340/26, y giro 16° → −3° con muelle 260/9, que se asienta bamboleando. La imagen de abajo recibe un golpe: baja 4px y vuelve en 260 ms, a los 140 ms. Solo la primera vez que se ve | `withSpring` por separado para escala y giro; el golpe con `withDelay(140, withSequence(withTiming(4, { duration: 80 }), withTiming(0, { duration: 180 })))` |
| Filtro: check, rebote y lista | El chip se invierte en 280 ms, crece para el check con muelle 400/30 y rebota (1,08 en 140 ms, vuelve con muelle 380/14). A los 120 ms la lista se reacomoda: la fila que sale se va en 240 ms (fundido y escala .96) y las demás se corren con muelle 320/30 | `interpolateColor` para el fondo del chip; `layout={LinearTransition.springify().stiffness(400).damping(30)}` en el chip, y en las filas `.stiffness(320).damping(30)` con `exiting={FadeOut.duration(240)}` |
| Segmentado: elástica con apretón | El borde de la pastilla que avanza tira con muelle 520/36 y el otro lo sigue 150 ms después con 340/28. Al soltarse, la pastilla se aprieta en vertical (`scaleY` .86 → 1, muelle 420/16). El texto cambia de color en 200 ms | Borde izquierdo y derecho como dos valores con `withSpring`, el que sigue con `withDelay(150, …)`; el apretón con `withDelay(150, withSequence(withTiming(0.86, { duration: 90 }), withSpring(1, { stiffness: 420, damping: 16 })))`. Háptica `AndroidHaptics.Segment_Tick` |
| Precio y ahorro: rodillo, cuenta y tachado | Cada dígito del precio rueda hasta el nuevo con muelle 200/24, 90 ms después del anterior. El ahorro cuenta desde 0 en 1100 ms con `[.16, 1, .3, 1]`. El precio anterior se tacha con una línea que se dibuja en 360 ms, a los 300 ms | Una columna 0–9 por dígito con `withDelay(i * 90, withSpring(…))`; el ahorro con `withTiming` sobre un `TextInput` animado (patrón ReText); la línea con `scaleX` y `transformOrigin: 'left'` |
| Error en un campo | Tiembla solo el campo, .4 s | `withSequence` de `translateX` ±6px, 400 ms en total |

### Navegación y avisos

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| Barra: círculo elástico e ícono que se rellena | El borde del círculo que avanza tira con muelle 520/36 y el otro lo sigue 150 ms después con 340/28. A los 300 ms el ícono de destino se rellena, se encoge a .8 en 120 ms y rebota con muelle 380/16. El ícono activo queda relleno | `left` y `right` del círculo como dos valores con `withSpring`, el que sigue con `withDelay(150, …)`; el ícono con `withDelay(300, withSequence(withTiming(0.8, { duration: 120 }), withSpring(1, { stiffness: 380, damping: 16 })))` |
| Aviso en la barra | Abre: la cápsula pasa de 232×64 a 358×124 y de radio 32 a 28 con muelle 340/28; el mensaje entra con un fundido de 260 ms a los 200 ms. Cierra: el mensaje se va en 180 ms y la cápsula vuelve con el mismo muelle 100 ms después. No muestra cuánto queda: dura 5 s | `withSpring` sobre `width`, `height` y `borderRadius`; el mensaje con `withDelay(200, withTiming(1, { duration: 260 }))` |
| Tarjeta → detalle: contenedor y fondo que se aleja | La caja de la tarjeta crece hasta la pantalla (posición, tamaño y radio 16 → 0) con muelle 240/28. La tarjeta se apaga en 140 ms y el detalle aparece en 260 ms a los 160 ms. La lista de atrás baja a .94 con el mismo muelle y un velo la oscurece en 300 ms. Cerrar es lo mismo al revés | `measure()` da la caja de la tarjeta; `left`, `top`, `width`, `height` y `borderRadius` se interpolan de esa caja a la pantalla con `withSpring(1, { stiffness: 240, damping: 28 })`. No se usa elemento compartido: en Reanimated 4.7.1 sigue experimental y su doc no lo recomienda para producción |
| Hoja de filtros: crece desde el chip y el fondo se achica | La caja del chip "Filtros" crece hasta la hoja con muelle 240/28. La pantalla de atrás baja a .92, se corre 4px y toma radio 14 con el mismo muelle, bajo un velo de 280 ms. El chip se apaga en 140 ms y la hoja aparece en 260 ms a los 160 ms | Igual que el detalle, desde `measure(chipRef)`; atrás, `scale` y `borderRadius` interpolados |
| Cambio de tema: círculo e ícono que gira | Se captura la pantalla, cambia el tema y la captura se recorta con un círculo que crece desde el botón en 760 ms con `[.4, 0, .2, 1]`. El ícono: la luna gira 180° y se apaga, y el sol entra girando de −180° a 0, en 500 ms | `captureScreen` de react-native-view-shot 6.1.1, `UnistylesRuntime.setTheme` y la máscara con `@react-native-masked-view/masked-view` 0.3.2 (los dos fijados por el SDK 58). Es la más cara: una captura por cambio |

### Listas y carga

| Qué | Motion (web) | Reanimated (app) |
| --- | --- | --- |
| No me interesa: se levanta y se lanza | Al agarrarla, la tarjeta sube a 1,03 con muelle 420/30 y su sombra crece en 200 ms. Sigue al dedo. Si se suelta pasado el umbral, sale hacia la izquierda en 320 ms con giro −10°, escala .92 y fundido; si no, vuelve a su lugar con muelle 300/30. Con el ícono `x` se lanza sin levantarse. El hueco se cierra en 340 ms con `[.2, 0, 0, 1]` y la barra muestra el aviso con Deshacer. Deshacer abre el hueco en 340 ms y la tarjeta vuelve con muelle 300/30 | Un gesto de arrastre de Gesture Handler 3: al empezar, `withSpring(1.03, { stiffness: 420, damping: 30 })`; al soltar pasado el umbral, `withTiming` de 320 ms en `translateX`, giro, escala y opacidad. La lista se acomoda con `LinearTransition.duration(340)` |
| Esqueleto (esperando) | Bloques `surface-raised` con un brillo de 1,6 s en bucle | `expo-linear-gradient` movido con la API CSS de Reanimated (`animationName` con keyframes de `translateX`, 1,6 s, `infinite`); se apaga con reducir movimiento |
| Esqueleto → tarjeta: el brillo va formando la tarjeta | Cuando llegan los datos, un último brillo cruza la tarjeta en 900 ms, a ritmo constante. Cada bloque toma el tamaño de su pieza cuando el centro del brillo pasa por él (muelle 260/26; el título y el precio un poco después, para que la tarjeta se forme en diagonal) y se cruza con la pieza real en 220 ms. Solo en la primera página | El tamaño de cada pieza sale de `onLayout`; cada bloque con `withDelay(t, withSpring(…, { stiffness: 260, damping: 26 }))`, con `t` según su `x`. Falta probarlo dentro de FlashList |
| Desplegar (filtros) | Altura .28 s `[.2, 0, 0, 1]`, filas en cascada de .06 s | `withTiming` con `Easing.bezier(.2, 0, 0, 1)`, retraso por fila de 60 ms |

### Bienvenida: la calcomanía se vuelve el botón

Corre solo la primera vez que se abre la app. En la app, cada pieza es un `withDelay` seguido de `withSpring` o `withTiming`.

| Pieza | Qué hace | Cuándo empieza |
| --- | --- | --- |
| Tarjetas de la ilustración | Suben 30px y se acomodan girando, con muelle 240/22 | 0, 120 y 240 ms |
| Calcomanías | Se pegan una a una desde escala 1,8 y 12° más de giro, con muelle 340/26 | 700, 860 y 1040 ms |
| Título, texto y "Ver ofertas sin cuenta" | Suben 12px con un fundido de 520 ms | Desde 1300 ms, cada 100 ms |
| La calcomanía más grande | Toma la caja, el radio y el color del botón "Iniciar sesión con Steam" (muelle 220/26). Su texto se va en 160 ms y entra el del botón en 260 ms | 2600 ms |
| El botón | Aparece su canto (`ink-lip`, 200 ms) y se hunde una vez, como un toque | 3100 y 3800 ms |

## Qué no se anima

- La cuenta regresiva no corre segundo a segundo: se actualiza una vez por minuto, sin animación.
- Nada se anima al hacer scroll más allá de las filas que entran por primera vez.
- No hay animaciones de carga en bucle fuera de los esqueletos.
