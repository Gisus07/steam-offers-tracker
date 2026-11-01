Botones de la app: primario para la acción principal de cada pantalla, secundario, de texto, de ícono y el de iniciar sesión con Steam.

## Variantes
- **Primario** (`accent` con texto `on-accent`): una vez por pantalla. "Ir a Steam" en el detalle, "Continuar" en el primer uso.
- **Secundario** (`surface-raised`, borde `line`, texto `ink`): acciones que acompañan.
- **De texto** (texto `accent`): Deshacer, Ver todo, Ajustar mis gustos.
- **De ícono** (`size-tap` de área, ícono `ink-2`): Guardar, No me interesa, cerrar.
- **Iniciar sesión con Steam** (`ink` con texto `bg`): solo en bienvenida y en Ajustes. Para el logo de Steam se usa el botón oficial de Valve, sin modificarlo; mientras no esté, va solo texto.

## Reglas
- Alto `size-button`, radio `radius-button`, estilo `button-text`, padding `space-5`. El texto dice lo que hace.
- Deshabilitado: opacidad .45 y sin cambio de color.
- Foco: anillo de 2px en `accent` con 2px de separación.

## Movimiento
- Presionar: escala .97, muelle 600/18. Guardar algo: el botón se transforma a su estado confirmado (muelle 500/32) en lugar de mostrar un toast aparte.
