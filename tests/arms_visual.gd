extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(20):
		await process_frame
	game.open_model_review()
	var studio=game.model_review
	studio.set_process(false)
	studio.yaw=PI/2
	studio.update_camera()
	for i in range(4):
		studio.model.pose(0.0 if i%2==0 else PI,1.0,0.0,1.0 if i>=2 else 0.0,Vector2(0,-1),true)
		for f in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://exports/arms_%d.png" % i)
	game.free()
	paused=false
	quit()
