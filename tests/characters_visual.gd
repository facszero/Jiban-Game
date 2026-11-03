extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(15): await process_frame
	game.open_model_review()
	var studio=game.model_review
	for index in range(3):
		studio.select_model(index)
		for angle in range(2):
			studio.yaw=0 if angle==0 else PI/2
			studio.update_camera()
			for i in range(6): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://exports/character_%d_%d.png" % [index,angle])
	studio.select_model(2)
	studio.preview_aim=true
	studio.walking=true
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/mask_aim.png")
	game.free()
	paused=false
	quit()
