extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const Materials = preload("res://scripts/industrial_materials.gd")
var steel: Material
var dark: Material
var red: Material
var white: Material
var amber: Material
var specimen: Material
var droplets: Material
var bolts: Array[Transform3D] = []

func _ready() -> void:
	steel = Materials.metal()
	dark = Geo.material(Color(.025,.029,.035),.55)
	red = Geo.material(Color(1,.018,.008),.1,3)
	white = Geo.material(Color(.68,.80,.9),.05,2)
	amber = Geo.material(Color(.45,.23,.035),.2)
	specimen = Geo.material(Color(.11,.20,.15),.08)
	droplets = Geo.material(Color(.22,.28,.27),.3)
	build_floor()
	build_walls()
	for z in [-20.0,-40.0]: build_portal(z)
	for z in [-27.0,-34.0,-46.0,-52.0]:
		for x in [-5.8,5.8]: build_tank(Vector3(x,0,z+1.1))
	Geo.label(self,Vector3(0,4.9,7.6),"BIORON / ACCESO EXTERIOR",48).rotation.y=PI
	batch_static_geometry()
	# Local cubemaps give the metal the actual red/cold fixtures, not a daylight sky.
	for z in [-10.0,-30.0,-48.0]:
		var probe := ReflectionProbe.new()
		probe.position=Vector3(0,3.3,z)
		probe.size=Vector3(16,7,22)
		probe.interior=true
		probe.intensity=.65
		probe.max_distance=22
		probe.mesh_lod_threshold=4
		add_child(probe)

func box(pos: Vector3, size: Vector3, mat: Material) -> Node3D:
	return Geo.box(self,pos,size,mat)

func build_floor() -> void:
	# Underlying collision slab stays continuous. All detail is visual only.
	for z in range(6,-56,-2):
		for x in range(-7,8,2):
			box(Vector3(x,.008,z-1),Vector3(1.98,.014,1.98),Materials.metal("floor"))
	for z in range(4,-56,-4):
		box(Vector3(0,.018,z),Vector3(15.4,.018,.24),dark)
		for x in range(-75,76,2):
			box(Vector3(x*.1,.035,z),Vector3(.035,.022,.23),steel)
	for side in [-1,1]:
		box(Vector3(side*3.0,.032,-24),Vector3(.045,.015,62),amber)
		box(Vector3(side*7.45,.08,-24),Vector3(.22,.12,63),steel)
	for z in [-19.0,-39.0]:
		for x in range(-5,6):
			var stripe := box(Vector3(x*.45,.034,z),Vector3(.23,.02,.46),amber)
			stripe.rotation.y=-.5

func build_walls() -> void:
	for z in range(4,-56,-4):
		for side in [-1,1]:
			box(Vector3(side*7.68,3.2,z-2),Vector3(.12,5.9,3.75),Materials.metal("wall"))
			for y in [0.5,5.9]:
				box(Vector3(side*7.56,y,z-2),Vector3(.13,.10,3.7),steel)
			# Recessed ventilation slats and junction plates.
			box(Vector3(side*7.52,.9,z-2),Vector3(.15,.68,1.35),dark)
			for i in range(6):
				box(Vector3(side*7.40,.65+i*.10,z-2),Vector3(.08,.035,1.2),steel)
			for y in [1.5,4.6]:
				Geo.link(self,Vector3(side*7.38,y,z-.5),Vector3(side*7.38,y+.5,z-.5),.035,steel)
			box(Vector3(side*7.35,3.5,z+.36),Vector3(.17,1.6,.10),dark)
			box(Vector3(side*7.24,3.5,z+.38),Vector3(.07,1.35,.075),red)
			for i in range(3):
				var xx: float = side*(6.15+i*.35)
				var yy := 6.15+i*.17
				Geo.link(self,Vector3(xx,yy,z+2),Vector3(xx,yy,z-2),.10+i*.025,steel)
				Geo.link(self,Vector3(xx,yy,z-.06),Vector3(xx,yy,z+.06),.14+i*.025,dark)
			box(Vector3(side*6.5,5.98,z),Vector3(1.25,.08,.12),steel)
			# Service cable elbows, with clips and sockets rather than floating rods.
			for cable in range(2):
				var points := [Vector3(side*(7.2-cable*.12),6.0,z-1),Vector3(side*(7.2-cable*.12),4.9,z-1),Vector3(side*7.3,4.6,z-1.25),Vector3(side*7.3,3.9,z-1.25)]
				for i in range(3): Geo.link(self,points[i],points[i+1],.035,dark)
			box(Vector3(side*7.35,3.75,z-1.25),Vector3(.19,.35,.30),steel)
		box(Vector3(0,6.65,z),Vector3(15,.23,.25),steel)
		box(Vector3(0,6.82,z-2),Vector3(14,.10,3.7),Materials.metal("wall"))
		for x in [-3.5,3.5]:
			box(Vector3(x,6.52,z-1),Vector3(1.3,.13,.30),dark)
			box(Vector3(x,6.43,z-1),Vector3(1.15,.035,.19),white)
		if z % 8 == 4:
			var light := SpotLight3D.new()
			light.position=Vector3(0,6.1,z-1)
			light.rotation_degrees.x=-90
			light.light_color=Color(.68,.78,.92)
			light.light_energy=3.5
			light.spot_range=12
			light.spot_angle=67
			light.spot_attenuation=.7
			light.shadow_enabled=true
			light.shadow_bias=.04
			add_child(light)
		for side in [-1,1]:
			if z % 8 == 4: Geo.light(self,Vector3(side*6.7,3.4,z),Color(1,.055,.025),1.3,4.8)

