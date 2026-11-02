Aviso breve que ofrece deshacer una acción o informa un error. Sale de la barra de navegación: no flota aparte ni empuja el contenido.

## Cómo se ve
- La cápsula de la barra crece hacia arriba y a lo ancho: pasa de 232×64 a 358×124px y su radio, de 32 a 28px.
- Encima de los íconos muestra una fila con ícono, frase y una acción. Los íconos siguen visibles y funcionan mientras dura el aviso.
- **Deshacer:**
  - ícono `eye-off` en `ink-2`;
  - "No te mostraremos más este juego";
  - **Deshacer**, como botón primario compacto, con su canto (ver Button).
- **Error:**
  - ícono `circle-alert` en `bad`;
  - qué pasó, por ejemplo "No pudimos actualizar las ofertas";
  - **Reintentar**.
- **Sin barra (primer uso):** el error va en línea, junto a la acción que falló.

## Reglas
- Uno a la vez: el nuevo reemplaza al anterior.
- Dura 5 s y no muestra cuánto queda.
- Guardar no muestra aviso: una copia del ícono vuela a Guardados y Guardados late.
- La frase ocupa una o dos líneas, a 13px y peso 600. La acción dice lo que hace.

## Movimiento
- **Abrir:** ancho, alto y radio con muelle 340/28. La fila del mensaje entra con un fundido de 260 ms que empieza a los 200 ms, cuando ya hay espacio.
- **Cerrar:** orden inverso. Primero se va el mensaje (180 ms) y, 100 ms después, la cápsula vuelve a su tamaño con el mismo muelle.
- **Con "reducir movimiento":** la cápsula cambia de tamaño en 150 ms, sin muelle, y el mensaje solo aparece.

## En la app
- Es un componente propio dentro de la barra, no una librería de toasts.
- El estado vive en un store de Zustand y la forma se anima con Reanimated (ver Implementación en la app).
