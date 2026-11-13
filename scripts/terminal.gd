extends StaticBody3D

signal activated(terminal)
const Geo = preload("res://scripts/geometry.gd")
@export var title := "TERMINAL"
var used := false
var screen: Node3D
const Hard = preload("res://scripts/hard_surface.gd")
var indicator: StandardMaterial3D
var status_sign: Label3D
var shown_used := false

func _ready() -> void:
	add_to_group("interactables")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.6, 0.5)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.8
	add_child(col)
	var steel := preload("res://scripts/industrial_materials.gd").metal()
	var dark := Geo.material(Color(.035,.043,.052),.65)
	var edge := Geo.material(Color(.24,.27,.29),.8)
	indicator=Geo.material(Color(.8,.10,.025),.1,1.2)
	Hard.plate(self,Vector3(0,.055,0),Vector3(.88,.11,.48),dark,.035)
	Hard.plate(self,Vector3(0,.39,-.055),Vector3(.46,.65,.32),steel,.045)
	Hard.plate(self,Vector3(0,1.07,0),Vector3(.87,1.02,.46),steel,.055)
	Hard.plate(self,Vector3(0,1.12,.245),Vector3(.77,.64,.075),edge,.025)
	Hard.plate(self,Vector3(0,1.12,.285),Vector3(.69,.55,.018),dark,.018)
	var display := StandardMaterial3D.new()
	display.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	display.albedo_texture=preload("res://assets/environment/console_security.png") if title.begins_with("01") or title=="ELEVADOR" else preload("res://assets/environment/console_containment.png")
	var display_mesh := MeshInstance3D.new()
	var display_quad := QuadMesh.new()
	display_quad.size=Vector2(.61,.45)
	display_mesh.mesh=display_quad
	display_mesh.material_override=display
	display_mesh.position=Vector3(0,1.12,.305)
	add_child(display_mesh)
	screen=display_mesh
	for x in [-.355,.355]:
		Geo.box(self,Vector3(x,1.12,.303),Vector3(.025,.53,.025),dark)
	Hard.plate(self,Vector3(0,1.50,.24),Vector3(.75,.115,.025),dark,.014)
	Hard.label(self,Vector3(0,1.50,.257),title,.69)
	Hard.plate(self,Vector3(0,.71,.25),Vector3(.73,.19,.035),dark,.02)
	for i in range(3):
		Hard.plate(self,Vector3(-.25+i*.17,.72,.282),Vector3(.12,.09,.035),indicator if i==0 else edge,.013)
	var dial := Geo.cylinder(self,Vector3(.27,.72,.287),.047,.035,dark)
	dial.rotation.x=PI/2
	Geo.box(self,Vector3(.27,.74,.31),Vector3(.008,.027,.005),edge)
	status_sign=Hard.label(self,Vector3(0,.84,.303),"ACCESO / PENDIENTE",.55,Color(.65,.39,.16))
	for i in range(5):
		Geo.box(self,Vector3(0,.23+i*.055,.112),Vector3(.32,.022,.014),dark)
	for x in [-.37,.37]:
		for y in [.60,1.54]:
			var bolt := Geo.cylinder(self,Vector3(x,y,.24),.014,.016,edge)
			bolt.rotation.x=PI/2
	Geo.box(self,Vector3(0,1.59,.08),Vector3(.50,.04,.20),dark)
	Geo.box(self,Vector3(0,1.565,.12),Vector3(.42,.012,.08),Geo.material(Color(.55,.75,.85),0,1))
	Geo.light(self,Vector3(0,1.65,.48),Color(.58,.73,.85),.35,1.3)

func _process(_delta: float) -> void:
	if shown_used==used: return
	shown_used=used
	indicator.albedo_color=Color(.035,.6,.3) if used else Color(.8,.10,.025)
	indicator.emission=indicator.albedo_color
	status_sign.text="ACCESO / AUTORIZADO" if used else "ACCESO / PENDIENTE"
	status_sign.modulate=Color(.18,.8,.5) if used else Color(.65,.39,.16)

func interact() -> void:
	if used:
		return
	used = true
	activated.emit(self)
