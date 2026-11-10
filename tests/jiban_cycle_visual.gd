extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720)
	for row in range(2):
		for frame in range(6):
			var viewport=SubViewport.new()
			viewport.size=Vector2i(213,360)
			viewport.own_world_3d=true
			viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var stage=Node3D.new()
			viewport.add_child(stage)
			var model=load("res://scripts/jiban_meshy_model.gd").new()
			stage.add_child(model)
			model.rotation.y=PI
			model.pose(TAU*frame/6.0,1,0,0,Vector2(0,-1),true)
			var env=WorldEnvironment.new()
			var environment=Environment.new()
			environment.background_mode=Environment.BG_COLOR
			environment.background_color=Color(.08,.09,.10)
			environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
			environment.ambient_light_energy=.7
			preload("res://scripts/character_reflections.gd").apply(environment)
			env.environment=environment
			stage.add_child(env)
			var light=DirectionalLight3D.new()
			stage.add_child(light)
			light.rotation_degrees=Vector3(-35,-30,0)
			light.light_energy=1.2
			var fill=DirectionalLight3D.new()
			stage.add_child(fill)
			fill.rotation_degrees=Vector3(-30,120,0)
			fill.light_energy=.8
			var camera=Camera3D.new()
			stage.add_child(camera)
			camera.position=Vector3(.1,1.1,3.2) if row==0 else Vector3(3.2,1.1,.1)
			camera.look_at(Vector3(0,.95,0))
			camera.fov=38
			camera.current=true
			var screen=TextureRect.new()
			root.add_child(screen)
			screen.position=Vector2(frame*213,row*360)
			screen.size=Vector2(213,360)
			screen.texture=viewport.get_texture()
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/jiban_gait_cycle.png")
	quit()
