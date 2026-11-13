extends RefCounted
const Geo = preload("res://scripts/geometry.gd")
const Hard = preload("res://scripts/hard_surface.gd")
const Materials = preload("res://scripts/industrial_materials.gd")
static func build(door: Node3D) -> void:
	var steel := Materials.metal()
	var dark := Geo.material(Color(.025,.032,.04),.65)
	var satin := Geo.material(Color(.16,.19,.21),.7)
	var warning := Geo.material(Color(.58,.34,.08),.35)
	# Moving detail follows the existing collision door and checkpoint tween.
	for side in [-1,1]:
		Hard.plate(door,Vector3(side*1.24,0,.28),Vector3(2.42,5.22,.14),dark,.13)
		Hard.plate(door,Vector3(side*1.24,.02,.36),Vector3(2.20,4.85,.15),satin,.16)
		for y in [-1.58,0,1.58]:
			Hard.plate(door,Vector3(side*1.26,y,.45),Vector3(1.92,1.38,.10),steel,.09)
			for x in [.45,2.05]:
				var bolt := Geo.cylinder(door,Vector3(side*x,y+.48,.51),.035,.025,dark)
				bolt.rotation.x=PI/2
		Hard.plate(door,Vector3(side*.14,0,.51),Vector3(.19,4.95,.12),dark,.035)
		for y in [-1.9,1.9]:
			Hard.plate(door,Vector3(side*.35,y,.55),Vector3(.43,.22,.16),satin,.04)
		Geo.box(door,Vector3(side*1.25,-2.44,.46),Vector3(1.85,.08,.025),warning)
	Hard.plate(door,Vector3(0,.12,.60),Vector3(.65,.56,.10),dark,.06)
	Hard.label(door,Vector3(0,.20,.66),"B01",.37)
	Hard.label(door,Vector3(0,-.02,.66),"BLOQUEO",.43,Color(.8,.33,.13))
	Hard.label(door,Vector3(-1.23,1.57,.52),"CONTENCIÓN",1.32)
	Hard.label(door,Vector3(1.23,1.57,.52),"ACCESO RESTRINGIDO",1.45)
static func surround(parent: Node3D,z: float) -> void:
	var steel := Materials.metal()
	var dark := Geo.material(Color(.028,.035,.043),.65)
	var satin := Geo.material(Color(.20,.23,.26),.8)
	for side in [-1,1]:
		Hard.plate(parent,Vector3(side*2.91,2.72,z+.72),Vector3(.56,5.45,.40),steel,.085)
		Hard.plate(parent,Vector3(side*3.34,2.72,z+.58),Vector3(.24,5.35,.20),dark,.045)
		Geo.link(parent,Vector3(side*3.30,.6,z+.77),Vector3(side*3.30,4.85,z+.77),.065,satin)
		for y in [1.0,4.35]:
			Geo.link(parent,Vector3(side*3.30,y-.28,z+.77),Vector3(side*3.30,y+.28,z+.77),.11,dark)
		for y in [.5,2.7,5.0]:
			Hard.plate(parent,Vector3(side*2.95,y,z+.96),Vector3(.45,.17,.12),dark,.03)
		Geo.box(parent,Vector3(side*2.72,2.8,z+.95),Vector3(.035,2.2,.025),Geo.material(Color(.8,.035,.012),0,1.5))
	Hard.plate(parent,Vector3(0,5.60,z+.72),Vector3(6.25,.48,.45),steel,.09)
	Hard.plate(parent,Vector3(0,5.62,z+.97),Vector3(3.8,.29,.035),dark,.035)
	Hard.label(parent,Vector3(0,5.62,z+1.00),"B01 / CONTENCIÓN",3.20)
	Geo.box(parent,Vector3(0,5.32,z+.90),Vector3(2.1,.08,.22),dark)
	Geo.box(parent,Vector3(0,5.27,z+.95),Vector3(1.90,.025,.11),Geo.material(Color(.75,.82,.9),0,1.7))
	var lamp := SpotLight3D.new()
	lamp.position=Vector3(0,5.1,z+2.5)
	parent.add_child(lamp)
	lamp.look_at(Vector3(0,2.5,z+.4))
	lamp.light_color=Color(.77,.84,.94)
	lamp.light_energy=3.0
	lamp.spot_range=7
	lamp.spot_angle=55
	lamp.shadow_enabled=true
