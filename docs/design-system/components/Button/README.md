Botones de la app: primario para la acción principal de cada pantalla, secundario, de texto, de ícono y el de iniciar sesión con Steam.

## Forma: estilo control
Todo botón que hace algo tiene la misma forma, como los botones de un control.
- **Silueta:** cápsula (radio completo); los de ícono son círculos.
- **Canto:** debajo de la cara va una franja de 4px de un tono más oscuro (`accent-lip`, `raised-lip` o `ink-lip`, según la variante).
- **Al presionar:** la cara baja 4px y el canto desaparece. Al soltar, vuelve con un muelle.
- **Sin canto:**
  - El botón de texto no lo lleva, porque es texto y no una pieza.
  - La barra de navegación, los chips y el segmentado tampoco, porque eligen y no hacen.

## Variantes
- **Primario** (`accent` con texto `on-accent`, canto `accent-lip`): una vez por pantalla. "Ir a Steam" en el detalle, "Continuar" en el primer uso, "Deshacer" en el aviso.
- **Secundario** (`surface-raised`, borde `line`, texto `ink`, canto `raised-lip`): acciones que acompañan, como "No me interesa".
- **De texto** (texto `accent`; al presionar, fondo `accent-soft`): Saltar, Ver ofertas sin cuenta.
- **De ícono** (círculo de 44px, `surface-raised`, borde `line`, ícono `ink-2`, canto `raised-lip`): Guardar, No me interesa, volver. Guardado: fondo `good-soft` e ícono `good` relleno.
- **Iniciar sesión con Steam** (`ink` con texto `bg`, canto `ink-lip`): solo en bienvenida y en Ajustes. Para el logo de Steam se usa el botón oficial de Valve, sin modificarlo; mientras no esté, va solo texto.

## Reglas
- Alto `size-button` (52px) el principal y `size-tap` (44px) el compacto y los de ícono.
- Estilo `button-text`, con padding horizontal de 24px (18px en el compacto).
- El canto no ocupa lugar en el layout: deja 4px libres debajo de cada botón.
- El texto dice lo que hace.
- Deshabilitado: opacidad .45, sin cambio de color, y no se hunde.
- Foco: anillo de 2px en `accent` con 2px de separación.

## Movimiento
- **Presionar:** la cara baja 4px en 120 ms y el canto se achica a 0. Al soltar, vuelve con muelle 500/26 (ver Movimiento).
- **Háptica:** `AndroidHaptics.Virtual_Key` al hundir y `Virtual_Key_Release` al soltar.
- **Guardar:** el botón de ícono se aplasta, estalla y manda una copia a Guardados (ver OfferCard y Movimiento). No hay aviso aparte.

## En la app
- El canto es una View debajo de la cara, no una sombra: React Native no tiene sombras sólidas desplazadas. La cara se mueve con `translateY` y el canto cambia de alto.
- En la web y en los previews, el canto es un `box-shadow` sólido y el hundido va en CSS.
