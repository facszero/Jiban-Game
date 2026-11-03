# Locomoción, revisión 4

Referencia visual: demostración de movimiento alrededor de 6:00 del video aportado por el usuario, Cómo hacer un juego en TERCERA PERSONA: CÁMARA Y CONTROLES.

- En exploración, el cuerpo gira suavemente hacia la velocidad real, independientemente de la cámara. Al detenerse conserva su orientación.
- Apuntar o disparar devuelve el cuerpo hacia la mira; una retención de 0,35 segundos evita cambios entre disparos.
- Poses de recuperación del pie interpoladas, compresión tras el contacto, elevación sobre el apoyo y coordinación de pelvis, hombros y brazos.
- Cadencia calculada con la velocidad, longitud de paso y fracción de apoyo. Velocidades: caminar 2,0 y correr 4,6 unidades/segundo, ajustadas al tamaño del personaje.
- Resolución de piernas para avance, retroceso y desplazamientos laterales. Se conserva la alineación del disparo en primera persona.

La animación sigue siendo procedural con poses definidas manualmente; no es captura de movimiento ni una reproducción exacta del video. No adapta los pies a desniveles. Los giros, transiciones y el desplazamiento lateral aún pueden presentar deslizamiento residual.

## Validación

Pruebas de locomoción: apoyos, elevación, arranque/frenada, bloqueo, apuntado, salto, dirección de exploración, independencia de cámara y retorno a combate. Regresiones de combate, visor y origen del disparo. Inspección de ocho fases laterales de caminar y correr y exportación Web.

## Prueba manual

En tercera persona, avanzar, desplazarse lateralmente, retroceder, girar la cámara estando quieto y disparar mientras se avanza de lado. En PC, Shift permite correr. En Pausa → Ver modelos 3D → Jiban, activar Caminar y comparar las variantes del selector. Revisar respuesta y fluidez en el teléfono objetivo.
