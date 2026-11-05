extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	for old in get_nodes_in_group("enemies"): old.free()
	var enemy=load("res://scripts/enemy.gd").new()
	enemy.heavy=true
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position=Vector3(0,.1,0)
	game.player.position=Vector3(0,.1,-2.4)
	await physics_frame
	enemy.update_heavy(1.0/60)
	check(enemy.attack_right,"First swipe uses right claw")
	var start: Vector3=enemy.position
	var health: float=game.player.health
	for i in range(100):
		await physics_frame
		game.player.hurt_time=0
		enemy.update_heavy(1.0/60)
		if enemy.attack_elapsed<0: break
	check(start.z-enemy.position.z>.55 and start.z-enemy.position.z<1.05,"Lunge advances a bounded distance")
	check(is_equal_approx(health-game.player.health,28),"Lunge hits once even without player invulnerability")
	enemy.cooldown=0
	enemy.update_heavy(1.0/60)
	check(not enemy.attack_right,"Next swipe alternates to left claw")
	# Both clips cross the body, move forward, then recover all driven joints.
	var model=enemy.model
	model.animate(0,0)
	var jaw: int=model.skeleton.find_bone("jaw")
	var jaw_rest: Quaternion=model.skeleton.get_bone_pose_rotation(jaw)
	for right in [true,false]:
		var side: String="R" if right else "L"
		model.animate(0,0,.6,right)
		var wide: Vector3=model.joint_position("hand."+side)
		model.animate(0,0,.78,right)
		var impact: Vector3=model.joint_position("hand."+side)
		model.animate(0,0,.98,right)
		var across: Vector3=model.joint_position("hand."+side)
		check(absf(across.x-wide.x)>.75,"Swipe traverses a wide lateral arc: "+side)
		check(impact.z<wide.z-.25,"Claw passes in front of chest: "+side)
		model.animate(0,0,-1,right)
		check(model.skeleton.get_bone_pose_rotation(jaw).angle_to(jaw_rest)<.001,"Cancelled swipe closes jaw: "+side)
	# Fixed windup direction does not track a sidestep.
	enemy.position=Vector3(0,.1,0)
	enemy.rotation.y=0
	enemy.attack_elapsed=0
	enemy.attack_hit=false
	game.player.position=Vector3(2,.1,0)
	health=game.player.health
	for i in range(90):
		await physics_frame
		game.player.hurt_time=0
		enemy.update_heavy(1.0/60)
		if enemy.attack_elapsed<0: break
	check(is_equal_approx(game.player.health,health),"Committed lunge can be sidestepped")
	# Collision movement and sight check prevent charging or hitting through a wall.
	enemy.position=Vector3(0,.1,0)
	enemy.rotation.y=0
	enemy.velocity=Vector3.ZERO
	enemy.attack_elapsed=0
	enemy.attack_hit=false
	game.player.position=Vector3(0,.1,-1.6)
	var wall=load("res://scripts/geometry.gd").box(game,Vector3(0,1,-.8),Vector3(3,2,.15),StandardMaterial3D.new(),true)
	await physics_frame
	for i in range(90):
		await physics_frame
		game.player.hurt_time=0
		enemy.update_heavy(1.0/60)
		if enemy.attack_elapsed<0: break
	check(enemy.position.z>-.25,"Wall blocks lunge movement")
	check(is_equal_approx(game.player.health,health),"Wall blocks claw damage")
	wall.free()
	game.free()
	paused=false
	print("HEAVY SWIPES RESULT: %d failures" % failures)
	quit(1 if failures else 0)

