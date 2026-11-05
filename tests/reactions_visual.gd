extends SceneTree
func _initialize(): call_deferred("run")
func snap(path: String):
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/"+path+".png")
func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(15): await process_frame
	game.open_model_review()
	game.model_review.select_model(1)
	game.model_review.set_process(false)
	var model=game.model_review.model
	for frame in range(4):
		model.animate(frame*PI/2,1)
		await snap("heavy_walk_"+str(frame))
	model.animate(0,0,-1,true,.11)
	await snap("light_hit")
	model.animate(0,0,-1,true,-1,.35)
	await snap("stagger")
	for t in [.4,.9,1.8]:
		model.animate(0,0,-1,true,-1,-1,t)
		await snap("death_"+str(t))
	game.free()
	paused=false
	quit()
