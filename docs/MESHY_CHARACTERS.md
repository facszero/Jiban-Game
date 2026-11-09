# Jiban and Bioron Meshy integration — 0.10.0

User-supplied Meshy surfaces replace the procedural third-person Jiban and standard Bioron enemies, including the model studio and comparison stage. Original base-color and metal/roughness maps are preserved; tangent normals are rebaked from the original high-resolution meshes at 2048 px. Jiban: 150,000 triangles. Bioron: 70,000 triangles. Each uses a 15-bone skeleton driven by the existing locomotion controller.

Bioron keeps the original two-handed weapon grip; arms currently follow the chest. His shortened tactical stride limits coat distortion. This is an initial animation integration, not a final character animation pass. The first-person weapon remains the existing functional model. Third-person shot origin remains the existing gameplay offset rather than a newly calibrated Meshy barrel attachment.

Skin tests deform actual imported vertices in idle, walk, run and aiming poses, checking edge stretch and floor penetration. Existing gameplay, comparison and native mouse-input tests also pass locally. Neutral studio images are captured separately for visual review. Sky reflections support metallic materials in both gameplay and studio.
