extends Node3D
## Reconstructed sculpt, sampled against the combat clock.
const GAME_SCALE := 1.1
const GAIT_PER_METER := 4.5
const ASSET = preload("res://assets/chamelenoid/chamelenoid.glb")
var skeleton: Skeleton3D
var player: AnimationPlayer
var clips := {}
var visual: Node3D
func _ready() -> void:
	visual = ASSET.instantiate()
	visual.rotation.y = PI
	visual.scale = Vector3.ONE * .86
	add_child(visual)
	find_rig(visual)
	assert(skeleton != null and player != null)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for key in player.get_animation_list():
		for expected in ["Idle", "Walk", "AttackRight", "AttackLeft", "Stagger", "Death"]:
			if String(key).ends_with(expected): clips[expected] = key
	assert(clips.size() == 6)
	animate(0, 0)
func find_rig(node: Node) -> void:
	if node is Skeleton3D: skeleton = node
	if node is AnimationPlayer: player = node
	for child in node.get_children(): find_rig(child)
func animate(phase: float, movement: float, attack_time: float = -1.0, attack_right: bool = true, hit_time: float = -1.0, stagger_time: float = -1.0, death_time: float = -1.0) -> void:
	if player == null: return
	var clip: String = ("AttackRight" if attack_right else "AttackLeft") if attack_time >= 0.0 else ("Walk" if movement > .01 else "Idle")
	if stagger_time >= 0: clip = "Stagger"
	if death_time >= 0: clip = "Death"
	var key: String = clips[clip]
	var duration := player.get_animation(key).length
	var time := clampf(attack_time, 0, duration) if clip.begins_with("Attack") else fposmod(phase / TAU, 1.0) * duration
	if clip == "Stagger": time = clampf(stagger_time,0,duration)
	if clip == "Death": time = clampf(death_time,0,duration)
	player.play(key)
	player.seek(time, true)
	if hit_time >= 0 and stagger_time < 0 and death_time < 0:
		var recoil := sin(PI*clampf(hit_time/.22,0,1))
		var chest := skeleton.find_bone("chest")
		var head := skeleton.find_bone("head")
		skeleton.set_bone_pose_rotation(chest,skeleton.get_bone_pose_rotation(chest)*Quaternion(Vector3.RIGHT,-.12*recoil))
		skeleton.set_bone_pose_rotation(head,skeleton.get_bone_pose_rotation(head)*Quaternion(Vector3.RIGHT,.07*recoil))
	skeleton.force_update_all_bone_transforms()
func joint_position(bone_name: String) -> Vector3:
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin))

