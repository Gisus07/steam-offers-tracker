Barra de navegación flotante con los cuatro destinos de la app: Para ti, Explorar, Guardados y Ajustes. Lleva solo íconos.

## Reglas
- **Forma y posición:**
  - Cápsula centrada de 232×64px, a `space-4` del borde inferior más el inset seguro del sistema.
  - Fondo `surface`, borde `line`, sombra `shadow-float`.
  - No ocupa todo el ancho: deja ver el contenido a los lados.
- **Íconos:** Lucide a 24px, en áreas de 52px: `sparkles` (Para ti), `search` (Explorar), `bookmark` (Guardados) y `settings` (Ajustes). Sin etiquetas visibles.
- **Destino activo:** círculo `ink` detrás y el ícono en `bg`, igual que el filtro activo. Los demás van en `ink-2`. No se pinta de `accent`, porque el acento es para tocar, no para estado.
- **Accesibilidad:** cada destino tiene nombre accesible ("Para ti", "Explorar"…) y lo muestra al mantenerlo presionado.
- **Punto en Guardados:** puede mostrar un punto `good` cuando un juego guardado entra en oferta.
- **Aviso:** la barra también es donde aparece el aviso (ver Toast).

## Movimiento
- El círculo se desliza al destino tocado con un muelle 520/34.
- La pantalla nueva entra con un fundido corto (150 ms). No hay deslizamiento lateral entre pestañas.
- Al guardar un juego, el ícono de Guardados late una vez: escala 1,3 en 150 ms y vuelve con un muelle con rebote. Así señala dónde quedó.
- Con un aviso, la cápsula crece (ver Toast).
