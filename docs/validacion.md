# Validación del problema — Steam Offers Tracker v2

Fecha: 2026-11-01.
Objetivo: saber si otras personas tienen el problema y si usarían la app **antes** de diseñar el modelo de negocio y la pasarela de pago. Si la respuesta es no, la app queda como herramienta personal y proyecto de portafolio.

Leyenda: **[verificado]** = visto en la fuente primaria. **[fuente secundaria]** = artículos o reseñas de terceros. **[no verificado]** = falta comprobar. **[criterio propio]** = umbral elegido por juicio, ajustable antes de empezar.

---

## 1. Qué hay que validar

Cuatro hipótesis, de la primera que se prueba a la última. Si una falla, las siguientes no importan.

| # | Hipótesis | Cómo se prueba |
|---|---|---|
| H1 | **Problema:** quienes compran en Steam se enteran tarde, o no se enteran, de ofertas de juegos que les interesan y que no tienen en la wishlist. | Entrevistas + encuesta |
| H2 | **Solución:** avisos personalizados en el teléfono les sirven más que lo que usan hoy. | Reacción al final de la entrevista + piloto |
| H3 | **Uso sostenido:** la siguen usando después de la novedad. | Piloto de 4 semanas |
| H4 | **Pago:** alguien pagaría, con las trabas de pago de la región. | Compromisos en el piloto; se diseña recién si H1–H3 pasan |

---

## 2. Mercado

### 2.1 Lo que ya hace Steam [verificado en la documentación de Steamworks y en el anuncio de Valve]

- **Wishlist:** Steam avisa por email o push cuando un juego de tu wishlist baja **20 % o más**. El descuento tiene que tocar el paquete más barato y durar más de 8 horas. Hay un enfriamiento de 2 semanas por juego, más largo en las grandes rebajas.
- **Fuera de la wishlist:** Steam ya muestra ofertas recomendadas para cada usuario, pero **solo dentro de la tienda**. No encontré push ni email de ofertas por gusto fuera de la wishlist [fuente secundaria].
- **Lo que viene:** el 29-sep-2026 Valve anunció que **a principios de 2027** reemplaza el calendario curado de "Discounts & Events" por un sistema **dinámico y personalizado para cada cliente**. Ya pausó las Daily, Midweek y Weekend Deals. En sus pruebas mostró 10 veces más juegos por día y subieron las visitas, las wishlists y los carritos.

### 2.2 Competidores y sustitutos

| Nombre | Tipo | Personaliza fuera de la wishlist | Push / alertas | Precio regional | Cómo se financia | Señal de demanda |
|---|---|---|---|---|---|---|
| Steam | Tienda + app oficial | Parcial: solo dentro de la tienda | Email/push solo de wishlist | Nativo; Venezuela usa el nivel USD_LATAM | Venta de juegos | App Android 100M+ instalaciones |
| IsThereAnyDeal | Web + API | No | Email de la Waitlist, webhooks | Por país | Afiliados + Patreon | Grupo de Steam: 15,8K |
| Augmented Steam | Extensión | No | No | Vía ITAD | Afiliados | Chrome: 400K usuarios |
| GG.deals | Web + extensión | No | Email y push de navegador [fuente secundaria] | 19 regiones | Afiliados; premium "planeado" [fuente secundaria] | Grupo de Steam: 38,9K |
| SteamDB | Web + extensión | No | No consta | Todas las monedas | GitHub Sponsors | Chrome: 700K usuarios |
| GameTrack | App Android/iOS | Parcial: "match score" y ofertas ordenadas por interés | Alertas de precio solo en el plan pago | Sin confirmar | Suscripción (GameTrack+) | Android 10K+; iOS 1251 valoraciones |
| Sales for Gaming | App Android | No | No, solo lista | Sí | Anuncios | 100K+ |
| Bestgameprice | App Android | No | Alertas de precio | No deja cambiar moneda (queja) | — | 100K+, sin actualizar desde oct-2024 |
| GET – Steam & Epic Alert | App Android | No | Push de gratis y descuentos | Sin confirmar | Gratis | 50K+, sin actualizar desde jul-2025 |
| Steamly | Bot de Discord | Parcial: puntúa tu wishlist según tus horas jugadas | DM o canal | Sí | Gratis | 7 servidores |
| r/GameDeals, r/Steam | Reddit | No | No | No | — | 975K / 5,4M miembros [fuente secundaria] |
| Canales de Telegram en español | Difusión | No | Difusión | Euros (son de España) | Afiliados de Amazon | 2K–21K suscriptores |

