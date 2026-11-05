# Chamelenoid: prueba 0.7.0

La escultura del estudio Blender se incorpora al combate y al visor de personajes. Se amplía la profundidad del tórax y espalda y se adelanta la cabeza; las proporciones del resto del cuerpo se conservan.

Recurso: `assets/chamelenoid/chamelenoid.glb`, 27.019 triángulos, 16 huesos, ocho superficies de material y tres animaciones (Idle, Walk, Attack). El golpe se muestrea con el reloj de combate; cancelar o completar el ataque restaura brazo y mandíbula. Los pesos regionales evitan que la cercanía del antebrazo al muslo vincule sus vértices al mismo hueso.

Validación local con Godot 4.5.1: importación y exportación Web; suites smoke, touch, model, chamelenoid, locomotion, muzzle, mask y comparison. Capturas reales del visor y del nivel. Validación adicional en Blender de caminata y ataque: sin los triángulos largos que unían brazo y cadera; altura mínima de la malla -0,00064 m antes de la escala de juego.

Es una reconstrucción a partir de la escultura estática y las decisiones recuperadas de la charla, no el archivo perdido. Los materiales procedurales se aproximan mediante colores de vértice; faltan las texturas finales de piel, refinamiento artístico y mediciones en Samsung A56. Las deformaciones normales de hombro y codo todavía pueden mejorarse con retopología.

Para verlo: pausa → visor de personajes → Chamelenoid. Usar caminar, ataque y perfil. También aparece como enemigo pesado en el nivel.
