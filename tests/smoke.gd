extends SceneTree

var failures := 0
var game: Node
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(20)
	var player = game.player
	check(player.is_on_floor(), "Player stands on collision floor")
	var start: Vector3 = player.position
	Input.action_press("forward")
	await frames(30)
	Input.action_release("forward")
	check(player.position.z < start.z - 0.5, "Movement input moves player forward")
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await frames(6)
	check(player.position.y > 0.15, "Jump leaves floor")
	await frames(50)
	var position_before: Vector3 = player.position
	player.first_person = true
	player.update_camera(1.0)
	check(player.camera.position == Vector3.ZERO and not player.body_model.visible, "First person hides body")
	check(player.position == position_before, "Perspective switch does not teleport player")
	player.first_person = false
	player.update_camera(1.0)
	check(player.camera.position.z > 1.0 and player.body_model.visible, "Third person stays behind body")
	# Place the camera against the rear wall; the swept sphere must retract.
	player.position = Vector3(0, 0.05, 7.0)
	await frames(3)
	check(player.camera.global_position.z < 7.75, "Camera retracts before rear wall")
	player.position = Vector3(0, 0.05, 4)
	player.pitch = 0.0
	player.first_person = true
	await frames(3)
	var target = game.level.spawn_enemy(Vector3(0, 0.1, -2))
	target.set_physics_process(false)
	await frames(3)
	var old_health: float = target.health
	player.shoot()
	check(player.ammo == 11 and target.health < old_health, "First person shot consumes ammo and damages target")
	player.first_person = false
	player.cooldown = 0.0
	await frames(3)
	player.shoot()
	check(target.health < old_health - 25.0, "Third person reticle damages the same target")
	# A solid barrier must stop damage regardless of camera visibility.
	var wall = load("res://scripts/geometry.gd").box(game, Vector3(0, 1.5, 0), Vector3(5, 3, 0.3), StandardMaterial3D.new(), true)
	await frames(3)
	old_health = target.health
	player.cooldown = 0.0
	player.shoot()
	check(target.health == old_health, "Wall blocks weapon damage")
	# Reuse the shot budget: the close wall crosses the body-to-muzzle segment.
	wall.position.z = 3.7
	await frames(3)
	player.ammo += 1
	player.cooldown = 0.0
	player.shoot()
	check(target.health == old_health, "Close wall blocks a muzzle extending beyond it")
	wall.free()
	player.reload_weapon()
	await frames(80)
	check(player.ammo == 12 and player.reserve == 69, "Reload transfers reserve into magazine")
	player.hurt_time = 0
	player.take_damage(12)
	player.take_damage(12)
	check(player.health == 168, "Damage invulnerability prevents duplicate hit")
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var hunter = game.level.spawn_enemy(Vector3(0, 0.1, -2))
	await frames(5)
	var distance_before: float = hunter.global_position.distance_to(player.global_position)
	await frames(30)
	check(hunter.global_position.distance_to(player.global_position) < distance_before, "Enemy pursues visible player")
	hunter.position = player.position + Vector3(0, 0, -1)
	player.hurt_time = 0
	await frames(5)
	check(player.health < 168, "Enemy attacks player")
	hunter.free()
	player.position = Vector3(-4, 0.05, -12.1)
	player.rotation = Vector3.ZERO
	player.pitch = -0.2
	player.first_person = true
	await frames(5)
	check(game.target_terminal == game.level.terminals[0], "Nearby aimed terminal is interactable")
	# Reproduce the mobile screenshot: stand against the terminal, looking down.
	player.position = Vector3(-4, 0.05, -14.35)
	player.pitch = -0.35
	await frames(3)
	check(player.weapon_clearance < 0.65 and not player.view_weapon.visible, "Weapon withdraws at terminal contact")
	player.position = Vector3(-4, 0.05, -12.1)
	player.pitch = -0.2
	await frames(20)
	check(player.weapon_clearance > 0.99 and player.view_weapon.visible, "Weapon returns after leaving terminal")
	var action := InputEventAction.new()
	action.action = "interact"
	action.pressed = true
	Input.parse_input_event(action)
	await frames(3)
	check(game.terminals_used == 1, "Interaction input activates aimed terminal")
	game.level.terminals[0].interact()
	check(game.terminals_used == 1, "Terminal activation is idempotent")
	game.level.terminals[1].interact()
	await frames(95)
	check(game.checkpoint and game.level.door.position.y > 8.0, "Two terminals unlock door and checkpoint")
	player.hurt_time = 0
	player.take_damage(999)
	check(paused and player.health == 0, "Death pauses game")
	game.restart_checkpoint()
	await frames(2)
	check(not paused and player.health == 180 and player.position.z < -21, "Checkpoint restores player past door")
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	game.level.exit_terminal.interact()
	check(game.finished and paused, "Elevator completes sector")
	game.restart_checkpoint()
	check(not game.finished and not game.level.exit_terminal.used, "Restart clears completed sector state")
	# Ensure controls can be initialized again on full scene restart without duplicate actions.
	var before: int = InputMap.action_get_events("fire").size()
	load("res://scripts/controls.gd").setup()
	check(InputMap.action_get_events("fire").size() == before, "Input setup is idempotent")
	print("SMOKE RESULT: ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

