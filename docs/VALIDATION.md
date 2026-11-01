# Validación de la entrega 0.1

Fecha: 2026-10-31. Motor: Godot 4.5.1.stable.official.f62fdbde1.

- Importación completa sin errores de script.
- Arranque de escena y simulación de física.
- 23 comprobaciones automáticas satisfactorias (registro debajo).
- Renderizado real de ambas perspectivas a 1280×720 mediante Xvfb y OpenGL/Mesa llvmpipe; capturas inspeccionadas. Se corrigió iluminación demasiado oscura.
- Advertencia del renderizador: V-Sync no configurable en la pantalla virtual. No afectó las capturas.

Las pruebas ejercitan eventos y física del motor; no equivalen a una partida manual completa. No se probaron mando físico, exportación Windows, rendimiento real ni sesión de 10–15 minutos. El audio se sintetiza, pero no se hizo evaluación auditiva. El checkpoint no persiste al cerrar.

La prueba detectó y permitió corregir pérdida de impacto por precisión numérica en el extremo del rayo al cambiar de cámara. Las pruebas cubren además interacción mediante una acción de entrada, detección visual de terminal y restauración del estado tras muerte/finalización.

## Registro

```text
Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org

PASS: Player stands on collision floor
PASS: Movement input moves player forward
PASS: Jump leaves floor
PASS: First person hides body
PASS: Perspective switch does not teleport player
PASS: Third person stays behind body
PASS: Camera retracts before rear wall
PASS: First person shot consumes ammo and damages target
PASS: Third person reticle damages the same target
PASS: Wall blocks weapon damage
PASS: Reload transfers reserve into magazine
PASS: Damage invulnerability prevents duplicate hit
PASS: Enemy pursues visible player
PASS: Enemy attacks player
PASS: Nearby aimed terminal is interactable
PASS: Interaction input activates aimed terminal
PASS: Terminal activation is idempotent
PASS: Two terminals unlock door and checkpoint
PASS: Death pauses game
PASS: Checkpoint restores player past door
PASS: Elevator completes sector
PASS: Restart clears completed sector state
PASS: Input setup is idempotent
SMOKE RESULT: 0 failures
```
