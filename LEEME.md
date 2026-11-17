# Golf, según recuerdo

Golf caótico en 3D hecho en **Godot 4** (GDScript), inspirado en *What the Golf?*.
No juegas con una pelota: juegas con una **bomba con la mecha encendida**. Tienes que meterla al hoyo antes de que explote.
Probado en Godot 4.7.2 (renderizador Compatibility, física Jolt). Debería abrir desde Godot 4.4.

## Cómo abrirlo
1. Descomprime la carpeta.
2. En Godot: **Importar → `project.godot`**.
3. Espera a que importe (la primera vez tarda unos segundos por el audio) y presiona **F5**.

## Cómo se puntúa
No hay golpes ni par: se juega **contra reloj**. Cada hoyo tiene su mecha:

| Hoyo | Mecha | 3 estrellas | 2 estrellas | 1 estrella |
|---|---|---|---|---|
| 1. Primer Día | 60 s | menos de 30 s | menos de 45 s | antes de que explote |
| 2. Camino a la Biblioteca | 75 s | menos de 35 s | menos de 55 s | antes de que explote |
| 3. Santuario de Murciélagos | 70 s | menos de 30 s | menos de 48 s | antes de que explote |
| 4. El Manglar | 120 s | menos de 55 s | menos de 85 s | antes de que explote |
| 5. SIGMAA (Jefe Final) | 180 s | menos de 85 s | menos de 130 s | antes de que explote |

Si la mecha llega a cero, la bomba explota: **0 estrellas**. Puedes reintentar o seguir al siguiente hoyo.
Caer al agua, a la lava o al vacío cuesta **5 segundos**. Reiniciar el tiro (R) cuesta 3 segundos. Los **relojes verdes** dan +5 s.
Los tiempos y las estrellas se cambian en `LEVELS`, dentro de `scripts/game.gd`.

## Controles
| Acción | Control |
|---|---|
| Tirar | Clic izquierdo y **arrastrar hacia atrás** (como resortera), soltar |
| Cambiar rodar / elevar | **F** o Espacio |
| Girar cámara | Clic derecho + arrastrar, o Q/E (A/D, flechas) |
| Inclinar cámara | W/S |
| Zoom | Rueda del mouse |
| Reiniciar tiro (-3 s) | R |
| Pausa | Esc o P |

## Los hoyos (ambientados en la Universidad del Caribe)
1. **Primer Día** — al principio solo existe un tramo corto. Cuando la bomba se acerca, el hoyo huye y el campus se construye delante (bloques que caen del cielo), dos veces. Cocodrilo en el estanque, ibis, iguanas y jardineras.
2. **Camino a la Biblioteca** — cangrejos-imán en la entrada, árbol con panal en el camino corto (o lo cruzas rápido o rodeas), río con tronco y cocodrilo, y el hoyo frente a la biblioteca con un cangrejo cerca.
3. **Santuario de Murciélagos** — cueva con gravedad invertida. Si pasas 10 s en la oscuridad, los murciélagos se llevan la bomba; la luz de los hongos reinicia el contador (barra "OSCURIDAD" arriba).
4. **El Manglar** — agua con Don Coco, troncos flotantes, águila pescadora en su percha (sus ráfagas empujan la bomba; espera a que deje de aletear), otra águila que caza en picada, corriente y raíz-rampa.
5. **SIGMAA (Jefe Final)** — la sala de servidores de SIGMAA: arena circular de piedra con líneas azules, obeliscos, trono, racks y la pantalla gigante con "espere un momento...". Ver la sección del jefe.

