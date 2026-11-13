# Sector 01 — industrial environment, 0.11.0

Replaces flat surfaces with modular steel panels and floor plates, textured roughness, overhead pipes and cable elbows, vent grilles, drainage strips, framed entrances and instrument consoles. Containment tanks have transparent shells, solid cylinder collisions, red fixtures, static Chamelenoid specimens and subtle animated steam. Existing route, security terminals and door progression are retained.

`industrial_sector.gd` groups repeated opaque pieces into MultiMeshes by material/shape and 12-metre room slices. Room slices prevent Compatibility's per-object light selection from treating the entire corridor as one object. Three once-updated reflection probes provide local reflections. Cold overhead spotlights provide shadows; red practical lights illuminate tank areas. This uses Godot GL Compatibility, including the web build. No screen-space reflections or volumetric fog dependency.

Wall and floor albedo images were generated with the built-in image_gen tool, then copied unchanged into assets/environment. Remaining microstructure/roughness and console graphics were generated procedurally. The concept image is a direction reference, not a guarantee of equivalent real-time rendering. Reflections, smoke and detail density remain simpler than the concept.

Validation: tests/environment.gd checks traversal, tank collisions, non-combat specimens and retained consoles. tests/environment_visual.gd renders actual engine entry/lab views and reports draw calls. Standard smoke suite checks movement, camera, shooting, terminal interaction, checkpoint and completion.

The Bioron ranged projectile remains a separate authorized task; this release changes environment presentation only.
