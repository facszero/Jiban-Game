extends SceneTree
var failures := 0
var shot_origin := Vector3.ZERO
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	var player = game.player
	player.set_physics_process(false)
	player.position = Vector3(0, 30, 0)
	player.first_person = true
	player.fired.connect(func(origin, _target): shot_origin = origin)
	for angle in [-0.8, 0.0, 0.8]:
		player.pitch = angle
		player.rotation.y = angle
		player.update_camera(1.0)
		player.cooldown = 0
		player.shoot()
		check(shot_origin.distance_to(player.view_pistol.muzzle.global_position) < 0.0001, "Shot starts at barrel with pitch/yaw %s" % angle)
		check(player.flash.global_position.distance_to(shot_origin) < 0.0001, "Flash matches barrel")
	player.view_weapon.position *= 0.75
	player.view_weapon.scale = Vector3.ONE * 0.75
	player.cooldown = 0
	player.shoot()
	check(shot_origin.distance_to(player.view_pistol.muzzle.global_position) < 0.0001, "Retracted weapon keeps aligned shot")
	player.first_person = false
	player.update_camera(1.0)
	player.cooldown = 0
	player.shoot()
	var body_origin: Vector3 = player.global_position + player.global_basis * Vector3(0.32, 1.45, -0.5)
	check(shot_origin.distance_to(body_origin) < 0.0001, "Third-person origin preserved")
	game.queue_free()
	await process_frame
	print("MUZZLE RESULT: %d failures" % failures)
	quit(1 if failures else 0)
