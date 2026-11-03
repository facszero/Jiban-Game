extends SceneTree
var failures:=0
var meshes:=0
var triangles:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func count(node: Node) -> void:
	if node is MeshInstance3D:
		meshes+=1
		for i in range(node.mesh.get_surface_count()):
			var a=node.mesh.surface_get_arrays(i)
			triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null and a[Mesh.ARRAY_INDEX].size()>0 else a[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children(): count(child)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	game.set_pause(true)
	game.open_model_review()
	game.model_review.select_model(2)
	var model=game.model_review.model
	check(model.get_script()==load("res://scripts/mask_model.gd"),"Mask selectable in studio")
	count(model)
	print("MASK BUDGET: %d meshes / %d triangles" % [meshes,triangles])
	check(meshes<65 and triangles<22000,"Mask geometry budget")
	check(model.ankles.size()==2 and is_instance_valid(model.ankles[0]),"Ankle joints survive batching")
	for i in range(24): model.pose(TAU*i/24,1,0,0,Vector2(0,-1),true)
	model.pose(0,0,0,1,Vector2(0,-1),true)
	var gun=model.elbows[1].get_node("ServicePistol")
	check((-gun.global_basis.z).dot(Vector3.FORWARD)>.99,"Mask weapon points forward")
	var mask_enemy: Node3D
	for enemy in get_nodes_in_group("enemies"):
		if not enemy.heavy: mask_enemy=enemy; break
	check(mask_enemy!=null and mask_enemy.model.get_script()==load("res://scripts/mask_model.gd"),"Generic enemies use new Mask")
	mask_enemy.take_damage(25)
	check(mask_enemy.health==50,"Damage preserved")
	mask_enemy.hit_flash=.06
	mask_enemy.animate_model(.016)
	check(absf(mask_enemy.model.upper_body.rotation.x)>.05,"Impact pose updates")
	game.queue_free()
	await process_frame
	paused=false
	print("MASK RESULT: %d failures" % failures)
	quit(1 if failures else 0)
