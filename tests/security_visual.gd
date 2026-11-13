extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/"+path+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.player.set_physics_process(false)
	game.set_process(false)
	game.health_bar.value=180
	game.energy_bar.value=120
	game.objective_label.text="SECTOR 01 / ACCESO\nACTIVAR LAS DOS TERMINALES DE SEGURIDAD"
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	game.player.first_person=true
	game.player.position=Vector3(-.9,.05,-11.5)
	game.player.pitch=0
	game.player.update_camera(1.0)
	await capture("security_overview")
	game.player.position=Vector3(-4,.05,-13.3)
	game.player.pitch=-.16
	game.player.update_camera(1.0)
	await capture("security_console")
	game.level.terminals[0].interact()
	await capture("security_console_active")
	game.level.terminals[1].interact()
	await create_timer(1.6).timeout
	game.player.position=Vector3(-.9,.05,-11.5)
	game.player.pitch=0
	game.player.update_camera(1.0)
	await capture("security_open")
	quit()