## El jefe: SIGMAA y su mecha tortuga
- **Cinemática de entrada** (se puede saltar con el botón o Esc): la tortuga habla desde su trono, llega el mecha, la tortuga se sube a su espalda y aparece la presentación estilo "character splash".
- **Ataques:** camina lento disparando con las ametralladoras (solo empujan), salta y cae con daño en área, y desde la fase 2 lanza misiles. En la fase 3 aprende la **mira roja** que te persigue y dispara un rayo. Las líneas del piso se ponen rojas antes de cada ataque fuerte. Misiles, saltos, golpes y rayo empujan la bomba y quitan 3 s.
- **Golpe a dos manos:** golpea el suelo y se queda agachado unos segundos. Ahí está **vulnerable**: la cola baja como rampa hasta su espalda, donde se ve el hoyo (bandera y aro luminoso).
  - Tiro **rodando**: sube por la cola (necesita un tiro de fuerza media).
  - Tiro **en arco**: cae directo en la espalda.
- **Cada golpe:** la bomba explota en su espalda, sale volando a un lugar seguro detrás de él y el mecha pasa de fase: camina más rápido, usa menos el golpe a dos manos (cada 2, 3 y 4 ataques) y aprende ataques nuevos.
- **A los 3 golpes:** cinemática final de reflexión; la tortuga vuelve a su trono y termina el nivel.

## Fauna
| Animal | Qué hace |
|---|---|
| Cocodrilo / Don Coco | Si la bomba cae al agua, se la come (−5 s). |
| Ibis blanco | Patrulla (línea, círculo u ocho). Da un empujón corto según la velocidad de la bomba. No quita tiempo. |
| Cangrejo rojo / azul | Imán: el rojo jala y el azul empuja. Radio visible y línea de jalón. |
| Iguana | Quieta. Si la bomba entra a su círculo rojo, avisa 0.7 s y lanza la lengua a donde estaba la bomba. Si la atrapa, se la traga (−5 s). Recarga 5 s. |
| Abejas | 3 s dentro del círculo amarillo y se llevan la bomba a la colmena (−5 s). Salir reinicia la cuenta. |
| Murciélagos | 10 s en la oscuridad y se llevan la bomba (−5 s). Los hongos luminosos reinician el contador. |
| Águila pescadora | En percha: ráfagas con pausas. En vuelo: marca un círculo rojo y baja en picada (−5 s si te atrapa). |

## Mecánicas
- **Trampolines**, **portales**, **relojes** (+5 s), pads de gravedad, plataformas, viento y corriente.

## Estructura
- `scenes/main.tscn` — única escena; todo se construye por código.
- `scripts/game.gd` (autoload `Game`) — niveles, tiempos, estrellas, opciones y guardado.
- `scripts/level.gd` — cámara, tiro, mecha/temporizador, peligros, mecánicas y victoria.
- `scripts/levels.gd` — geometría de cada hoyo y helpers (`jump_pad`, `magnet`, `portals`, `clock`, `side_sign`).
- `scripts/boss.gd` — el jefe (modelo del mecha, poses, ataques, fases y cinemáticas). `scripts/cinematic.gd` — diálogos, botón de saltar y presentación.
- `scripts/ball.gd` — la bomba (mecha que se acorta, chispa, parpadeo rojo al final).
- `scripts/crocodile.gd` — cocodrilo y Don Coco.
- `scripts/hud.gd`, `stars.gd`, `menu.gd`, `scorecard.gd`, `ui_kit.gd` — interfaz.
- `scripts/build.gd` — modelos 3D procedurales y partículas. `shaders/` — césped, agua, lava, pads.
- `assets/` — audio generado por `tools/generar_audio.py` (requiere numpy) y la fuente Lilita One (SIL OFL).
- `tools/autotest.gd` — prueba automática: `godot --headless --path . -- --autotest`
- `capturas/` — imágenes del juego (Godot las ignora).

Los créditos (nombres del equipo) están en `_credits_panel()` de `scripts/menu.gd`.
Los modelos del campus y la fauna están en `scripts/unicaribe.gd`; el comportamiento de cada animal en `ibis.gd`, `iguana_turret.gd`, `beehive.gd` y `osprey.gd`.
