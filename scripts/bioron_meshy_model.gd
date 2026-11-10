extends "res://scripts/jiban_meshy_model.gd"
func neutralize_arms() -> bool:
	return true
func asset_path() -> String:
	return "res://assets/bioron_meshy/bioron.glb"
func _ready() -> void:
	super._ready()
	# The replacement A-pose model has no weapon. Attach the existing service
	# pistol to its actual hand bone, not to the old procedural elbow marker.
	var hand := skin_skeleton.find_bone("hand.R")
	var mount := BoneAttachment3D.new()
	mount.bone_name="hand.R"
	skin_skeleton.add_child(mount)
	var pistol=preload("res://scripts/service_weapon.gd").new()
	mount.add_child(pistol)
	var neutral_basis: Basis=global_basis.inverse()*skin_skeleton.global_basis*skin_rest[hand]
	pistol.transform=Transform3D(neutral_basis.inverse()*Basis(Vector3.RIGHT,-PI/2),neutral_basis.inverse()*Vector3(0,-.055,-.015))
