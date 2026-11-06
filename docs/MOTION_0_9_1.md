# Motion and mouse review — 0.9.1

Chamelenoid pursues at 1.9 m/s (previously 1.25). Walk stance is 56% of a cycle, with 0.72 m of local foot travel; GAIT_PER_METER accounts for both visual scales. Swing clearance is 0.16 m. Lateral pelvis sway is reduced; arms counter-swing more. The model viewer uses the same chase cadence.

Regression coverage checks planted foot drift under 2.5 cm, support height, and swing clearance over 12 cm. The existing combat suites and Blender deformation validation pass.

Mouse aiming uses screen_relative, as recommended by Godot 4.5 for captured input: https://docs.godotengine.org/en/4.5/classes/class_inputeventmousemotion.html#class-inputeventmousemotion-property-screen-relative
Capture requests are idempotent. The first event and a short settling interval after acquisition, focus return, resize or resume do not rotate the camera. Firing does not modify pitch. Tests exercise actual capture with a display; CI uses Xvfb because headless mode cannot acquire a real pointer.

The user reports abrupt downward aim mainly when clicking to shoot. This browser/hardware-specific symptom has not been reproduced locally, so these are input-stability corrections, not proof of its exact cause. Godot itself normally ignores capture requests when pointer lock is already active. Keep checking the user's actual browser after publication.
