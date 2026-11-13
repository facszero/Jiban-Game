extends StaticBody3D

signal activated(terminal)
const Geo = preload("res://scripts/geometry.gd")
@export var title := "TERMINAL"
var used := false
var screen: Node3D

func _ready() -> void:
	add_to_group("interactables")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.6, 0.5)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.8
	add_child(col)
	Geo.box(self, Vector3(0, 0.8, 0), shape.size, preload("res://scripts/industrial_materials.gd").metal())
	screen = Geo.box(self, Vector3(0, 1.15, 0.27), Vector3(0.7, 0.5, 0.03), preload("res://scripts/industrial_materials.gd").screen())
	var dark := Geo.material(Color(.025,.03,.035),.6)
	var red := Geo.material(Color(.8,.02,.01),.1,1.7)
	for x in [-.40,.40]:
		Geo.box(self,Vector3(x,1.15,.28),Vector3(.07,.65,.07),dark)
	for y in [.84,1.46]:
		Geo.box(self,Vector3(0,y,.28),Vector3(.85,.07,.07),dark)
	for i in range(4):
		Geo.box(self,Vector3(-.27+i*.18,.66,.29),Vector3(.11,.10,.06),red if i==0 else dark)
	for i in range(6):
		Geo.box(self,Vector3(0,.18+i*.048,.27),Vector3(.65,.018,.045),dark)
	Geo.label(self, Vector3(0, 1.9, 0), title, 30)

func interact() -> void:
	if used:
		return
	used = true
	activated.emit(self)
