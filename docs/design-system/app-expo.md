# Implementación en la app

Cómo llevar este sistema a Expo SDK 58 sin copiar valores a mano.

## Librerías

| Para qué | Paquete | Versión verificada (npm, 1-nov-2026) |
| --- | --- | --- |
| Animación | `react-native-reanimated` | 4.7.1 |
| Íconos | `lucide-react-native` + `react-native-svg` | 1.66.0 / 15.16.0 |
| Listas | `@shopify/flash-list` | 2.3.3 |
| Háptica | `expo-haptics` | 58.0.7 |
| Fuentes | `@expo-google-fonts/big-shoulders-display`, `@expo-google-fonts/hanken-grotesk` | 0.2.3 / 0.4.3 |

Motion y AnimateIcons no corren en React Native: dependen de `react-dom`. Quedan para la web de presentación.

## Tokens

- `tokens.json` es la fuente única. Un script genera `theme.ts` con los colores por tema, espaciado, radios, sombras y estilos de texto; ningún componente escribe un color literal.
- Las sombras de dos capas no existen en React Native: en Android se usa `elevation` (tarjeta 2, flotante 8) más el borde `line`; en iOS, la primera capa de cada sombra.
- El tema sigue al sistema por defecto (`useColorScheme`) y se puede fijar en Ajustes.
- Fuentes: cargar `BigShouldersDisplay_800ExtraBold`, `BigShouldersDisplay_700Bold`, `HankenGrotesk_400Regular`, `HankenGrotesk_500Medium`, `HankenGrotesk_600SemiBold` y `HankenGrotesk_700Bold` con `useFonts`.

## Movimiento

- Los muelles de Movimiento se copian tal cual a `withSpring({ stiffness, damping })`.
- `useReducedMotion()` decide entre la receta y el fundido de 150 ms.
- La lista de ofertas usa FlashList; las animaciones de entrada van solo en ítems nuevos (no en los reciclados).
