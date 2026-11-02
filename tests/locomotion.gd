extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:
		failures+=1
func run() -> void:
	var model=load("res://scripts/jiban_model.gd").new()
	root.add_child(model)
	var support_error := 0.0
	var swing_lift := 0.0
	for i in range(120):
		var phase := TAU*i/120.0
		model.pose(phase,1.0,0.0,0.0,Vector2(0,-1),true)
		if float(i)/120.0<.6:
			support_error=maxf(support_error,absf(model.ankles[0].global_position.y-.155))
		else:
			swing_lift=maxf(swing_lift,model.ankles[0].global_position.y-.155)
	check(support_error<.015,"Support ankle remains at floor-relative height")
	check(swing_lift>.08,"Swing foot clears the ground")
	model.update_locomotion(.016,Vector3(0,0,-4),false,false,true)
	check(model.move_blend>0 and model.move_blend<.3,"Movement starts gradually")
	for i in range(60):
		model.update_locomotion(.016,Vector3.ZERO,false,false,true)
	check(model.move_blend<.001,"Stopped player settles without marching")
	var old_phase: float=model.locomotion_phase
	model.update_locomotion(.016,Vector3.ZERO,false,false,true)
	check(model.locomotion_phase==old_phase,"Blocked movement does not advance gait")
	for i in range(60):
		model.update_locomotion(.016,Vector3(0,0,-4),false,true,true)
	check(model.arm_right.rotation.x<-1.4,"Aim steadies weapon arm while moving")
	model.update_locomotion(.016,Vector3(2,3,0),false,false,false)
	check(absf(model.knees[0].rotation.x+.35)<.001,"Airborne pose replaces ground step")
	model.free()
	print("LOCOMOTION RESULT: %d failures" % failures)
	quit(1 if failures else 0)
