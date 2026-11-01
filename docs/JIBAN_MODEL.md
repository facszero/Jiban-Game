# Jiban: primera revisión de la armadura

El jugador y el estudio usan `scripts/jiban_model.gd`: perfiles de sección
elíptica y placas biseladas, fusionados por material dentro de cada articulación.
Aproximadamente 8.400 triángulos y 34 mallas. Es un presupuesto de geometría,
no una medición de FPS ni una garantía de rendimiento móvil.

## Revisión

Pausa → VER MODELO 3D DE JIBAN. Arrastrar gira la cámara; los botones muestran
frente, perfil y espalda, ajustan zoom y prueban la marcha. Volver a pausa
conserva vida, munición, posición y progreso. El estudio tiene un mundo 3D
independiente y bloquea los controles táctiles del juego mientras está abierto.

## Alcance y pendientes

Silueta adulta, casco con visor rojo y mandíbula plateada, coraza azul marino,
insignia, espalda anatómica, abdomen segmentado, cinturón y extremidades con
armadura. Hombros, codos, caderas y rodillas usan articulaciones rígidas.
La pistola de tercera persona acompaña al brazo; la de primera persona conserva
su protección contra intersecciones con terminales y paredes.

Primera interpretación 3D de la lámina, todavía sin su acabado ilustrado.
Faltan texturas de desgaste, detalle fino, revisión de materiales con reflexiones
y animaciones de combate completas. No hay un esqueleto con deformación de piel.
Chamelenoid conserva su modelo anterior para concentrar esta revisión en Jiban.

## Validación

`tests/model.gd`: aislamiento del estudio, bloqueo/restauración de entrada,
articulaciones, giro táctil, zoom y conservación de la partida.
`tests/model_visual.gd`: renders del frente, espalda y pasillo.
`tests/smoke.gd` y `tests/touch.gd`: mecánicas y controles.

El Galaxy A56 sigue como dispositivo objetivo provisional. El mínimo se
confirmará después de medir FPS sostenidos, memoria y temperatura en equipo
real; los renders de escritorio no sustituyen esa prueba.

## Revisión 2

Material plateado más oscuro y menos luz auxiliar sobre el jugador; detalles
adicionales de casco y espalda. Pistola compartida entre primera y tercera
persona, con guardamonte, miras, boca y empuñadura. La presentación en primera
persona es más compacta. Las cajas estáticas se fusionan por material sin
eliminar los pivotes animados. Sigue pendiente el acabado fino de texturas.

