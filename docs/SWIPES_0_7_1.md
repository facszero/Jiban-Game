# Chamelenoid: zarpazos y embestida (0.7.1)

El ataque corto se reemplaza por dos barridos amplios alternados. La garra se abre hacia el costado, pasa por delante del pecho y termina al otro lado del cuerpo, acompañada por el giro del torso, la mandíbula abierta y un paso de apoyo. El visor alterna derecha e izquierda cada vez que se pulsa ATAQUE, después de finalizar el anterior.

En combate, el enemigo inicia el ataque hasta 2,7 m del objetivo y se abalanza hasta unos 0,90 m durante la descarga. La dirección queda fijada durante la preparación: permite esquivar lateralmente. La embestida usa las colisiones del personaje y no atraviesa paredes. Se conserva el impacto a los 0,78 s, un máximo de 28 de daño por zarpazo y la recuperación a los 1,45 s.

El GLB incluye Idle, Walk, AttackRight y AttackLeft. El generador usa una cadena de brazo de dos huesos para alcanzar los puntos del barrido sin estirar los segmentos.

Validación local con Godot 4.5.1: nueve suites, incluida heavy_swipes (alternancia, amplitud, recuperación, avance, daño único, esquiva y bloqueo por paredes). Revisión visual de ambos brazos, captura de preparación, impacto y final del barrido. Exportación Web correcta. Muestreo de deformaciones en Blender: ambos zarpazos quedan por debajo del límite de estiramiento de la comprobación existente; sin penetración apreciable del suelo. Rendimiento en teléfono físico pendiente.
