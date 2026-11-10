extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const Controls = preload("res://scripts/controls.gd")
const Player = preload("res://scripts/player.gd")
const Level = preload("res://scripts/level.gd")
var player: CharacterBody3D
var level: Node3D
var hud: Label
var objective_label: Label
var hint: Label
var ammo_label: Label
var health_bar: ProgressBar
var energy_bar: ProgressBar
var overlay: ColorRect
var menu: VBoxContainer
var status: Label
var resume_button: Button
var target_terminal: Node
var terminals_used := 0
var checkpoint := false
var finished := false
var objective := "ACTIVAR LAS DOS TERMINALES DE SEGURIDAD"
var notice := "BIORON // Señal de Giba detectada"
var notice_time := 5.0
var audio: AudioStreamPlayer
var sound: AudioStreamWAV
var model_review: CanvasLayer
var touch_controls: CanvasLayer
var phase_events := [false, false, false]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.setup()
	setup_environment()
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.position = Vector3(0, 0.1, 4)
	player.fired.connect(on_shot)
	player.died.connect(on_death)
	level = Level.new()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	for terminal in level.terminals:
		terminal.activated.connect(on_terminal)
	level.exit_terminal.activated.connect(on_exit)
	level.spawn_enemy(Vector3(0, 0.1, -11))
	create_hud()
	touch_controls = preload("res://scripts/touch_controls.gd").new()
	add_child(touch_controls)
	create_sound()
	create_ambience()
	if not OS.has_feature("web"):
		player.capture_mouse()

func setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.005, 0.01, 0.025)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.55, 0.7)
	environment.ambient_light_energy = 0.65
	preload("res://scripts/character_reflections.gd").apply(environment)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(-35, -25, 0)
	fill.light_color = Color(0.6, 0.75, 1.0)
	fill.light_energy = 0.8

