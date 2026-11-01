extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30):
		await process_frame
	game.open_model_review()
	for i in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://exports")
	root.get_texture().get_image().save_png("res://exports/model_front.png")
	game.model_review.yaw=PI
	game.model_review.update_camera()
	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/model_back.png")
	game.model_review.close()
	game.set_pause(false)
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/model_corridor.png")
	game.free()
	quit()
