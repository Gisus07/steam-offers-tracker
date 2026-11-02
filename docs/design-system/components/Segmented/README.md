Control segmentado para cambiar entre vistas hermanas de una misma pantalla, como Para ti y Terminan pronto.

## Reglas
- Dos o tres opciones, nunca más. Fondo `surface-raised` en cápsula (radio completo); la pastilla seleccionada en `surface` con `shadow-card`, también en cápsula.
- Texto `ink-2`; el seleccionado en `ink`. Estilo `button-text` a 14px.
- No lleva canto: elige, no hace (ver Button).
- También se usa en Ajustes para el descuento mínimo (30 / 50 / 70%).

## Movimiento
- **La pastilla es elástica:** el borde que avanza tira con muelle 520/36 y el otro lo sigue 150 ms después con 340/28.
- **Apretón:** al soltarse, la pastilla se aprieta en vertical (.86 → 1, muelle 420/16).
- **Texto:** cambia de `ink-2` a `ink` en 200 ms.
- **Con "reducir movimiento":** cambia sin desplazarse.

## En la app
- Los bordes izquierdo y derecho de la pastilla son dos valores con `withSpring`; el que sigue va con `withDelay(150, …)`.
- El color del texto cambia con una transición CSS de Reanimated, que no tiene muelle.
- Cada cambio va con háptica `AndroidHaptics.Segment_Tick`.
