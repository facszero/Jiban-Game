extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run")
func verify(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
	else:
		print("PASS: ", message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var touch = load("res://scripts/touch_controls.gd").new()
	touch.force_visible = true
	game.add_child(touch)
	await process_frame
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(125, 460) * root.get_visible_rect().size / Vector2(1280, 720)
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	verify(Input.is_action_pressed("forward"), "Touch movement press")
	press = press.duplicate()
	press.pressed = false
	root.push_input(press, true)
	await process_frame
	verify(not Input.is_action_pressed("forward"), "Touch movement release")
	var old_yaw: float = game.player.rotation.y
	var look := InputEventScreenTouch.new()
	look.index = 1
	look.position = Vector2(800, 350)
	look.pressed = true
	root.push_input(look, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(840, 350)
	drag.relative = Vector2(40, 0)
	root.push_input(drag, true)
	await process_frame
	verify(game.player.rotation.y != old_yaw, "Touch drag turns camera")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
