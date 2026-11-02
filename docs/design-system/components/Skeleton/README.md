Esqueleto de carga con la forma exacta del contenido que va a aparecer; reemplaza a cualquier spinner.

## Reglas
- Bloques `surface-raised` con el radio del elemento real; brillo de 1,6 s en bucle con `line`.
- Copia la forma de la OfferCard: imagen, calcomanía, dos líneas de nombre, chips y precio. La lista muestra tres.
- Cuando llega el contenido, no hay corte seco: el esqueleto se desvanece en 220 ms mientras las tarjetas entran con un fundido y 12px de subida, escalonadas 70 ms.
- Con "reducir movimiento", el brillo se apaga y quedan los bloques quietos; el cambio a contenido es un fundido simple.
- Si la carga falla, el esqueleto se reemplaza por el aviso de error en la barra. Nunca queda girando.
