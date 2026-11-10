extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_process(false)
	var player=game.player
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.free()
	player.first_person=true
	player.pitch=0
	player.rotation.y=0
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	player.capture_mouse()
	var motion=InputEventMouseMotion.new()
	motion.relative=Vector2(900,900)
	motion.screen_relative=Vector2(900,900)
	player._unhandled_input(motion)
	check(is_zero_approx(player.pitch) and is_zero_approx(player.rotation.y),"Capture recenter event does not turn camera")
	player._unhandled_input(motion)
	check(is_zero_approx(player.pitch),"Capture settling ignores queued motion")
	player.mouse_settle_until=0
	motion.relative=Vector2(200,100)
	motion.screen_relative=Vector2(20,10)
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,-10*player.sensitivity),"Aim uses unscaled screen movement")
	check(is_equal_approx(player.rotation.y,-20*player.sensitivity),"Horizontal aim uses the same scale")
	var before: float=player.pitch
	player.capture_mouse()
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,before-10*player.sensitivity),"Repeated capture during clicks does not interrupt normal aim")
	before=player.pitch
	player.update_camera(0.016)
	for i in range(3):
		player.cooldown=0
		player.shoot()
	check(is_equal_approx(player.pitch,before),"Firing preserves intended pitch")
	await process_frame
	player.pitch=0
	player.rotation.y=0
	motion.screen_relative=Vector2(4000,4000)
	for i in range(20):player._unhandled_input(motion)
	check(absf(player.pitch)<=.16001 and absf(player.rotation.y)<=.30001,"Large mouse event bursts cannot snap aim to floor or ceiling")
	before=player.pitch
	await process_frame
	check(is_equal_approx(player.pitch,before),"Excess mouse movement is discarded, not replayed later")
	motion.screen_relative=Vector2(20,10)
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,before-10*player.sensitivity),"Normal aim resumes immediately after a spike")
	before=player.pitch
	game.set_pause(true)
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,before),"Paused mouse movement does not aim")
	game.set_pause(false)
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,before),"Resume ignores the capture transition")
	player._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	player._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	player._unhandled_input(motion)
	check(is_equal_approx(player.pitch,before),"Focus return cannot apply queued camera jump")
	game.free()
	paused=false
	print("INPUT STABILITY RESULT: %d failures" % failures)
	quit(1 if failures else 0)