Datos [verificado] en las fichas de Google Play, Chrome Web Store, grupos de Steam y canales de Telegram, salvo donde dice lo contrario. Hay más apps chicas (SaleStash, ST Deals, GameDeal, G Dealz) con 10 a 10K instalaciones. Las apps de juegos gratis tienen más tracción que las de ofertas: Epic Freebie Games Radar, 5M+.

### 2.3 Lo que se repite en las reseñas

Indicativo: Google Play muestra pocas reseñas por ficha.

1. **No se puede ocultar lo que ya tenés ni marcar "no me interesa".** Es la queja más repetida.
2. **Notificaciones que no se pueden configurar** (umbral de %, tipo de aviso) **o que nunca llegan.** En el foro de Steam piden lo mismo para la wishlist, porque el ruido hace que la gente apague los avisos.
3. **Apps que solo listan, sin alertas.**
4. **Catálogo vacío o incompleto, sin actualización automática.**
5. **Región y moneda:** apps que no dejan cambiar la moneda o no tienen precios de la región del usuario.

### 2.4 Huecos y riesgos

- **Push de ofertas por gusto, fuera de la wishlist: el hueco existe pero es angosto.** Los que se acercan son parciales (GameTrack cobra las alertas; Steamly casi no tiene usuarios).
- **El mayor riesgo es Valve.** Tiene los datos, acaba de comprobar que personalizar ofertas funciona (10 veces más juegos vistos) y podría sumar "ofertas recomendadas" a sus notificaciones cuando quiera. La propuesta no puede depender solo de "te aviso fuera de la wishlist".
- **Aprender de lo que descartás** (ocultar, "no me interesa", tiempo de vista) responde a la queja más repetida, y no vi a nadie que diga hacerlo [no verificado].
- **LatAm:** no encontré canales ni bots de ofertas de Steam pensados para LatAm. Lo grande en español es de España, en euros.
- **La fecha de fin no diferencia:** ya la muestran Steamly, ST Deals y GameTrack.

### 2.5 Cómo se financian y qué dice eso del pago

- **Afiliados:** ITAD, GG.deals y los canales de Telegram. **Steam no tiene un programa de afiliados público** [fuente secundaria]: si la app solo enlaza a Steam, no cobra comisión.
- **Donaciones:** ITAD (Patreon), SteamDB (GitHub Sponsors).
- **Anuncios:** casi todas las apps chicas.
- **Suscripción o compras en la app:** GameTrack+ cobra las alertas; otras apps chicas venden de 0,99 a 16,99 USD.
- **Evidencia de que la gente paga solo por alertas de ofertas: débil.** Ninguno publica ingresos y hay alternativas gratis sin anuncios. Por eso H4 es la hipótesis más riesgosa, y se prueba al final.

### 2.6 Qué cambia en la validación

- En las entrevistas, además del "me enteré tarde", hay que explorar el **ruido**: qué hacen con los avisos que les llegan hoy y cuáles ignoran. Puede que el dolor real sea la relevancia y no la cobertura.
- Preguntar si usan las notificaciones de la app de Steam: si ya les alcanzan, el problema es menor.
- Reclutar en comunidades de LatAm, donde no hay un competidor fuerte.

---

## 3. Entrevistas: cómo hacerlas por primera vez

### 3.1 Las cinco reglas

Basadas en *The Mom Test* (Rob Fitzpatrick), el libro de referencia para esto:

1. **Hablá de su vida, no de tu idea.** La idea se menciona recién al final, si se menciona.
2. **Preguntá por hechos pasados y concretos**, no por hipótesis. "¿Cuándo fue la última vez que…?" sirve; "¿usarías…?" no, porque la gente responde lo que cree que querés escuchar.
3. **Escuchá más de lo que hablás.** Si hablás más del 20 % del tiempo, estás vendiendo.
4. **Desconfiá de los cumplidos.** "Qué buena idea" no es un dato. Un caso concreto ("la semana pasada me perdí X") sí lo es.
5. **Buscá compromisos, no opiniones.** Que se anote al piloto o te presente a otra persona vale más que "lo pagaría".

Errores típicos de la primera vez:
- Presentar la idea al principio: todo lo que sigue queda contaminado.
- Preguntas que inducen la respuesta: "¿no te molesta perderte ofertas?".
- Preguntar "¿pagarías?": la respuesta casi nunca coincide con lo que la persona hace después.
- Entrevistar solo a amigos cercanos: te quieren y van a ser amables. Sumá amigos de amigos y desconocidos de comunidades.

### 3.2 A quién y cuántos

- **Cuántos:** 6 a 8 entrevistas. Con 5 o 6 ya suelen repetirse los patrones.
- **Quiénes:** personas que compraron al menos un juego en Steam en los últimos 6 meses. Mezclá perfiles: quien compra seguido y quien compra poco, quien usa la wishlist y quien no.
- **Dónde encontrarlas:** compañeros de la universidad, amigos de amigos y comunidades de jugadores en español (sección 2).

