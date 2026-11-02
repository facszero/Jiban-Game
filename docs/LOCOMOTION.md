# Marcha articulada y revisión visual 3

Jiban utiliza una marcha procedural que responde a la velocidad real. Caderas, rodillas y tobillos coordinan la fase de apoyo y elevación del pie, con movimiento leve del torso y transiciones al arrancar y detenerse. La carrera amplía el paso; apuntar estabiliza los brazos. El movimiento no modifica velocidades, colisiones ni reglas de combate.

En Pausa → Ver modelos 3D, seleccionar Jiban, activar Caminar y comparar caminar, correr y apuntando. Probar también en tercera persona: avanzar, retroceder, desplazarse lateralmente, detenerse contra una pared y saltar.

Es una animación procedural, no captura de movimiento ni adaptación de pies al terreno. La comodidad y el rendimiento deben comprobarse en el teléfono objetivo.

Chamelenoid recibe placas pectorales de contorno irregular, cejas más marcadas y materiales con escamas y pliegues. Conserva sus ataques y comportamiento.

## Validación

- `godot --headless --script res://tests/locomotion.gd`: apoyo, elevación, transiciones, bloqueo, apuntado y salto.
- `tests/locomotion_visual.gd`: capturas laterales de cuatro fases para inspección.
- Regresiones: `tests/smoke.gd`, `tests/model.gd`, `tests/chamelenoid.gd`.
- Exportación Web y validación de despliegue mediante GitHub Actions.
