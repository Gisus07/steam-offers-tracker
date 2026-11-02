Botones de la app: primario para la acción principal de cada pantalla, secundario, de texto, de ícono y el de iniciar sesión con Steam.

## Forma en evaluación
Se elige una de las dos. El tablero "Forma: cápsula o relieve" del canvas de bocetos las muestra lado a lado, y se pueden presionar.
- **A · Cápsula (recomendada):** radio completo (la mitad del alto).
  - Al presionar se aplana: el radio baja a 16px (14px en los de ícono) y escala .97 (.9 en los de ícono), con el muelle 600/18.
  - Comparte silueta con los chips, el segmentado y la barra.
- **B · Relieve:** radio 14px, borde de 1,5px en `line-strong` y un canto de 4px debajo (3px en los de ícono).
  - Al presionar baja 4px y el canto desaparece, en 110 ms.
  - Necesita un token de canto por variante.
- Al elegir se actualizan `radius-button` y `size-button` (52px el principal).

## Variantes
- **Primario** (`accent` con texto `on-accent`): una vez por pantalla. "Ir a Steam" en el detalle, "Continuar" en el primer uso.
- **Secundario** (`surface-raised`, borde `line`, texto `ink`): acciones que acompañan, como "No me interesa".
- **De texto** (texto `accent`; al presionar, fondo `accent-soft`): Saltar, Deshacer, Ver ofertas sin cuenta.
- **De ícono** (44px, fondo `surface-raised`, ícono `ink-2`): Guardar, No me interesa, volver. Guardado: fondo `good-soft` e ícono `good` relleno.
- **Iniciar sesión con Steam** (`ink` con texto `bg`): solo en bienvenida y en Ajustes. Para el logo de Steam se usa el botón oficial de Valve, sin modificarlo; mientras no esté, va solo texto.

## Reglas
- Alto de 52px el principal y de 44px el compacto.
- Estilo `button-text`, con padding horizontal de 24px (18px en el compacto).
- El texto dice lo que hace.
- Deshabilitado: opacidad .45 y sin cambio de color.
- Foco: anillo de 2px en `accent` con 2px de separación.

## Movimiento
- Presionar: según la forma (arriba).
- Guardar algo: el botón pasa a su estado confirmado (muelle 500/32) en lugar de mostrar un aviso aparte.