Mensaje de invitación listo para copiar:

> Hola, estoy investigando cómo la gente compra juegos en Steam y cómo se entera de las ofertas. ¿Me regalás 20 minutos para una charla por llamada esta semana? No te voy a vender nada; solo quiero escuchar cómo lo hacés vos.

### 3.3 Logística

- 20 a 25 minutos, por videollamada o en persona.
- Pedí permiso para grabar o tomar notas. Si no quiere, solo notas.
- Completá las notas apenas termina (plantilla en 3.5): en una hora ya se olvida la mitad.
- Guardá las notas con un alias, no con el nombre.

### 3.4 Guion (25 min)

**Apertura (2 min)**
- "Gracias por el tiempo. Estoy investigando cómo la gente compra juegos en Steam y cómo se entera de las ofertas. No hay respuestas correctas y no te voy a vender nada. ¿Te molesta si tomo notas?"

**Contexto (6 min)**
- "¿Qué estás jugando últimamente?"
- "¿Cuál fue el último juego que compraste en Steam? Contame cómo fue: cómo lo encontraste, cuándo lo compraste, si estaba en oferta."
- "¿Cada cuánto comprás juegos? ¿Esperás ofertas o comprás cuando sale?"

**Profundización (10 min)**
- "¿Cómo te enterás hoy de las ofertas?" Seguí el hilo: "¿Y eso cada cuánto lo hacés?"
- "¿Te pasó enterarte de una oferta cuando ya había terminado? Contame la última vez: qué juego, cómo te enteraste, qué hiciste después."
  - Si no le pasó, no lo fuerces: anotalo como "sin problema". Ese dato vale tanto como el contrario.
- "¿Ese juego lo tenías en la wishlist? ¿Cómo usás la wishlist?"
- "¿Te llegan avisos de ofertas hoy, de Steam o de otro lado? ¿Qué hacés con ellos? Contame el último que ignoraste."
- "¿Tenés la app de Steam en el teléfono? ¿Con las notificaciones activadas?"
- "¿Probaste alguna página, canal o app para no perderte ofertas? ¿Por qué la seguís usando, o por qué la dejaste?"
- "¿Cuánto te importó perderte esa oferta? ¿Lo compraste igual más caro, esperaste a otra o lo dejaste?"

**Reacción (5 min, recién ahora)**
- Describí la idea en una sola frase: "Una app que te avisa en el teléfono cuando un juego parecido a los que te gustan está en oferta en tu región, aunque no esté en tu wishlist."
- "¿Qué te parece? ¿Qué tendría que tener para que la uses? ¿Qué te molestaría?"
- Mirá la diferencia entre cortesía ("está buena") y detalle concreto ("si me avisa de roguelikes de menos de 5 dólares, la uso").

**Cierre (2 min)**
- "¿Te puedo avisar cuando haya una versión de prueba?" (compromiso de tiempo)
- "¿Conocés a alguien a quien le pase esto y que pueda hablar conmigo?" (compromiso de reputación)
- "Gracias."

### 3.5 Plantilla de notas (una por entrevista)

```
Alias / fecha:
Perfil: país de la cuenta | compras por mes | usa wishlist (sí/no/abandonada)

Cómo se entera hoy de las ofertas:
Cada cuánto compra; espera ofertas o no:

¿Caso concreto reciente de oferta perdida o tardía? (sí/no)
  Qué juego, cuándo, cómo se enteró:
  ¿Estaba en la wishlist?:
  Qué hizo después:
  Cita textual:

Herramientas que probó y por qué las usa o las dejó:
Intensidad del problema (1 = le da igual, 3 = le molestó y actuó):

Reacción a la idea (frases textuales):
Qué pidió / qué le molestaría:

Compromisos: ¿se anotó al piloto? ¿te presentó a alguien?
Sorpresas:
```

### 3.6 Síntesis

1. Después de cada entrevista: 10 minutos para completar la plantilla.
2. Con 5 o más entrevistas, **mapa de afinidad**: una fila por observación en una planilla, y una columna "tema" que vas llenando al agrupar las parecidas.
3. Contá:
   - cuántas personas contaron un caso concreto reciente (H1);
   - qué usan hoy y qué les falta;
   - cuántas se anotaron al piloto o te presentaron a alguien.
4. Escribí de 3 a 5 hallazgos y una frase de *jobs to be done*: "Cuando ___, quiero ___, para ___."

---

## 4. Encuesta (complemento)

