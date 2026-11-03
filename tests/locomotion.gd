extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:
		failures+=1
func run() -> void:
	load("res://scripts/controls.gd").setup()
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
	check(model.arm_right.rotation.x>1.4,"Aim steadies weapon arm while moving")
	model.update_locomotion(.016,Vector3(2,3,0),false,false,false)
	check(absf(model.knees[0].rotation.x+.35)<.001,"Airborne pose replaces ground step")
	for direction in [Vector2(0,1), Vector2(1,0), Vector2(-1,0), Vector2(.707,-.707)]:
		var max_error := 0.0
		for i in range(100):
			var cycle := float(i)/100.0
			model.pose(cycle*TAU,1,1,1,direction,true)
			if cycle<.42:
				max_error=maxf(max_error,absf(model.ankles[0].global_position.y-.155))
		check(max_error<.02,"Running support height in direction %s" % direction)
	var player=load("res://scripts/player.gd").new()
	root.add_child(player)
	player.set_physics_process(false)
	player.velocity=Vector3(2,0,0)
	player.update_body_heading(.016,false)
	check(player.body_model.rotation.y<0 and player.body_model.rotation.y>-.5,"Exploration turn starts smoothly toward travel")
	for i in range(90):
		player.update_body_heading(.016,false)
		player.last_visual_yaw=player.body_model.global_rotation.y
	check(absf(angle_difference(player.body_model.rotation.y,-PI/2))<.01,"Exploration faces rightward movement")
	check(player.rotation.y==0,"Body turn does not rotate camera/input root")
	for i in range(90):
		player.update_body_heading(.016,true)
		player.last_visual_yaw=player.body_model.global_rotation.y
	check(absf(player.body_model.rotation.y)<.01,"Combat restores sight-facing orientation")
	player.velocity=Vector3.ZERO
	player.last_visual_yaw=.7
	player.rotation.y=1.3
	player.update_body_heading(.016,false)
	check(absf(player.body_model.global_rotation.y-.7)<.01,"Idle body remains independent from orbiting camera")
	player.free()
	# Test the actual barrel in world space, not just joint angle signs.
	var gun: Node3D = model.elbows[1].get_node("ServicePistol")
	for run_weight in [0.0,1.0]:
		var minimum_dot := 1.0
		var left_min := INF
		var left_max := -INF
		var right_min := INF
		var right_max := -INF
		var flex_min := INF
		var flex_max := -INF
		for i in range(48):
			var phase := TAU*i/48.0
			model.pose(phase,1,run_weight,1,Vector2(0,-1),true)
			var forward: Vector3 = -model.global_basis.z
			minimum_dot=minf(minimum_dot,(-gun.global_basis.z).dot(forward))
			model.pose(phase,1,run_weight,0,Vector2(0,-1),true)
			left_min=minf(left_min,model.arm_left.rotation.x)
			left_max=maxf(left_max,model.arm_left.rotation.x)
			right_min=minf(right_min,model.arm_right.rotation.x)
			right_max=maxf(right_max,model.arm_right.rotation.x)
			flex_min=minf(flex_min,model.elbows[1].rotation.x)
			flex_max=maxf(flex_max,model.elbows[1].rotation.x)
		check(minimum_dot>.995,"Aimed barrel faces forward through complete gait, run=%s" % run_weight)
		check(left_min<-.1 and left_max>.2 and right_min<-.1 and right_max>.2,"Both arms swing forward and backward")
		check(flex_min>0 and flex_max-flex_min>.1,"Elbows bend forward and vary during stride")
	model.free()
	print("LOCOMOTION RESULT: %d failures" % failures)
	quit(1 if failures else 0)
