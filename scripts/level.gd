extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const Terminal = preload("res://scripts/terminal.gd")
const Enemy = preload("res://scripts/enemy.gd")
var door: Node3D
var terminals: Array[Node] = []
var exit_terminal: Node
var lamps: Array[OmniLight3D] = []

func _ready() -> void:
	var steel := preload("res://scripts/industrial_materials.gd").metal("steel")
	var panel := preload("res://scripts/industrial_materials.gd").metal("wall")
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
			lamps.append(Geo.light(self, Vector3(0, 5.5, z), Color(.7,.8,1), .65, 9))
		Geo.box(self, Vector3(0, 6.7, z), Vector3(4, 0.1, 0.2), cyan)
	for x in [-5.3, 5.3]:
		Geo.box(self, Vector3(x, 3.0, -20), Vector3(5.4, 6, 0.8), panel, true)
		Geo.box(self, Vector3(x, 3.0, -40), Vector3(5.4, 6, 0.8), panel, true)
	Geo.box(self, Vector3(0, 6.25, -20), Vector3(5.2, 1.5, 1), panel, true)
	door = Geo.box(self, Vector3(0, 2.7, -20), Vector3(5, 5.4, 0.5), steel, true)
	Geo.box(door, Vector3(0, 0, 0.27), Vector3(0.08, 5.2, 0.05), red)
	Geo.label(self, Vector3(0, 5.8, -19.15), "B01 / CONTENCIÓN", 65)
	Geo.label(self, Vector3(0, 5.8, -39.15), "NÚCLEO / ELEVADOR", 65)
	decorate_sector()
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

func decorate_sector() -> void:
	var dressing := preload("res://scripts/industrial_sector.gd").new()
	dressing.name = "IndustrialSector"
	add_child(dressing)
