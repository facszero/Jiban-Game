extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	await physics_frame
	await physics_frame
	var space=game.get_world_3d().direct_space_state
	var route=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.5,-23),Vector3(0,1.5,-51),1))
	check(route.is_empty(),"Lab center route remains unobstructed")
	for x in [-5.8,5.8]:
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,1.8,-23),Vector3(x,1.8,-29),1))
		check(not hit.is_empty(),"Containment glass has solid collision")
	check(get_nodes_in_group("enemies").is_empty(),"Display specimens do not enter combat or block progression")
	check(game.level.terminals.size()==2 and game.level.exit_terminal!=null,"Interactive consoles remain available")
	check(game.level.get_node_or_null("IndustrialSector")!=null,"Industrial dressing loaded")
	print("ENVIRONMENT RESULT: ",failures," failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