func text_label(parent: Node, position: Vector2, size: int, color := Color(0.7, 0.85, 0.95)) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func create_hud() -> void:
	var touch := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_environment("JIBAN_TOUCH_PREVIEW")
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var frame := Control.new()
	canvas.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner := ColorRect.new()
	frame.add_child(banner)
	banner.color = Color(0.01, 0.025, 0.045, 0.85)
	banner.size = Vector2(1280, 110)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = text_label(frame, Vector2(30, 20), 24)
	hud.text = "JIBAN // SISTEMAS OPERATIVOS"
	var version_label := text_label(frame, Vector2(355, 77), 14)
	version_label.text = "v0.10.2-prueba"
	for i in range(2):
		var bar := ProgressBar.new()
		frame.add_child(bar)
		bar.position = Vector2(30, 55 + i * 21)
		bar.size = Vector2(310, 13)
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.9, 0.05, 0.08) if i == 0 else Color(0.1, 0.6, 0.95)
		bar.add_theme_stylebox_override("fill", fill)
		bar.max_value = 180.0 if i == 0 else 120.0
		if i == 0:
			health_bar = bar
		else:
			energy_bar = bar
	objective_label = text_label(frame, Vector2(620, 25), 18)
	objective_label.size = Vector2(490, 75)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var reticle := text_label(frame, Vector2(630, 343), 26, Color(0.7, 0.95, 1, 0.85))
	reticle.text = "+"
	hint = text_label(frame, Vector2(320, 545) if touch else Vector2(30, 605), 19)
	if touch:
		hint.size = Vector2(620, 55)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ammo_label = text_label(frame, Vector2(440, 610) if touch else Vector2(920, 610), 22)
	if touch:
		ammo_label.size = Vector2(400, 60)
		ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := text_label(frame, Vector2(30, 680), 15, Color(0.4, 0.6, 0.7))
	controls.visible = not touch
	controls.text = "WASD Mover   ·   Ratón Apuntar   ·   V Cámara   ·   E Terminal   ·   R Recargar   ·   F Linterna   ·   Esc Pausa"
	overlay = ColorRect.new()
	frame.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.003, 0.01, 0.025, 0.94)
	overlay.visible = false
	menu = VBoxContainer.new()
	overlay.add_child(menu)
	menu.position = Vector2(390, 210)
	menu.size = Vector2(500, 320)
	menu.add_theme_constant_override("separation", 20)
	status = Label.new()
	menu.add_child(status)
	status.add_theme_font_size_override("font_size", 28)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_button = Button.new()
	menu.add_child(resume_button)
	resume_button.text = "CONTINUAR"
	resume_button.pressed.connect(func(): set_pause(false))
	var restart := Button.new()
	menu.add_child(restart)
	restart.text = "REINICIAR DESDE PUNTO DE CONTROL"
	restart.pressed.connect(restart_checkpoint)
	var review_button := Button.new()
	menu.add_child(review_button)
	review_button.text = "VER MODELOS 3D"
	review_button.custom_minimum_size.y = 48
	review_button.pressed.connect(open_model_review)
	var sensitivity := HSlider.new()
	menu.add_child(sensitivity)
	sensitivity.min_value = 0.0004
	sensitivity.max_value = 0.003
	sensitivity.step = 0.0001
	sensitivity.value = player.sensitivity
	sensitivity.tooltip_text = "Sensibilidad del ratón"
	sensitivity.value_changed.connect(func(value): player.sensitivity = value)
	var subtitle := Label.new()
	menu.add_child(subtitle)
	subtitle.text = "Sensibilidad del ratón\nVersión 0.10.2 · revisión de personajes"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(model_review):
		return
	if OS.has_feature("web") and event is InputEventMouseButton and event.pressed and not get_tree().paused and not DisplayServer.is_touchscreen_available():
		player.capture_mouse()
	if event.is_action_pressed("pause_game") and player.health > 0.0 and not finished:
		set_pause(not get_tree().paused)
	if event.is_action_pressed("interact") and not get_tree().paused and is_instance_valid(target_terminal):
		if target_terminal == level.exit_terminal and not get_tree().get_nodes_in_group("enemies").is_empty():
			show_notice("ELEVADOR BLOQUEADO // Neutralizar amenazas")
		else:
			target_terminal.interact()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	notice_time = maxf(0.0, notice_time - delta)
	health_bar.value = player.health
	energy_bar.value = player.energy
	objective_label.text = "SECTOR 01 / ACCESO\n" + objective
	ammo_label.text = "MAXIMILLIAN / GUN\n%s | %02d" % ["RECARGANDO" if player.reload_time > 0 else str(player.ammo), player.reserve]
	target_terminal = null
	# Interaction uses the view ray, distance AND a clear line of sight.
	var origin: Vector3 = player.camera.global_position
	var hit: Dictionary = player.ray(origin, origin - player.camera.global_basis.z * 7.0, 1)
	if not hit.is_empty() and hit.collider.has_method("interact"):
		if player.global_position.distance_to(hit.collider.global_position) < 3.2 and not hit.collider.used:
			target_terminal = hit.collider
	hint.text = "[E / X] " + target_terminal.title if is_instance_valid(target_terminal) else (notice if notice_time > 0.0 else "")
	if player.position.z < -7 and not phase_events[0]:
		phase_events[0] = true
		show_notice("GIBA: Sabía que vendrías, Jiban.")
	if player.position.z < -23 and not phase_events[1]:
		phase_events[1] = true
		show_notice("ALERTA // Rotura de contención")
		level.spawn_enemy(Vector3(3, 0.1, -33))
	if player.position.z < -40 and not phase_events[2]:
		phase_events[2] = true
		show_notice("BIORON // Firma biológica pesada detectada")

func on_terminal(_terminal: Node) -> void:
	terminals_used += 1
	show_notice("SEGURIDAD // Terminal %d de 2 activada" % terminals_used)
	if terminals_used == 2:
		level.open_door()
		checkpoint = true
		objective = "NEUTRALIZAR AMENAZAS Y ACTIVAR EL ELEVADOR"
		level.spawn_enemy(Vector3(-2, 0.1, -29))
		level.spawn_enemy(Vector3(0, 0.1, -46), true)
		show_notice("ACCESO CONCEDIDO // Punto de control registrado")

