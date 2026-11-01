extends CanvasLayer

# Track each finger independently, including simultaneous movement and firing.
@export var force_visible := false
var player: Node3D
var look_finger := -1
var zones: Array = []
var held: Dictionary = {}

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("player")
	var active := force_visible or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if not active:
		return
	var layout := Node2D.new()
	add_child(layout)
	var buttons := [
		["forward", "▲", Vector2(125, 460)], ["back", "▼", Vector2(125, 620)],
		["left", "◀", Vector2(45, 540)], ["right", "▶", Vector2(205, 540)],
		["fire", "FUEGO", Vector2(1130, 535)], ["jump", "SALTO", Vector2(1220, 450)],
		["interact", "USAR", Vector2(1010, 620)], ["reload", "CARGA", Vector2(1130, 650)],
		["view", "VISTA", Vector2(1210, 120)], ["pause_game", "PAUSA", Vector2(1210, 215)],
		["scan", "LUZ", Vector2(1210, 305)]]
	for entry in buttons:
		var button := Node2D.new()
		layout.add_child(button)
		button.position = entry[2]
		zones.append(entry)
		var disc := Polygon2D.new()
		button.add_child(disc)
		var points := PackedVector2Array()
		for i in range(32):
			points.append(Vector2.from_angle(TAU * i / 32.0) * 38)
		disc.polygon = points
		disc.color = Color(0.06, 0.22, 0.32, 0.75)
		var label := Label.new()
		button.add_child(label)
		label.position = Vector2(-38, -13)
		label.size = Vector2(76, 26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		label.text = entry[1]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var help := Label.new()
	layout.add_child(help)
	help.position = Vector2(400, 640)
	help.text = "Arrastrá el centro/derecha para mirar"
	var scale_layout := func():
		var viewport := get_viewport().get_visible_rect().size
		layout.scale = viewport / Vector2(1280, 720)
	get_viewport().size_changed.connect(scale_layout)
	scale_layout.call()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or not is_instance_valid(player):
		look_finger = -1
		return
	if event is InputEventScreenTouch:
		if not event.pressed and event.index == look_finger:
			look_finger = -1
		elif event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.35 and look_finger == -1:
			look_finger = event.index
	if event is InputEventScreenDrag and event.index == look_finger:
		player.rotate_y(-event.relative.x * 0.004)
		player.pitch = clampf(player.pitch - event.relative.y * 0.004, -1.25, 1.25)

func action_event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch or zones.is_empty():
		return
	if not event.pressed and held.has(event.index):
		var action: String = held[event.index]
		held.erase(event.index)
		if not held.values().has(action):
			action_event(action, false)
		get_viewport().set_input_as_handled()
		return
	if event.pressed:
		var point: Vector2 = event.position * Vector2(1280, 720) / get_viewport().get_visible_rect().size
		for zone in zones:
			if point.distance_to(zone[2]) < 38:
				if not get_tree().paused or zone[0] == "pause_game":
					held[event.index] = zone[0]
					action_event(zone[0], true)
				get_viewport().set_input_as_handled()
				return

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in held.values():
			action_event(action, false)
		held.clear()
		look_finger = -1
