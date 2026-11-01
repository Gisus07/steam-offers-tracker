# Implementación en la app

Cómo llevar este sistema a Expo SDK 58 sin copiar valores a mano. Qué librería se usa y por qué está en Librerías.

## Instalación

- Todo se instala con `npx expo install`, que respeta las versiones que fija el SDK (React 19.3.0, React Native 0.88.1). `npx expo install --fix` corrige las que se desvíen.
- Development build desde el primer día: Unistyles y MMKV no corren en Expo Go.
- React Compiler activado (`experiments.reactCompiler`, que ya viene en la plantilla del SDK 58). Memoiza solo, así que `useMemo` y `useCallback` a mano dejan de hacer falta en casi todos los casos.
- Motion y AnimateIcons no corren en React Native, porque dependen de `react-dom`. Quedan para la web de presentación.

## Tokens y tema

- `tokens.json` es la fuente única. Un script genera `theme.ts` con los colores de cada tema, el espaciado, los radios, las sombras y los estilos de texto. Ningún componente escribe un color literal.
- Unistyles registra los dos temas con `StyleSheet.configure({ themes: { dark, light }, settings: { adaptiveThemes: true } })` y sigue al sistema. Si la persona fija el tema en Ajustes, se llama a `UnistylesRuntime.setAdaptiveThemes(false)` y luego a `UnistylesRuntime.setTheme('light')`.
- Las sombras de dos capas no existen en React Native. En Android se usa `elevation` (tarjeta 2, flotante 8) más el borde `line`; en iOS, la primera capa de cada sombra.
- Las fuentes se cargan con `useFonts`: `BigShouldersDisplay_800ExtraBold`, `BigShouldersDisplay_700Bold`, `HankenGrotesk_400Regular`, `HankenGrotesk_500Medium`, `HankenGrotesk_600SemiBold` y `HankenGrotesk_700Bold`.

## Movimiento

- Los muelles de Movimiento se copian tal cual a `withSpring({ stiffness, damping })`.
- Los bucles y los cambios de color van con la API CSS de Reanimated, que corre en el hilo de UI sin estado de React:
  - el brillo del esqueleto, con `animationName` y `animationIterationCount: 'infinite'`;
  - el color del texto del segmentado, con `transitionProperty` y `transitionDuration`.
- La API CSS no tiene muelles: lo que lleva muelle sigue con `withSpring`.
- `useReducedMotion()` decide entre la receta y el fundido de 150 ms.
- No hay transiciones de elemento compartido. En Reanimated 4.7.1 siguen detrás de un flag y su doc no las recomienda para producción. Tarjeta → detalle usa la entrada con escala (ver Movimiento).

## Datos y sin conexión

- **Red y foco:**
  - `onlineManager.setEventListener` con `addNetworkStateListener` de `expo-network`;
  - `focusManager` con `AppState`.
  
  Sin esto, Query no sabe que el teléfono perdió la red ni que la app volvió al frente.
- **Persistencia:**
  - `PersistQueryClientProvider` con `createAsyncStoragePersister` sobre MMKV. MMKV se crea con `createMMKV`, y un adaptador traduce `getItem`, `setItem` y `removeItem` a `getString`, `set` y `remove`.
  - El cliente entero va en una sola clave, así que `shouldDehydrateQuery` deja pasar solo el feed, Guardados y los ajustes.
  - `gcTime` igual o mayor que `maxAge` (24 h), y la versión de la app como `buster`.
  
  Al abrir, el feed guardado aparece antes de que responda la red.
- **Feed:**
  - `useInfiniteQuery` con el cursor de `feed_for_user` (puntaje y appid del último ítem).
  - `maxPages`, para no acumular páginas.
  - FlashList pide la página siguiente en `onEndReached`.
- **Guardar y descartar:**
  - Optimistas en `onMutate`, con rollback en `onError`.
  - `setMutationDefaults` con la misma `mutationKey` que usa el hook, para que sobrevivan a un reinicio.
  - `resumePausedMutations()` al restaurar el caché.
  - `scope: { id: 'feedback' }`, para que se envíen en orden.
- **Eventos (vistas, tiempo de lectura):**
  - Van fuera de Query, a una cola propia en `expo-sqlite`.
  - La cola se vacía por lotes al pasar a segundo plano y al recuperar la red.
  - Cada evento lleva un UUID (`Crypto.randomUUID()` de `expo-crypto`), y el servidor ignora los reintentos con `on conflict do nothing` (probado en Postgres 18).

## Imágenes y listas

- `expo-image` dentro de FlashList se configura así:
  - `cachePolicy="memory-disk"`.
  - `recyclingKey` con el appid. Así, al reciclar una celda no aparece la imagen anterior.
  - `transition={{ duration: 150, skipOnCacheHit: true }}`. Así, lo cacheado aparece sin fundido.
- `Image.prefetch` precarga las imágenes de la página siguiente del feed y la cápsula grande al abrir el detalle.
- Mientras la imagen carga, rige la regla de Imágenes: `surface-raised` con el nombre del juego.
- FlashList se usa en Para ti, Explorar y Guardados. Las animaciones de entrada van solo en ítems nuevos, no en los reciclados.

## Toasts

- `sonner-native` monta un solo `<Toaster>` en la raíz, con esta configuración:
  - `visibleToasts={1}`, para que haya uno a la vez.
  - `duration={5000}`.
  - `position` según la variante elegida: `bottom-center` para A y C, `top-center` para B.
- La variante se dibuja con `toast.custom()` o con `unstyled` y `styles` desde el tema. No queda a la vista ningún estilo propio de sonner.
- Deshacer manda el evento inverso (`undismiss` o `unsave`) y cierra el toast.

## Navegación y hojas

- `expo-router` con la barra flotante propia sobre `expo-router/ui` (`TabList`, `TabTrigger`, `TabSlot`). Las NativeTabs del SDK 58 son estables, pero en Android usan la barra Material y no permiten una barra flotante.
- Los filtros de Explorar van en una hoja nativa (`presentation: 'formSheet'`). En Android admite hasta tres alturas.

## Avisos y háptica

- Los avisos usan `expo-notifications`, con el push enviado por el servidor a través de Expo Push.
- La imagen grande va en el push (`richContent.image`), y Android la muestra sin código extra.
- Las acciones Guardar y No me interesa se crean con `setNotificationCategoryAsync` y `opensAppToForeground: false`. En Android, `registerTaskAsync` recibe el toque aunque la app esté cerrada.
- La háptica va con `Haptics.performAndroidHapticsAsync`:
  - `AndroidHaptics.Confirm` al guardar;
  - `AndroidHaptics.Reject` al descartar;
  - `AndroidHaptics.Segment_Tick` al cambiar el segmentado.
