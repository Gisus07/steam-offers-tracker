# Pantallas y comportamiento

Navegación inferior flotante con cuatro destinos: **Para ti**, **Explorar**, **Guardados** y **Ajustes**. Las acciones van a la derecha, al alcance del pulgar. Lo secundario se abre en hojas que suben desde abajo.

## Primer uso

1. **Bienvenida:** una frase ("Te avisamos de ofertas de Steam que te van a gustar, antes de que terminen") y el botón "Iniciar sesión con Steam". Debajo, "Ver ofertas sin cuenta" abre Explorar en modo invitado.
2. **Login con Steam:** se abre el navegador del sistema con la página de Steam; al volver, la app ya tiene la sesión. Si falla: aviso `bad` con "Volver a intentar".
3. **Importar:** "Leyendo tu biblioteca y tu wishlist" con esqueletos de juegos. Si la wishlist es privada, se dice y se sigue sin ella.
4. **Región:** el país precargado desde tu perfil de Steam, con la moneda ("Venezuela · precios en USD"). Se puede cambiar.
5. **Gustos:** chips de tags precargados desde la biblioteca; tocar uno lo suma o lo saca. Mínimo tres.
6. **Avisos:** explica cuántos avisos por día como máximo (5 por defecto) y el horario de silencio, y recién ahí pide el permiso del sistema.

## Para ti (feed)

- Encabezado con `screen-title` "Para ti" y "Actualizado hace 2 h". Un segmentado: **Para ti** · **Terminan pronto**.
- Lista de OfferCard ordenada por afinidad. Una de cada cinco o seis es de exploración y lo dice: "Algo distinto".
- **Tocar la tarjeta:** abre el detalle, que entra desde la tarjeta con escala y fundido (ver Movimiento).
- **Guardar:** ícono `bookmark` en la tarjeta; se rellena y vibra suave.
- **No me interesa:** deslizar a la izquierda o ícono `x`. La tarjeta sale, la lista se cierra y aparece el toast "No te mostraremos más este juego" con Deshacer durante 5 s.
- **Tirar hacia abajo:** actualiza. Si no hay nada nuevo: "Ya estás al día".
- **Vacío:** "Todavía no hay ofertas para ti. Aparecen cuando Steam publica rebajas; te avisamos cuando llegue una que te guste." Salida: "Ajustar mis gustos".

## Detalle de la oferta

- Cápsula grande, calcomanía, `title-lg`, PriceBlock con `price-hero` y la cuenta regresiva absoluta ("Termina el 12 de noviembre, 13:00").
- PriceHistory: precio en los últimos 90 días y el mínimo registrado; si el precio actual es el mínimo, chip `good` "Mínimo registrado".
- Tags, reseñas ("Muy positivas · 92% de 12.408") y, si existe, "Está en tu wishlist de Steam".
- Acción principal: **Ir a Steam** (botón primario, ícono `external-link`), que abre la página del juego en la app de Steam o en el navegador. Secundarias: Guardar y No me interesa.

## Explorar

- Buscador por nombre arriba (campo con `radius-field`) y chips de filtro: % mínimo, precio máximo, termina hoy, tags. El filtro activo se invierte a `ink`.
- Misma tarjeta que el feed, ordenada por descuento o por fecha de fin.
- Es la pantalla del modo invitado: funciona sin cuenta.

## Guardados

- Juegos guardados con su estado: en oferta (con calcomanía y cuenta regresiva) o sin oferta ("Sin descuento ahora · te avisamos cuando baje").
- Deslizar para quitar, con Deshacer.

## Ajustes

- Región y moneda, descuento mínimo (segmentado 30 / 50 / 70%), precio máximo, excluir contenido para adultos (activado por defecto), avisos por día, horario de silencio, tema (sistema, oscuro, claro), cuenta de Steam vinculada, cerrar sesión y **eliminar cuenta** (borra todo, con confirmación escrita).

## Notificación

- Título: el juego. Texto: "−85% · USD 0,89 · termina en 2 d". Tocarla abre el detalle.
- Agrupadas si llegan varias del mismo barrido: "3 ofertas para ti".
- Nunca más del tope diario ni dentro del horario de silencio; lo que cae ahí se manda al terminar el silencio.