Sirve para sumar volumen, no para reemplazar las entrevistas. Con menos de ~30 respuestas es solo exploratoria; para cuantificar con confianza hacen falta 100 o más.

Preguntas listas para Google Forms:

1. **(Filtro)** ¿Compraste algún juego en Steam en los últimos 6 meses? — Sí / No (si es No, termina la encuesta)
2. ¿En qué país está tu cuenta de Steam? — Respuesta corta
3. ¿Cuántos juegos compraste en Steam en los últimos 6 meses? — 1–2 / 3–5 / 6–10 / Más de 10
4. ¿Cuántos de esos estaban en oferta? — Ninguno / Algunos / La mayoría / Todos
5. ¿Cómo te enterás de las ofertas? (varias opciones) — Email de la wishlist de Steam / Notificaciones de la app de Steam / Navegando la tienda / Amigos / Redes sociales / Reddit / Telegram o Discord / IsThereAnyDeal, SteamDB u otra web / Otra
6. ¿Qué te molesta de cómo te enterás hoy? (varias opciones) — Me entero tarde / Me llegan ofertas que no me interesan / Tengo que buscarlas yo / Los precios no están en mi moneda o región / Nada, estoy conforme / Otra
7. En los últimos 3 meses, ¿te enteraste de la oferta de un juego que te interesaba cuando ya había terminado? — Sí, varias veces / Sí, una vez / No / No me acuerdo
8. Si respondiste que sí: ¿ese juego estaba en tu wishlist? — Sí / No / Algunos sí y otros no
9. ¿Usás la wishlist de Steam? — Sí, la mantengo al día / La tengo pero abandonada / No
10. ¿Qué tan útil te resultaría recibir en el teléfono ofertas de juegos parecidos a los que te gustan, aunque no estén en tu wishlist? — Escala 1 a 5 (**señal débil**: es una opinión sobre el futuro)
11. ¿Cuánto gastás en promedio por mes en juegos? — Nada / Menos de 5 USD / 5–15 USD / 15–30 USD / Más de 30 USD
12. Contanos la última vez que te perdiste una oferta: qué juego era y cómo te enteraste. — Respuesta larga
13. ¿Querés probar una versión temprana? Dejá tu email o usuario de Discord/Telegram. — Respuesta corta (**señal fuerte**: es un compromiso)

---

## 5. Piloto con la versión personal

La versión personal se construye igual, porque la necesitás. El piloto es dársela a un grupo chico y medir si la usan.

- **Quiénes:** de 10 a 20 personas que se anotaron en entrevistas o en la encuesta. La cuenta de distribución limitada de Android permite instalarla en hasta 20 dispositivos, gratis y sin documento [verificado en developer.android.com].
- **Duración:** 4 semanas.
- **Métricas:** salen de los mismos eventos que ya registra el recomendador, así que no hace falta otra herramienta de analytics.

| Métrica | Qué mide |
|---|---|
| % de participantes activos cada semana (abren la app o una notificación) | H3, uso sostenido |
| % de notificaciones abiertas | Si los avisos son relevantes |
| Clicks a "Ir a Steam" por persona y semana | Intención de compra |
| Compras declaradas (botón "Lo compré" o encuesta final) | Valor real |
| Test de Sean Ellis al final: "¿Cómo te sentirías si mañana ya no pudieras usar la app?" (muy / algo / nada decepcionado) | Qué tan necesaria es |
| Anotados a una lista de "precio fundador" | H4, primera señal de pago |

---

## 6. Regla de decisión

Se fija **antes** de ver los datos, para no acomodar los umbrales a los resultados. Todos son [criterio propio] y se pueden ajustar antes de empezar.

**Pasar a diseñar la monetización** si se cumplen las tres:
1. Entrevistas: al menos 5 de 8 cuentan un caso concreto de los últimos 3 meses.
2. Piloto: en la semana 4, al menos el 40 % de los participantes sigue activo.
3. Test de Sean Ellis: al menos el 40 % responde "muy decepcionado".

Como el grupo del piloto es cercano y tiende a ser amable, estos umbrales son más exigentes de lo que serían con desconocidos.

**Ajustar la propuesta y repetir el piloto una vez** si el problema aparece en las entrevistas pero el piloto no retiene: el problema existe, pero la solución no convence.

**Quedarse con la herramienta personal y el portafolio** si menos de 3 de 8 entrevistados cuentan un caso concreto, o si casi nadie se anota al piloto.

---

## 7. Calendario orientativo

| Semanas | Qué |
|---|---|
| 1–2 | Entrevistas y encuesta. La versión personal se construye en paralelo |
| 3–6 | Piloto de 4 semanas |
| 7 | Síntesis y decisión |
