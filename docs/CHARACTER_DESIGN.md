# Character design pass — v0.5.0

Approved references: Jiban armor sheet, Chamelenoid creature sheet and Mask/Bioron soldier turnaround from this project.

## Implemented

- Mask replaces the rounded placeholder with fitted cloth profiles, almond eye borders, forehead emblem, lower-face crescent, chest stripe, belt, gloves and light shin/forearm protection. Its articulated rig uses the current human gait and forward aiming pose. Existing combat/damage rules remain unchanged, with a short visible hit reaction.
- Mask is available alongside Jiban and Chamelenoid in the pause-menu model viewer.
- Jiban gains armor seams, fasteners and a restrained metal finish, preserving the corrected arm/weapon orientation.
- Chamelenoid's regular scale bubbles and striped folds are replaced with smaller, less uniform surface detail. Eye openings are wider.
- Visible version 0.5.0 and commit-specific web resource filenames help identify stale browser assets.

## Limits and next art work

These remain procedurally authored game meshes, not the final fidelity shown in the concept illustrations. Further work is needed on facial contours, organic anatomical transitions, bespoke textures and costume folds. No guarantee of device frame rate follows from the geometry budgets alone. Generic enemies still use their existing close-range combat logic; displaying a pistol does not introduce ranged AI.

## Validation

Smoke, locomotion, model-viewer, Chamelenoid, muzzle and touch regressions; Mask rig validity, weapon direction, damage, hit pose and geometry budget. Front/profile render captures for all three plus Mask aiming. Web export.
