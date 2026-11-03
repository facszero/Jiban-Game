extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	game.set_pause(true)
	game.open_model_review()
	var studio=game.model_review
	studio.select_model(3)
	var cast=studio.model.characters
	check(cast.size()==3,"Three characters share one stage")
	var heavy=load("res://scripts/enemy.gd").new()
	heavy.heavy=true
	game.add_child(heavy)
	heavy.set_physics_process(false)
	check(heavy!=null and cast[2].scale.is_equal_approx(heavy.model.scale),"Comparison uses gameplay scale")
	check(cast[2].torso.scale.x>1.2,"Chamelenoid broader torso")
	check(absf(cast[2].head.global_basis.x.length()-1.1)<.01,"Head retains proportions")
	for i in range(3): check(is_zero_approx(cast[i].position.y),"Common floor")
	studio.walking=true
	for i in range(10): await process_frame
	studio.select_model(0)
	studio.select_model(1)
	studio.select_model(3)
	check(paused,"Review keeps gameplay paused")
	game.free()
	paused=false
	print("COMPARISON RESULT: %d failures" % failures)
	quit(1 if failures else 0)
