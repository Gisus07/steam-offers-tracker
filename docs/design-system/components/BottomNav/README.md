Barra de navegación flotante con los cuatro destinos de la app: Para ti, Explorar, Guardados y Ajustes.

## Reglas
- Flota a `space-4` del borde inferior y de los lados, más el inset seguro del sistema. Alto `size-nav`, radio `radius-nav`, fondo `surface`, borde `line`, sombra `shadow-float`.
- Íconos de Lucide a 24px: `sparkles` (Para ti), `search` (Explorar), `bookmark` (Guardados), `settings` (Ajustes), con etiqueta debajo.
- El destino activo lleva la pastilla `accent-soft` y el ícono y la etiqueta en `accent`; los demás en `ink-2`.
- Guardados puede mostrar un punto `good` cuando un juego guardado entra en oferta.

## Movimiento
- La pastilla se desliza al destino tocado: muelle 520/34. La pantalla nueva entra con fundido corto (150 ms); no hay deslizamiento lateral entre pestañas.
