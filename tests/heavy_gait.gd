extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run():
	var model=load("res://scripts/chamelenoid_model.gd").new()
	root.add_child(model)
	model.scale=Vector3.ONE*model.GAME_SCALE
	model.animate(TAU*.08,1)
	var planted: Vector3=model.to_global(model.joint_position("foot.L"))
	var traveled: float=TAU*(.38-.08)/model.GAIT_PER_METER
	model.position.z-=traveled
	model.animate(TAU*.38,1)
	var next: Vector3=model.to_global(model.joint_position("foot.L"))
	check(absf(next.z-planted.z)<.025,"Planted foot tracks travel within 2.5 cm")
	check(absf(next.y-planted.y)<.015,"Support foot remains level")
	model.animate(TAU*.78,1)
	var raised: Vector3=model.to_global(model.joint_position("foot.L"))
	check(raised.y-planted.y>.12,"Swing foot clears the floor by more than 12 cm")
	model.free()
	print("HEAVY GAIT RESULT: %d failures" % failures)
	quit(1 if failures else 0)
