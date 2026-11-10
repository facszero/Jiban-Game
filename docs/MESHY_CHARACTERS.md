# Meshy integration — 0.10.1

Bioron now uses the replacement A-pose design supplied on November 10 (70,000 triangles), instead of the old crouched firing sculpt. Its bind pose stays intact, with arm alignment applied at runtime. The separate service pistol attaches to the actual hand bone. Hands have no articulated finger animation yet.

Jiban (150,000 triangles) and Bioron use leg IK based on their actual bone lengths, with forward knee poles and level soles. Lower foot clearance, restrained vertical travel and relaxed arm swing replace the previous exaggerated gait. Cadence follows ground speed and stride length. Full-cycle tests cover four travel directions and walking/running, including knee plane, foot support and drift; actual mesh deformation tests check stretching and ground penetration.

Chamelenoid now dissolves with irregular green corrosion edges over 2.2 seconds, holding the last living pose instead of falling rigidly forward. Death still immediately disables attacks and collisions and completes encounters once. Material overrides are per instance and reset in the studio.

The user-supplied service pistol (60,000 triangles) replaces Jiban's first-person gun. Original color/metal/roughness textures are retained, tangent normals rebaked, and the red strip receives selective emission. The existing procedural glove/forearm remains. The muzzle marker is calibrated to the imported barrel and tested through camera yaw/pitch and weapon withdrawal. Third-person Jiban weapon remains part of its character mesh.
