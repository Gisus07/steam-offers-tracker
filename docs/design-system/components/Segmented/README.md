Control segmentado para cambiar entre vistas hermanas de una misma pantalla, como Para ti y Terminan pronto.

## Reglas
- Dos o tres opciones, nunca más. Fondo `surface-raised`, radio `radius-button`; la pastilla seleccionada en `surface` con `shadow-card` y radio 8px.
- Texto `ink-2`; el seleccionado en `ink`. Estilo `button-text` a 14px.
- También se usa en Ajustes para el descuento mínimo (30 / 50 / 70%).

## Movimiento
- La pastilla se desliza a la opción tocada (muelle 520/34) con un leve apretón vertical al salir (muelle 600/18), y el texto cambia de `ink-2` a `ink` en 200 ms. Con "reducir movimiento", cambia sin desplazarse.

## En la app
- La pastilla se mueve con `withSpring` sobre `translateX`.
- El color del texto cambia con una transición CSS de Reanimated, que no tiene muelle.
- Cada cambio va con háptica `AndroidHaptics.Segment_Tick`.
