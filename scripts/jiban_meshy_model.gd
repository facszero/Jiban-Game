extends "res://scripts/jiban_model.gd"
## Meshy surface driven by the existing, tested locomotion controller.
var skin_skeleton: Skeleton3D
var skin_visual: Node3D
var proxy_nodes := {}
var proxy_rest := {}
var skin_rest := []
func asset_path() -> String:
	return "res://assets/jiban_meshy/jiban.glb"
func _ready() -> void:
	super._ready()
	remove_proxy_meshes(self)
	proxy_nodes={"pelvis":pelvis,"chest":upper_body,"head":upper_body,
		"upper_arm.L":arm_left,"upper_arm.R":arm_right,
		"forearm.L":elbows[0],"forearm.R":elbows[1],
		"hand.L":elbows[0],"hand.R":elbows[1],
		"thigh.L":leg_left,"thigh.R":leg_right,
		"shin.L":knees[0],"shin.R":knees[1],
		"foot.L":ankles[0],"foot.R":ankles[1]}
	for key in proxy_nodes: proxy_rest[key]=global_basis.inverse()*proxy_nodes[key].global_basis
	skin_visual=load(asset_path()).instantiate()
	skin_visual.rotation.y=PI
	add_child(skin_visual)
	find_skin(skin_visual)
	assert(skin_skeleton!=null)
	for i in range(skin_skeleton.get_bone_count()):skin_rest.append(skin_skeleton.get_bone_global_rest(i).basis)
	pose(0,0,0,0,Vector2(0,-1),true)
func remove_proxy_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D: child.free()
		else: remove_proxy_meshes(child)
func find_skin(node: Node) -> void:
	if node is Skeleton3D: skin_skeleton=node
	for child in node.get_children():find_skin(child)
func pose(phase: float,movement: float,running: float,aiming: float,direction: Vector2,grounded: bool) -> void:
	super.pose(phase,movement,running,aiming,direction,grounded)
	sync_skin()
func sync_skin() -> void:
	if skin_skeleton==null:return
	var desired := []
	var conversion: Basis=skin_skeleton.global_basis.inverse()*global_basis
	for i in range(skin_skeleton.get_bone_count()):
		var key: String=skin_skeleton.get_bone_name(i)
		var delta: Basis=global_basis.inverse()*proxy_nodes[key].global_basis*proxy_rest[key].inverse()
		desired.append(conversion*delta*conversion.inverse()*skin_rest[i])
	for i in range(skin_skeleton.get_bone_count()):
		var parent: int=skin_skeleton.get_bone_parent(i)
		var parent_basis: Basis=desired[parent] if parent>=0 else Basis.IDENTITY
		var local: Basis=parent_basis.inverse()*desired[i]
		skin_skeleton.set_bone_pose_rotation(i,local.orthonormalized().get_rotation_quaternion())
	var hip: int=skin_skeleton.find_bone("pelvis")
	var shift: Vector3=pelvis.position-Vector3(0,.99,0)
	skin_skeleton.set_bone_pose_position(hip,skin_skeleton.get_bone_rest(hip).origin+conversion*shift)
	skin_skeleton.force_update_all_bone_transforms()
