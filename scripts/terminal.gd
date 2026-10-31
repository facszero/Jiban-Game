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
	Geo.box(self, Vector3(0, 0.8, 0), shape.size, Geo.material(Color(0.08, 0.12, 0.17), 0.6))
	screen = Geo.box(self, Vector3(0, 1.15, 0.27), Vector3(0.7, 0.5, 0.03), Geo.material(Color(0.02, 0.5, 0.75), 0.2, 1.5))
	Geo.label(self, Vector3(0, 1.9, 0), title, 30)

func interact() -> void:
	if used:
		return
	used = true
	activated.emit(self)
