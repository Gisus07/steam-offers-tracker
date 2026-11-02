Chip de filtro en Explorar: se activa y desactiva, y puede mostrar cuántas ofertas deja.

## Qué provee quien lo usa
- La etiqueta ("50% o más", "Termina hoy", "Menos de USD 5"), el estado (`aria-pressed`) y, opcional, el conteo.

## Reglas
- Inactivo: fondo `surface`, borde `line-strong`, texto `ink`. Activo: **se invierte a `ink`** con texto `bg` y un check de 14px delante de la etiqueta. Nunca se pinta de `accent`.
- Alto `size-chip`, radio `radius-pill`. El conteo va en una pastilla chica con cifras tabulares.
- No lleva canto: elige, no hace (ver Button).
- En fila con scroll horizontal; el primero siempre es "Todos".

## Movimiento
- **Al activarlo:** el chip se invierte en 280 ms, crece para el check (muelle 400/30) y rebota (1,08 en 140 ms, vuelve con muelle 380/14).
- **La lista:** a los 120 ms se reacomoda. Las tarjetas que salen se van en 240 ms con fundido y escala .96, y las que quedan se corren con muelle 320/30.
- **Con "reducir movimiento":** solo fundido.
