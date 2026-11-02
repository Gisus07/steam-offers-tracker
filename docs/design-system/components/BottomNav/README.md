Barra de navegación flotante con los cuatro destinos de la app: Para ti, Explorar, Guardados y Ajustes. Lleva solo íconos.

## Reglas
- **Forma y posición:**
  - Cápsula centrada de 232×64px, a `space-4` del borde inferior más el inset seguro del sistema.
  - Fondo `surface`, borde `line`, sombra `shadow-float`.
  - No ocupa todo el ancho: deja ver el contenido a los lados.
  - No lleva canto: elige destino, no hace una acción (ver Button).
- **Íconos:** Lucide a 24px, en áreas de 52px: `sparkles` (Para ti), `search` (Explorar), `bookmark` (Guardados) y `settings` (Ajustes). Sin etiquetas visibles.
- **Destino activo:**
  - Círculo `ink` detrás y el ícono relleno en `bg`, igual que el filtro activo. Los demás van en contorno y `ink-2`.
  - No se pinta de `accent`, porque el acento es para tocar, no para estado.
- **Accesibilidad:** cada destino tiene nombre accesible ("Para ti", "Explorar"…) y lo muestra al mantenerlo presionado.
- **Punto en Guardados:** puede mostrar un punto `good` cuando un juego guardado entra en oferta.
- **Aviso:** la barra también es donde aparece el aviso (ver Toast).

## Movimiento
- **Cambiar de destino:**
  - El círculo es elástico. El borde que avanza tira con muelle 520/36 y el otro lo sigue 150 ms después con 340/28.
  - A los 300 ms, el ícono de destino se rellena, se encoge a .8 en 120 ms y rebota con muelle 380/16.
- La pantalla nueva entra con un fundido corto (150 ms). No hay deslizamiento lateral entre pestañas.
- **Al guardar un juego:** llega volando una copia del ícono desde la tarjeta. Guardados se rellena un momento, late (1,3 en 180 ms y vuelve con muelle 380/14) y suelta 5 puntos `good`. Así señala dónde quedó.
- **Con un aviso:** la cápsula crece (ver Toast).
