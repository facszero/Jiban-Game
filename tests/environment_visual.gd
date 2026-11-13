extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.player.set_physics_process(false)
	game.set_process(false)
	game.health_bar.value=180
	game.energy_bar.value=120
	game.objective_label.text="SECTOR 01 / ACCESO"
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	game.player.first_person=true
	game.player.position=Vector3(0,.05,-24)
	game.player.pitch=0
	game.player.update_camera(1.0)
	var enemy=game.level.spawn_enemy(Vector3(-.8,.05,-26.4))
	enemy.set_physics_process(false)
	enemy.rotation.y=PI
	enemy.state="ATACANDO"
	enemy.animate_model(1.0)
	var heavy=game.level.spawn_enemy(Vector3(0,.05,-47),true)
	heavy.set_physics_process(false)
	heavy.rotation.y=PI
	for i in range(50): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/environment_lab.png")
	print("ENVIRONMENT draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," objects=",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	game.player.position=Vector3(0,.05,2)
	game.player.update_camera(1.0)
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/environment_entry.png")
	quit()
