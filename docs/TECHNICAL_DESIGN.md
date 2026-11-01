# Diseño técnico

Godot 4.5.1 Standard, GDScript, Compatibility. Sin dependencias de ejecución externas.

| Archivo | Responsabilidad |
|---|---|
| `scenes/main.tscn` | Punto de entrada |
| `scripts/game.gd` | Coordinación del recorrido, HUD, pausa y checkpoint |
| `scripts/player.gd` | Movimiento, cámara, recursos y primer arma |
| `scripts/enemy.gd` | Estados y comportamiento de las dos variantes |
| `scripts/level.gd` | Construcción del sector y creación de enemigos |
| `scripts/terminal.gd` | Interacción de terminal reutilizable |
| `scripts/geometry.gd` | Primitivas, materiales, luces y carteles |
| `scripts/controls.gd` | Registro idempotente de acciones |

Capas físicas: 1 escenario/interactuables, 2 jugador, 4 enemigos. La cámara usa barrido de esfera contra el escenario. La mira converge sobre un rayo que parte del visor; el daño se calcula desde un origen estable del personaje, con una extensión de 5 cm al final del segmento para evitar fallos numéricos en superficies. Las paredes y el cuerpo de los enemigos participan en la prueba física.

Señales separan impactos, muerte y activación de terminales del flujo del nivel. Los parámetros iniciales de velocidad y daño son exportables. Antes de introducir más armas, extraer arma y recursos del controlador a componentes/Resources. Antes de ampliar HUD y misiones, extraerlos de `game.gd`. No hay todavía SaveManager ni CinematicManager: no se crean módulos vacíos para aparentar funciones.

Los enemigos usan percepción por rayo y persecución directa con `CharacterBody3D`. Esta versión no usa navegación por malla ni detección por ruido; el nivel mantiene las rutas de combate despejadas. El checkpoint recrea la fase de contención y limpia el estado de combate, pero no se serializa en disco.
