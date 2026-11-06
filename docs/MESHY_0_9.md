# Chamelenoid Meshy — 0.9.0

The user-provided textured Meshy GLB replaces the procedural creature. The original download remains untouched.

- Original: 1,720,468 triangles, no skeleton or animations.
- Runtime: 59,998 triangles, 16 bones, six animation clips, 11 MB GLB.
- Original base-color, normal and metallic/roughness textures preserved.
- Connected lower-arm regions separate hands from thighs. Shoulder and elbow weights blend across joints.
- Idle, walk, alternating claw attacks, stagger and forward death collapse are integrated into the existing combat controller.
- Death now buckles, pitches forward, and ends on the ground. This is a keyed animation, not a physics ragdoll.
- The viewer uses neutral lighting for inspecting materials.

## Validation

Ten existing game suites pass. Skin validation samples every third animation frame: maximum edge length ratio 2.93; minimum vertex height -0.012 m. Rendered front, back, profile, attack, walk, reactions and in-level views were inspected in Godot 4.5.1.

The mesh budget is 65,000 triangles to accommodate this visual review. Mobile performance has not been measured. Fingers remain a single hand group. The jaw bone is retained for controller compatibility but does not deform this closed Meshy face. Broad joint deformation is functional; artist retopology and animation polish remain potential improvements.

## Editable source

The local Chamelenoid_meshy_0.9.0 archive contains the optimized static input, rigged Blender project, runtime GLB, and builder. To rebuild with Blender 4.3.2:

```
blender -b --python rig_meshy.py -- --source meshy_optimized_static.glb --output runtime --blend Chamelenoid_meshy_rigged.blend
```

The normalized working input was decimated from the original at ratio 60000/1720468 with UVs preserved, then coincident vertices merged at 0.00001 m. Height is 2.82 m before the existing game scale is applied.
