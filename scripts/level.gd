extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const Terminal = preload("res://scripts/terminal.gd")
const Enemy = preload("res://scripts/enemy.gd")
var door: Node3D
var terminals: Array[Node] = []
var exit_terminal: Node
var lamps: Array[OmniLight3D] = []

func _ready() -> void:
	var steel := Geo.material(Color(0.07, 0.1, 0.14), 0.7)
	var panel := Geo.material(Color(0.12, 0.17, 0.22), 0.65)
	var red := Geo.material(Color(0.9, 0.025, 0.015), 0.2, 2.5)
	var cyan := Geo.material(Color(0.05, 0.5, 0.8), 0.2, 2.0)
	# Continuous collision floor, with non-colliding decorative seams.
	Geo.box(self, Vector3(0, -0.25, -24), Vector3(16, 0.5, 64), steel, true)
	Geo.box(self, Vector3(0, 7, -24), Vector3(16, 0.5, 64), steel, true)
	for x in [-8.0, 8.0]:
		Geo.box(self, Vector3(x, 3.5, -24), Vector3(0.5, 7, 64), steel, true)
	Geo.box(self, Vector3(0, 3.5, 8), Vector3(16, 7, 0.5), steel, true)
	Geo.box(self, Vector3(0, 3.5, -56), Vector3(16, 7, 0.5), steel, true)
	for z in range(4, -56, -4):
		Geo.box(self, Vector3(0, 0.015, z), Vector3(15.5, 0.025, 0.07), panel)
		for x in [-7.5, 7.5]:
			Geo.box(self, Vector3(x, 3.3, z), Vector3(0.45, 6.6, 0.65), panel)
			Geo.box(self, Vector3(x * 0.98, 2.5, z + 0.37), Vector3(0.18, 2.0, 0.06), red if z < -22 else cyan)
			Geo.cylinder(self, Vector3(x * 0.92, 3.5, z - 0.8), 0.13, 7, steel)
		if z % 8 == 4 or z % 8 == -4:
			lamps.append(Geo.light(self, Vector3(0, 5.5, z), Color(0.18, 0.6, 1.0) if z > -22 else Color(1, 0.17, 0.08), 2.3, 10))
		Geo.box(self, Vector3(0, 6.7, z), Vector3(4, 0.1, 0.2), cyan)
	for x in [-5.3, 5.3]:
		Geo.box(self, Vector3(x, 3.0, -20), Vector3(5.4, 6, 0.8), panel, true)
		Geo.box(self, Vector3(x, 3.0, -40), Vector3(5.4, 6, 0.8), panel, true)
	Geo.box(self, Vector3(0, 6.25, -20), Vector3(5.2, 1.5, 1), panel, true)
	door = Geo.box(self, Vector3(0, 2.7, -20), Vector3(5, 5.4, 0.5), steel, true)
	Geo.box(door, Vector3(0, 0, 0.27), Vector3(0.08, 5.2, 0.05), red)
	Geo.label(self, Vector3(0, 5.8, -19.4), "B01 / CONTENCIÓN", 65)
	Geo.label(self, Vector3(0, 5.8, -39.4), "NÚCLEO / ELEVADOR", 65)
	for z in [-27.0, -34.0, -46.0, -52.0]:
		for x in [-5.8, 5.8]:
			Geo.box(self, Vector3(x, 1.5, z), Vector3(1.9, 3, 1.9), steel, true)
			Geo.cylinder(self, Vector3(x, 2.0, z + 1.0), 0.65, 2.6, Geo.material(Color(0.1, 0.24, 0.17), 0.6))
			Geo.box(self, Vector3(x, 2.1, z + 1.65), Vector3(0.07, 2.2, 0.07), red)
			Geo.light(self, Vector3(x, 2.7, z + 2), Color(0.1, 1, 0.5), 0.7, 3)
	terminals.append(make_terminal(Vector3(-4, 0, -15), "01 / SEGURIDAD"))
	terminals.append(make_terminal(Vector3(4, 0, -17), "02 / CONTENCIÓN"))
	exit_terminal = make_terminal(Vector3(0, 0, -53), "ELEVADOR")

func make_terminal(pos: Vector3, title: String) -> Node:
	var terminal := Terminal.new()
	terminal.title = title
	add_child(terminal)
	terminal.position = pos
	return terminal

func spawn_enemy(pos: Vector3, heavy: bool = false) -> Node:
	var enemy := Enemy.new()
	enemy.heavy = heavy
	add_child(enemy)
	enemy.position = pos
	return enemy

func open_door() -> void:
	var tween := create_tween()
	tween.tween_property(door, "position:y", 8.4, 1.4).set_trans(Tween.TRANS_SINE)
