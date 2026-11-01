Gráfico chico del precio en los últimos 90 días, con el mínimo registrado marcado.

## Qué provee quien lo usa
- Los intervalos de `price_history` del juego en el país del usuario (desde, hasta, precio final) y el precio actual.

## Reglas
- Línea escalonada en `ink-2` sobre área `surface-raised`; grilla en `line`; el punto del mínimo en `good` y el del precio actual en `accent`.
- Debajo, en texto: "Mínimo registrado: USD 0,52, el 3 de octubre". Si el precio actual es el mínimo, chip `good` "Mínimo registrado" con el ícono `trending-down`.
- Solo afirma lo registrado: "registrado desde que seguimos este juego", nunca "el más bajo de la historia".
- Con menos de dos cambios de precio, se muestra solo el texto, sin gráfico.
- Etiquetas de los ejes en `ink-3`, estilo `caption`.

## En la app
- Primera opción: TanStack Charts con su adaptador de React Native, que es experimental. Se dibuja con `lineY` y la curva `curveStepAfter` de d3-shape. La documentación muestra otra curva, así que la escalonada falta probarla.
- Si el adaptador falla en Android: `react-native-wagmi-charts`, con `shape` en `curveStepAfter` y `LineChart.HorizontalLine` para marcar el mínimo.
