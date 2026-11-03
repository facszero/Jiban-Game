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
	check(creature.ankles.size()==2,"Feet retain articulated ankle joints")
	check(creature.wrists.size()==2,"Hands retain independent wrist joints")
	for frame in range(48):
		creature.animate(TAU*frame/48.0,1)
		for hand_index in range(2):
			var inward:=Vector3.RIGHT if hand_index==0 else Vector3.LEFT
			var palm: Vector3=-creature.wrists[hand_index].global_basis.z.normalized()
			check(palm.dot(inward)>.85,"Walking palm faces thigh")
		for ankle in creature.ankles:
			check(ankle.global_position.y>.05 and ankle.global_position.y<.23,"Walking foot stays above floor")
	creature.animate(0,0,.78)
	check(creature.elbows[1].global_position.z<creature.arms[1].global_position.z,"Strike reaches forward")
	studio.model.animate(0,0,.5)
	check(studio.model.arms[1].rotation.x>.4,"Windup visibly raises the striking arm")
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
