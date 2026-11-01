extends CanvasLayer
signal closed
var model: Node3D
var camera: Camera3D
var viewport: SubViewport
var yaw := -.35
var pitch := .08
var distance := 3.65
var walking := false
var spinning := false
var phase := 0.0
var drag_finger := -1
var dragging := false
var spin_toggle: CheckButton
func _ready() -> void:
	layer=20
	process_mode=Node.PROCESS_MODE_ALWAYS
	var frame := Control.new()
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var display := TextureRect.new()
	frame.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.mouse_filter=Control.MOUSE_FILTER_STOP
	display.gui_input.connect(orbit_input)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X
	add_child(viewport)
	display.texture=viewport.get_texture()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(.025,.038,.055)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.72,.8,.95)
	env.ambient_light_energy=.6
	world.environment=env
	viewport.add_child(world)
	for spec in [[Vector3(-35,-35,0),Color(.85,.92,1),1.8],[Vector3(-15,140,0),Color(.45,.65,1),1.6],[Vector3(15,55,0),Color(1,.7,.5),.65]]:
		var light := DirectionalLight3D.new()
		viewport.add_child(light)
		light.rotation_degrees=spec[0]
		light.light_color=spec[1]
		light.light_energy=spec[2]
	model=preload("res://scripts/jiban_model.gd").new()
	viewport.add_child(model)
	camera=Camera3D.new()
	viewport.add_child(camera)
	camera.fov=42
	camera.current=true
	update_camera()
	var title := Label.new()
	frame.add_child(title)
	title.position=Vector2(30,24)
	title.text="JIBAN / ESTUDIO DE ARMADURA\nModelo 3D · primera revisión"
	title.add_theme_font_size_override("font_size",23)
	title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var exit_button := Button.new()
	frame.add_child(exit_button)
	exit_button.text="VOLVER A PAUSA"
	exit_button.position=Vector2(1030,24)
	exit_button.size=Vector2(220,55)
	exit_button.pressed.connect(close)
	var bar := HBoxContainer.new()
	frame.add_child(bar)
	bar.position=Vector2(30,625)
	bar.add_theme_constant_override("separation",12)
	for item in [["FRENTE",0.0],["PERFIL",PI/2],["ESPALDA",PI]]:
		var button := Button.new()
		bar.add_child(button)
		button.text=item[0]
		button.custom_minimum_size=Vector2(130,52)
		button.pressed.connect(func(): yaw=item[1]; pitch=.08; stop_spin(); update_camera())
	var walk := CheckButton.new()
	bar.add_child(walk)
	walk.text="CAMINAR"
	walk.toggled.connect(func(value): walking=value)
	spin_toggle=CheckButton.new()
	bar.add_child(spin_toggle)
	spin_toggle.text="GIRAR"
	spin_toggle.toggled.connect(func(value): spinning=value)
	for item in [["−",.3],["+",-.3]]:
		var button := Button.new()
		bar.add_child(button)
		button.text=item[0]
		button.custom_minimum_size=Vector2(60,52)
		button.pressed.connect(func(): zoom(item[1]))
	var help := Label.new()
	frame.add_child(help)
	help.position=Vector2(30,686)
	help.text="Arrastrá para girar · + / − para acercar · la partida permanece en pausa"
	help.mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_camera() -> void:
	var target := Vector3(0,1.05,0)
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*distance
	camera.look_at(target)
func zoom(amount: float) -> void:
	distance=clampf(distance+amount,1.5,4.5)
	update_camera()
func stop_spin() -> void:
	spinning=false
	spin_toggle.set_pressed_no_signal(false)
func orbit_input(event: InputEvent) -> void:
	var movement := Vector2.ZERO
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom(-.2)
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom(.2)
	if event is InputEventMouseMotion and dragging:
		movement=event.relative
	if event is InputEventScreenTouch:
		if event.pressed and drag_finger==-1:
			drag_finger=event.index
		elif not event.pressed and drag_finger==event.index:
			drag_finger=-1
	if event is InputEventScreenDrag and event.index==drag_finger:
		movement=event.relative
	if movement!=Vector2.ZERO:
		yaw-=movement.x*.008
		pitch=clampf(pitch+movement.y*.006,-.45,.65)
		stop_spin()
		update_camera()
func _process(delta: float) -> void:
	phase+=delta*5.0
	model.animate(phase,1.0 if walking else 0.0,false)
	if spinning:
		yaw+=delta*.4
		update_camera()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		close()
func close() -> void:
	closed.emit()
	queue_free()
