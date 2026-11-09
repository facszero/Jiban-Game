extends SceneTree
var failures := 0
var meshes := 0
var triangles := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, title: String) -> void:
	print(("PASS: " if value else "FAIL: ")+title)
	if not value:
		failures+=1
func count_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		meshes+=1
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			var indices=arrays[Mesh.ARRAY_INDEX]
			triangles+=(indices.size() if indices!=null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children():
		count_meshes(child)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	game.player.health=123
	game.player.ammo=7
	var location: Vector3=game.player.position
	game.set_pause(true)
	game.open_model_review()
	var review=game.model_review
	check(paused and is_instance_valid(review),"Studio opens with gameplay paused")
	check(not game.touch_controls.is_processing_input(),"Gameplay touch input disabled in studio")
	check(review.viewport.own_world_3d,"Studio has isolated 3D world")
	count_meshes(review.model)
	print("MODEL BUDGET: %d meshes / %d triangles" % [meshes,triangles])
	check(meshes<=70 and triangles<=155000,"Model geometry budget")
	check(review.model.skin_skeleton.get_bone_count()==15,"Imported Jiban skeleton active")
	review.model.animate(PI/2,1.0,true)
	check(review.model.knees[0].rotation.x<-.5 and review.model.arm_right.rotation.x>1.0,"Knee and aiming joints animate")
	var start_yaw: float=review.yaw
	var touch := InputEventScreenTouch.new()
	touch.index=0
	touch.pressed=true
	review.orbit_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index=0
	drag.relative=Vector2(60,20)
	review.orbit_input(drag)
	check(review.yaw!=start_yaw,"Touch drag rotates studio camera")
	review.zoom(-100)
	check(review.distance==1.5,"Studio zoom clamps")
	review.close()
	await process_frame
	check(paused and not is_instance_valid(game.model_review),"Closing studio returns to pause")
	check(game.touch_controls.is_processing_input(),"Gameplay touch input restored")
	check(game.player.health==123 and game.player.ammo==7 and game.player.position.is_equal_approx(location),"Review preserves health, ammunition and position")
	game.free()
	paused=false
	print("MODEL RESULT: %d failures" % failures)
	quit(1 if failures else 0)
