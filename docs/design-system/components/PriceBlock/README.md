El precio anterior tachado, el precio final grande y, en el detalle, cuánto ahorras.

## Qué provee quien lo usa
- `originalCents`, `finalCents`, `currency` (ISO 4217) y el `locale` del usuario.
- `variant`: `card` (precio en `price-card`) o `hero` (precio en `price-hero`, con la línea de ahorro).

## Reglas
- Formatea con `Intl.NumberFormat(locale, { style: 'currency', currency })`: "USD 4,99" en Venezuela, "US$ 4,99" en Argentina, "$4.99" en México. El peso colombiano va sin decimales.
- Precio final en `ink`; precio anterior tachado en `ink-3` con `body-sm`; ahorro en `good` ("Ahorras USD 8,75").
- Cifras tabulares siempre.
- Si el precio final es 0: "Gratis" en lugar del número, y la calcomanía dice "−100%".

## Movimiento
- En el detalle, la cifra del ahorro cuenta desde 0 en 800 ms con `[.16, 1, .3, 1]`. Con "reducir movimiento", aparece directo.
