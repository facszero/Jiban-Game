extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/"+name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	game.player.set_physics_process(false)
	game.set_process(false)
	game.health_bar.value=180
	game.energy_bar.value=120
	game.player.first_person=true
	var fx=game.level.effects
	fx.set_process(false)
	game.player.position=Vector3(-2,.05,-22.8)
	game.player.pitch=-.08
	game.player.update_camera(1)
	for i in range(30): await process_frame
	fx.start_vent(0)
	for i in range(60): fx.advance(.016)
	await capture("effects_vapor")
	game.player.position=Vector3(-3.5,.05,-36.8)
	game.player.pitch=.25
	game.player.update_camera(1)
	fx.fire_arc()
	fx.advance(.02)
	await capture("effects_arc")
	game.player.position=Vector3(0,.05,-15.8)
	game.player.pitch=-.15
	game.player.update_camera(1)
	game.level.open_door()
	for i in range(45):
		fx.advance(.016)
		await process_frame
	await capture("effects_door")
	quit()
