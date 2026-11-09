extends "res://scripts/jiban_meshy_model.gd"
func asset_path() -> String:
	return "res://assets/bioron_meshy/bioron.glb"
func pose(phase: float,movement: float,running: float,aiming: float,direction: Vector2,grounded: bool) -> void:
	# Shorter tactical steps preserve the long coat and the two-handed grip.
	super.pose(phase,movement,running*.25,aiming,direction,grounded)
