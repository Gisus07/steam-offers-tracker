Chip que dice cuánto falta para que termine la oferta, y se vuelve urgente en las últimas 24 horas.

## Qué provee quien lo usa
- `endsAt` (fecha de fin de la oferta, de `discount_end_at`) y la zona horaria del usuario.

## Reglas
- Más de 24 h: fondo `surface-raised`, texto `ink-2`, "Termina en 2 d 4 h".
- Menos de 24 h: fondo `hot-soft`, texto `hot`, "Termina hoy, 18:00" o "Termina mañana, 9:00".
- Siempre con el ícono `clock` de Lucide a 14px: el color nunca es la única señal.
- Sin fecha de fin conocida, no se muestra el chip.
- Estilo `caption` con cifras tabulares.

## Movimiento
- No corre segundo a segundo: se recalcula una vez por minuto, sin animación.
