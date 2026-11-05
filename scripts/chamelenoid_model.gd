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
		for expected in ["Idle", "Walk", "Attack"]:
			if String(key).ends_with(expected): clips[expected] = key
	assert(clips.size() == 3)
	animate(0, 0)
func find_rig(node: Node) -> void:
	if node is Skeleton3D: skeleton = node
	if node is AnimationPlayer: player = node
	for child in node.get_children(): find_rig(child)
func animate(phase: float, movement: float, attack_time: float = -1.0) -> void:
	if player == null: return
	var clip: String = "Attack" if attack_time >= 0.0 else ("Walk" if movement > .01 else "Idle")
	var key: String = clips[clip]
	var duration := player.get_animation(key).length
	var time := clampf(attack_time, 0, duration) if clip == "Attack" else fposmod(phase / TAU, 1.0) * duration
	player.play(key)
	player.seek(time, true)
	skeleton.force_update_all_bone_transforms()
func joint_position(bone_name: String) -> Vector3:
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin))