func build_portal(z: float) -> void:
	for side in [-1,1]:
		box(Vector3(side*2.62,2.7,z+.57),Vector3(.28,5.4,.40),steel)
		box(Vector3(side*2.87,2.7,z+.48),Vector3(.20,5.4,.27),dark)
		for y in [1.0,3.6]:
			box(Vector3(side*2.80,y,z+.72),Vector3(.12,.98,.08),red)
		for y in [.45,2.2,4.7]:
			box(Vector3(side*2.66,y,z+.82),Vector3(.35,.16,.10),dark)
		var bevel := box(Vector3(side*2.48,5.30,z+.77),Vector3(.5,.14,.18),steel)
		bevel.rotation.z=side*PI/4
		# Front panels cover the existing solid partition without changing the opening.
		for x in [3.7,5.3,6.9]:
			box(Vector3(side*x,3,z+.48),Vector3(1.52,5.9,.09),Materials.metal("wall"))
		box(Vector3(side*4.5,1.1,z+.60),Vector3(1.1,.65,.14),dark)
		for i in range(6):box(Vector3(side*4.5,.88+i*.08,z+.70),Vector3(.95,.025,.05),steel)
		var sign := Geo.label(self,Vector3(side*4.6,4.1,z+.65),("01 / SEGURIDAD" if side<0 else "02 / CONTENCIÓN") if z == -20.0 else "B3\nSECTOR 01",28 if z == -20.0 else 48)
		sign.modulate=Color(.52,.50,.47)
		box(Vector3(side*4.6,2.65,z+.62),Vector3(1.05,1.04,.23),steel)
		box(Vector3(side*4.6,2.75,z+.76),Vector3(.86,.72,.04),Materials.screen())
		for i in range(4):
			box(Vector3(side*4.6-.30+i*.20,2.24,z+.78),Vector3(.11,.10,.05),red if i==0 else dark)
	box(Vector3(0,5.48,z+.56),Vector3(5.5,.25,.42),steel)
	box(Vector3(0,5.83,z+.55),Vector3(5.1,.50,.14),dark)
	box(Vector3(0,5.16,z+.60),Vector3(3.4,.04,.09),red)

