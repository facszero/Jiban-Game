extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(20):
		await process_frame
	game.open_model_review()
	game.model_review.select_model(1)
	await snap("res://exports/cham_front.png")
	game.model_review.yaw=PI
	game.model_review.update_camera()
	await snap("res://exports/cham_back.png")
	game.model_review.yaw=-.35
	game.model_review.update_camera()
	game.model_review.set_process(false)
	game.model_review.model.animate(0,0,.6)
	await snap("res://exports/cham_attack.png")
	game.model_review.model.animate(0,0,.78)
	await snap("res://exports/cham_impact.png")
	game.model_review.model.animate(PI/2,1)
	game.model_review.yaw=PI/2
	game.model_review.update_camera()
	await snap("res://exports/cham_walk_profile.png")
	game.model_review.model.animate(0,0,-1)
	await snap("res://exports/cham_rest_profile.png")
	game.model_review.close()
	game.set_pause(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	game.player.position=Vector3(0,.1,3.5)
	game.player.first_person=true
	var creature=load("res://scripts/enemy.gd").new()
	creature.heavy=true
	game.add_child(creature)
	creature.position=Vector3(0,.1,-.5)
	creature.rotation.y=PI
	creature.set_physics_process(false)
	await snap("res://exports/cham_corridor.png")
	game.free()
	paused=false
	quit()
