extends SceneTree
var failures := 0
var mesh_count := 0
var triangle_count := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, title: String) -> void:
	print(("PASS: " if value else "FAIL: ")+title)
	if not value:
		failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var enemy=load("res://scripts/enemy.gd").new()
	enemy.heavy=true
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position=Vector3(0,.1,0)
	game.player.position=Vector3(0,.1,-1.6)
	await physics_frame
	await process_frame
	enemy.update_heavy(.01)
	check(enemy.state=="PREPARANDO","Close range starts windup")
	enemy.update_heavy(.5)
	check(game.player.health==180,"Windup does not deal instant damage")
	enemy.update_heavy(.29)
	check(game.player.health==152,"Swipe deals damage at impact")
	game.player.hurt_time=0
	enemy.update_heavy(.2)
	check(game.player.health==152,"Single damage event per swipe")
	check(enemy.state=="RECUPERANDO","Recovery separates attacks")
	enemy.attack_elapsed=.5
	enemy.attack_hit=false
	game.player.position=Vector3(0,.1,-3.1)
	await physics_frame
	await process_frame
	enemy.update_heavy(.3)
	check(game.player.health==152,"Retreat evades the impact")
	enemy.attack_elapsed=.5
	enemy.attack_hit=false
	game.player.position=Vector3(1.6,.1,0)
	await physics_frame
	await process_frame
	enemy.update_heavy(.3)
	check(game.player.health==152,"Side step evades committed swipe")
	enemy.attack_elapsed=.5
	enemy.attack_hit=false
	game.player.position=Vector3(0,.1,-1.6)
	var wall=load("res://scripts/geometry.gd").box(game,Vector3(0,1,-.8),Vector3(3,2,.15),StandardMaterial3D.new(),true)
	await physics_frame
	await process_frame
	enemy.update_heavy(.3)
	check(game.player.health==152,"Wall blocks an ongoing swipe")
	wall.free()
	# Studio uses the same creature with working preview and safe model switching.
	game.open_model_review()
	var studio=game.model_review
	studio.select_model(1)
	check(studio.model.get_script()==enemy.model.get_script(),"Studio and combat share creature model")
	measure(studio.model)
	print("CHAMELENOID BUDGET: %d meshes / %d triangles" % [mesh_count,triangle_count])
	check(mesh_count<=70 and triangle_count<=35000,"Creature geometry stays in budget")
	var creature=studio.model
	check(creature.skeleton.get_bone_count()==16,"Imported skeleton has all joints")
	check(creature.clips.size()==6,"Locomotion, swipes and reactions imported")
	creature.animate(0,0)
	var rest_hand: Vector3=creature.joint_position("hand.R")
	var rest_hip: Vector3=creature.joint_position("thigh.R")
	var jaw_id: int=creature.skeleton.find_bone("jaw")
	var rest_jaw: Quaternion=creature.skeleton.get_bone_pose_rotation(jaw_id)
	creature.animate(0,0,.78)
	check(creature.joint_position("hand.R").z<rest_hand.z-.3,"Strike reaches forward")
	check(creature.joint_position("thigh.R").distance_to(rest_hip)<.001,"Attack leaves hip anchored")
	check(creature.skeleton.get_bone_pose_rotation(jaw_id).angle_to(rest_jaw)>.4,"Impact opens jaw")
	creature.animate(0,0,-1)
	check(creature.skeleton.get_bone_pose_rotation(jaw_id).angle_to(rest_jaw)<.001,"Interrupted attack restores jaw")
	check(creature.joint_position("hand.R").distance_to(rest_hand)<.001,"Interrupted attack restores arm")
	creature.animate(0,0,.78)
	creature.animate(0,0,1.5)
	check(creature.skeleton.get_bone_pose_rotation(jaw_id).angle_to(rest_jaw)<.001,"Completed attack restores jaw")
	creature.animate(0,1)
	var walk_start: Vector3=creature.joint_position("foot.R")
	creature.animate(PI/2,1)
	check(creature.joint_position("foot.R").distance_to(walk_start)>.05,"Walking articulates feet")
	for frame in range(48):
		creature.animate(TAU*frame/48.0,1)
		for side in ["L","R"]:
			check(creature.joint_position("foot."+side).y>.04,"Walking ankles remain above floor")
	studio.select_model(0)
	check(not studio.creature_selected and paused,"Switching model preserves pause")
	studio.close()
	await process_frame
	game.free()
	paused=false
	print("CHAMELENOID RESULT: %d failures" % failures)
	quit(1 if failures else 0)

func measure(node: Node) -> void:
	if node is MeshInstance3D:
		mesh_count+=1
		for i in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(i)
			var indices=arrays[Mesh.ARRAY_INDEX]
			triangle_count+=(indices.size() if indices!=null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children():
		measure(child)