func build_tank(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position=pos+Vector3(0,1.92,0)
	var collision := CollisionShape3D.new()
	var bounds := CylinderShape3D.new()
	bounds.radius=.88
	bounds.height=3.84
	collision.shape=bounds
	body.add_child(collision)
	add_child(body)
	for y in [.25,3.6]:
		var cap := Geo.cylinder(self,pos+Vector3(0,y,0),.88,.34,steel)
		cap.mesh.radial_segments=32
		var ring := Geo.cylinder(self,pos+Vector3(0,y+(.2 if y<1 else -.2),0),.82,.085,dark)
		ring.mesh.radial_segments=32
		for i in range(12):
			var a := TAU*i/12.0
			Geo.ellipsoid(self,pos+Vector3(sin(a)*.88,y,cos(a)*.88),Vector3(.08,.08,.08),dark)
	var glass := StandardMaterial3D.new()
	glass.albedo_color=Color(.18,.26,.25,.13)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness=.19
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var shell := Geo.cylinder(self,pos+Vector3(0,1.94,0),.77,2.98,glass)
	shell.mesh.radial_segments=32
	shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1,1]:
		Geo.link(self,pos+Vector3(side*.73,.45,.25),pos+Vector3(side*.73,3.38,.25),.045,red)
		Geo.link(self,pos+Vector3(side*.70,.45,-.33),pos+Vector3(side*.70,3.38,-.33),.065,steel)
	var culture := preload("res://scripts/chamelenoid_model.gd").new()
	culture.position=pos+Vector3(0,.45,0)
	culture.scale=Vector3(.62,.94,.62)
	culture.rotation.y=PI
	add_child(culture)
	culture.animate(.4,0)
	culture.process_mode=Node.PROCESS_MODE_DISABLED
	Geo.light(self,pos+Vector3(0,2.6,.85),Color(1,.035,.015),2.5,5.5)
	# Console is attached to the tank frame, leaving the corridor clear.
	var panelpos := pos+Vector3(1.03,1.7,.40)
	box(panelpos,Vector3(.60,.91,.22),steel)
	box(panelpos+Vector3(0,.12,.13),Vector3(.49,.55,.035),Materials.screen())
	for i in range(3):
		box(panelpos+Vector3(-.16+i*.16,-.28,.14),Vector3(.09,.08,.04),red if i==0 else dark)
	Geo.link(self,pos+Vector3(0,3.8,0),pos+Vector3(0,6.2,0),.10,steel)
	var steam := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size=Vector2(1.6,1.3)
	steam.mesh=quad
	steam.position=pos+Vector3(-.75,.65,.55)
	var vapor := ShaderMaterial.new()
	vapor.shader=preload("res://assets/environment/steam.gdshader")
	vapor.set_shader_parameter("seed",pos.z)
	steam.material_override=vapor
	steam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(steam)
	# Condensation streaks are sparse geometry, no screen-space transparency stack.
	for i in range(14):
		var a := i*2.399
		var y := .65+fmod(i*.419,2.5)
		Geo.link(self,pos+Vector3(sin(a)*.775,y,cos(a)*.775),pos+Vector3(sin(a)*.775,y+.035+(i%3)*.018,cos(a)*.775),.004,droplets)

func batch_static_geometry() -> void:
	# Bake world transforms into per-material MultiMeshes. Collisions stay in Level.
	var groups: Dictionary = {}
	collect_meshes(self,groups)
	for key in groups:
		var items: Array=groups[key]
		if items.size()<2: continue
		var first: MeshInstance3D=items[0]
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=first.mesh
		mm.instance_count=items.size()
		var node := MultiMeshInstance3D.new()
		node.multimesh=mm
		node.material_override=first.material_override
		add_child(node)
		for i in range(items.size()):
			mm.set_instance_transform(i,global_transform.affine_inverse()*items[i].global_transform)
			items[i].queue_free()

func collect_meshes(node: Node, groups: Dictionary) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and (child.mesh is BoxMesh or child.mesh is CylinderMesh or child.mesh is SphereMesh):
			if child.material_override is StandardMaterial3D and child.material_override.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
			# Limit each batch to a room: Compatibility selects lights per object.
			var key := str(child.material_override.get_instance_id())+":"+str(floori(child.global_position.z/12.0))+":"
			if child.mesh is BoxMesh:
				key += "box"+str(child.mesh.size)
			elif child.mesh is CylinderMesh:
				key += "cyl"+str(child.mesh.top_radius)+":"+str(child.mesh.height)+":"+str(child.mesh.radial_segments)
			else:
				key += "sphere"+str(child.mesh.radius)+":"+str(child.mesh.height)
			if not groups.has(key): groups[key]=[]
			groups[key].append(child)
		collect_meshes(child,groups)
