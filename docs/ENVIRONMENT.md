# Sector 01 — industrial environment, 0.11.0

Replaces flat surfaces with modular steel panels and floor plates, textured roughness, overhead pipes and cable elbows, vent grilles, drainage strips, framed entrances and instrument consoles. Containment tanks have transparent shells, solid cylinder collisions, red fixtures, static Chamelenoid specimens and subtle animated steam. Existing route, security terminals and door progression are retained.

`industrial_sector.gd` groups repeated opaque pieces into MultiMeshes by material/shape and 12-metre room slices. Room slices prevent Compatibility's per-object light selection from treating the entire corridor as one object. Three once-updated reflection probes provide local reflections. Cold overhead spotlights provide shadows; red practical lights illuminate tank areas. This uses Godot GL Compatibility, including the web build. No screen-space reflections or volumetric fog dependency.

Wall and floor albedo images were generated with the built-in image_gen tool, then copied unchanged into assets/environment. Remaining microstructure/roughness and console graphics were generated procedurally. The concept image is a direction reference, not a guarantee of equivalent real-time rendering. Reflections, smoke and detail density remain simpler than the concept.

Validation: tests/environment.gd checks traversal, tank collisions, non-combat specimens and retained consoles. tests/environment_visual.gd renders actual engine entry/lab views and reports draw calls. Standard smoke suite checks movement, camera, shooting, terminal interaction, checkpoint and completion.

The Bioron ranged projectile remains a separate authorized task; this release changes environment presentation only.

## 0.11.1 — security entrance detail

The first security door now carries layered chamfered panels, raised latches and seal rails; all moving details follow its original opening tween. Its collision depth includes the new front surface. Fixed side guides and a local shadow-casting task light articulate the entrance. Consoles have chamfered housings, pedestals, inset full-UV screens, tactile buttons, physical title plates and visible pending/authorized states that follow activation and reset. Security and containment displays are distinct. The HUD top band is smaller and the red wall lighting is more localized. This iteration focuses on the entrance; it does not claim the entire level has reached the concept image.

Visual checks: `tests/security_visual.gd` captures overview, close console, active console and open door. Functional status/reset checks: `tests/security_state.gd`. Existing smoke, touch and environment tests cover gameplay and traversal.

## 0.11.2 — localized environmental effects

Two visible pressure outlets near the containment tanks emit intermittent vapor. Opening the security door triggers two short pressure releases at its base. A damaged electrical box beside the second portal produces an occasional short arc, falling sparks and a synchronized blue local light. Original synthesized hiss/crackle sounds use positional attenuation. Effects are cosmetic and do not damage or obstruct characters.

The vapor system reuses a fixed pool of 64 camera-facing quads. Each puff expands, rises and fades; the old static tank steam cards have been removed. Ambient bursts only start within 22 m of the camera (20 m for the arc). Arc and spark geometry is reused. There are no continuously-created particles/nodes, volumetric-fog dependencies or screen-wide flashes. Effect time and audio inherit the level's pause behavior; shader animation uses the same paused age value.

`tests/effects.gd` checks door triggering, pool limits, dissipation and synchronized arc lighting. `tests/effects_visual.gd` captures actual vapor, arc and opening-door views. Smoke tests cover the existing gameplay loop.
