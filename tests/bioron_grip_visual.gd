extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var stage=Node3D.new()
	root.add_child(stage)
	var model=load("res://scripts/bioron_meshy_model.gd").new()
	stage.add_child(model)
	var scale_factor=2.5/1.95
	model.scale=Vector3.ONE*scale_factor
	model.position.y=0
	model.rotation.y=PI
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color(.045,.05,.048)
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color(.85,.85,.82)
	e.ambient_light_energy=.45
	var sky=Sky.new()
	var sky_material=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color(.55,.60,.68)
	sky_material.sky_horizon_color=Color(.8,.8,.8)
	sky_material.ground_bottom_color=Color(.18,.19,.22)
	sky_material.ground_horizon_color=Color(.8,.8,.8)
	sky.sky_material=sky_material
	e.sky=sky
	e.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	env.environment=e
	stage.add_child(env)
	for spec in [[Vector3(-35,-30,0),Color(1,.95,.88),1.2],[Vector3(-20,135,0),Color(.75,.82,1),.6],[Vector3(-10,210,0),Color(1,.72,.5),.7]]:
		var light=DirectionalLight3D.new()
		stage.add_child(light)
		light.rotation_degrees=spec[0]
		light.light_color=spec[1]
		light.light_energy=spec[2]
	var camera=Camera3D.new()
	stage.add_child(camera)
	camera.fov=38
	camera.current=true
	camera.position=Vector3(1.5,1.6,4.2)
	camera.look_at(Vector3(0,1.25,0))
	model.pose(0,0,0,1,Vector2(0,-1),true)
	for i in range(5):await process_frame
	var center: Vector3=model.held_pistol.to_global(Vector3(0,-.05,.03))
	for view in [["front",Vector3(.36,.18,.50)],["left",Vector3(-.40,.12,.40)],["back",Vector3(.40,.15,-.35)]]:
		camera.position=center+view[1]
		camera.look_at(center)
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://exports/bioron_grip_"+view[0]+".png")
	stage.free()
	quit()
