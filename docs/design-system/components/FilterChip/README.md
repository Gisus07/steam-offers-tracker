Chip de filtro en Explorar: se activa y desactiva, y puede mostrar cuántas ofertas deja.

## Qué provee quien lo usa
- La etiqueta ("50% o más", "Termina hoy", "Menos de USD 5"), el estado (`aria-pressed`) y, opcional, el conteo.

## Reglas
- Inactivo: fondo `surface`, borde `line-strong`, texto `ink`. Activo: **se invierte a `ink`** con texto `bg`. Nunca se pinta de `accent`.
- Alto `size-chip`, radio `radius-pill`. El conteo va en una pastilla chica con cifras tabulares.
- En fila con scroll horizontal; el primero siempre es "Todos".

## Movimiento
- Al filtrar, las tarjetas que salen se achican a .85 con fundido y las que quedan se reacomodan (muelle 420/32). Con "reducir movimiento", solo fundido.
