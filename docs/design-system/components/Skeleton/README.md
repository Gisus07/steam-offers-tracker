Esqueleto de carga con la forma exacta del contenido que va a aparecer; reemplaza a cualquier spinner.

## Reglas
- Bloques `surface-raised` con el radio del elemento real; mientras se espera, un brillo de 1,6 s en bucle con `line`.
- Copia la forma de la OfferCard: imagen, calcomanía, dos líneas de nombre, chips y precio. La lista muestra tres.
- Cuando llega el contenido no hay corte seco: el brillo va formando la tarjeta.
  - Un último brillo cruza cada tarjeta en 900 ms, a ritmo constante.
  - Cada bloque toma el tamaño de su pieza cuando el centro del brillo pasa por él (muelle 260/26) y se cruza con la pieza real en 220 ms.
  - Solo en la primera página; las filas recicladas no se animan.
- Con "reducir movimiento", el brillo se apaga y quedan los bloques quietos; el cambio a contenido es un fundido simple.
- Si la carga falla, el esqueleto se reemplaza por el aviso de error en la barra. Nunca queda girando.
