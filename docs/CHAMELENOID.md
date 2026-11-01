# Chamelenoid — primera revisión jugable

Modelo basado en la lámina aprobada: cabeza estrecha con cresta sagital, ojos
oblicuos dorados, mandíbula, torso con placas verdes, musculatura granate,
láminas de hombro y manos con tres dedos y pulgar. Tiene articulaciones rígidas
en hombros, codos, caderas y rodillas. Las superficies usan ruido determinista
para variación de color y relieve fino; no son texturas fotográficas ni una
reproducción final del detalle de la lámina.

Se instancia el mismo `chamelenoid_model.gd` en el enemigo pesado y en el visor.
Los soldados comunes conservan su modelo y comportamiento. La escala de combate
es 1,1; vida, velocidad y daño del enemigo pesado siguen siendo 175, 1,25 y 28.

## Ataque

- Entrada en alcance a menos de 2 metros con línea de visión.
- Preparación de 0,65 s: gira el torso y retira el brazo derecho.
- Barrido visible; un único intento de impacto a los 0,78 s.
- Recuperación hasta 1,45 s y pausa adicional de 0,35 s.
- Orientación fija durante la secuencia. Al impacto se comprueba distancia
  menor de 2,1 m, cono frontal y línea de visión. Retroceder, pasar a un costado
  o interponer una pared puede evitar el daño.

## Inspección

PAUSA → VER MODELOS 3D → CHAMELENOID. Giro táctil, zoom, frente, perfil,
espalda, CAMINAR y ATAQUE. Cambiar de modelo mantiene la partida en pausa.

## Validación y límites

`tests/chamelenoid.gd` verifica preparación sin daño, impacto único, recuperación,
esquiva hacia atrás/lateral, bloqueo por pared y selección del visor.
`tests/chamelenoid_visual.gd` genera renders de frente, espalda, ataque y pasillo.
Se mantienen las pruebas de combate, controles y visor anteriores.

Sigue pendiente el acabado artístico fino, animación de muerte y un rig con
más deformación orgánica. El objetivo móvil A56 requiere mediciones en equipo
real antes de considerarlo un requisito mínimo confirmado.


## Revisión 2 — cabeza y torso

La cresta usa una malla volumétrica de base ancha que nace en la frente y se
estrecha hacia atrás. Los ojos son más estrechos y están encajados en el borde
orgánico del párpado. Las placas usan contornos redondeados y varias secciones
curvas, en lugar de un frente plano con bisel. Los pectorales y las placas
abdominales se aproximan para reducir las separaciones.

La malla tiene aproximadamente 20.100 triángulos y mantiene 32 mallas dibujables.
No se cambia la lógica del ataque, daño, colisión ni velocidades. Sigue pendiente
un acabado de piel más detallado y la medición de rendimiento en móvil real.