func on_exit(_terminal: Node) -> void:
	finished = true
	objective = "SECTOR COMPLETADO"
	set_pause(true)
	status.text = "SECTOR 01 COMPLETADO\nEl experimento apenas comienza."
	resume_button.visible = false

func show_notice(text: String) -> void:
	notice = text
	notice_time = 5.0

func set_pause(value: bool) -> void:
	get_tree().paused = value
	overlay.visible = value
	status.text = "JIBAN // PAUSA"
	resume_button.visible = true
	if value:
		resume_button.grab_focus()
	if not DisplayServer.is_touchscreen_available():
		if value:
			player.reset_mouse_capture()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			player.capture_mouse()

func on_death() -> void:
	set_pause(true)
	status.text = "SISTEMAS DESACTIVADOS"
	resume_button.visible = false

func restart_checkpoint() -> void:
	get_tree().paused = false
	if not checkpoint:
		get_tree().reload_current_scene()
		return
	for corpse in get_tree().get_nodes_in_group("enemy_corpses"):
		corpse.free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.free()
	player.position = Vector3(0, 0.1, -22)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.pitch = 0.0
	player.health = 180.0
	player.energy = 120.0
	player.ammo = 12
	player.reserve = 72
	player.cooldown = 0.0
	player.hurt_time = 0.0
	player.reload_time = 0.0
	phase_events = [true, false, false]
	finished = false
	level.exit_terminal.used = false
	objective = "NEUTRALIZAR AMENAZAS Y ACTIVAR EL ELEVADOR"
	level.spawn_enemy(Vector3(-2, 0.1, -29))
	level.spawn_enemy(Vector3(0, 0.1, -46), true)
	set_pause(false)

func on_shot(origin: Vector3, target: Vector3) -> void:
	var distance := origin.distance_to(target)
	if distance < 0.01:
		return
	var beam := Geo.box(self, (origin + target) / 2.0, Vector3(0.035, 0.035, distance), Geo.material(Color(0.2, 0.8, 1), 0.1, 3.0))
	beam.look_at(target)
	var tween := create_tween()
	tween.tween_interval(0.06)
	tween.tween_callback(beam.queue_free)
	audio.play()

func create_sound() -> void:
	# Short original procedural energy pulse; no third-party audio.
	sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(6615 * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var phase := 0.0
	for i in range(6615):
		var t := float(i) / 22050.0
		phase += TAU * (850.0 * exp(-t * 14.0) + 90.0) / 22050.0
		var sample := (sin(phase) * 0.65 + rng.randf_range(-0.2, 0.2)) * exp(-t * 20.0)
		bytes.encode_s16(i * 2, int(sample * 20000.0))
	sound.data = bytes
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = sound
	audio.volume_db = -12.0

func create_ambience() -> void:
	# Seamless original industrial hum; no recordings from the TV series.
	var rate := 22050
	var seconds := 4
	var data := PackedByteArray()
	data.resize(rate * seconds * 2)
	for i in range(rate * seconds):
		var t := float(i) / rate
		var sample := sin(TAU * 55.0 * t) * 0.11 + sin(TAU * 82.5 * t) * 0.035
		sample *= 0.8 + 0.2 * sin(TAU * 0.25 * t)
		data.encode_s16(i * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = rate * seconds
	var hum := AudioStreamPlayer.new()
	hum.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hum)
	hum.stream = stream
	hum.volume_db = -24
	hum.play()


func open_model_review() -> void:
	if is_instance_valid(model_review):
		return
	if not get_tree().paused:
		set_pause(true)
	# Release held touch actions before switching to the independent studio.
	touch_controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	touch_controls.hide()
	touch_controls.set_process_input(false)
	touch_controls.set_process_unhandled_input(false)
	model_review = preload("res://scripts/model_review.gd").new()
	add_child(model_review)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	model_review.closed.connect(func():
		model_review = null
		touch_controls.show()
		touch_controls.set_process_input(true)
		touch_controls.set_process_unhandled_input(true)
	)




