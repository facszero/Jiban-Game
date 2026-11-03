extends Node3D
## Segmented organic model based on the approved concept sheet; front is -Z.
const MeshTools = preload("res://scripts/jiban_model.gd")
const Geo = preload("res://scripts/geometry.gd")
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var torso: Node3D
var head: Node3D
var helper: Node3D
var skin: StandardMaterial3D
var flesh: StandardMaterial3D
var edge: StandardMaterial3D
var gold: StandardMaterial3D
var dark: StandardMaterial3D
var claw: StandardMaterial3D

func organic(color: Color, roughness: float, seed_value: int) -> StandardMaterial3D:
	var mat = MeshTools.metal(color,.05,roughness)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = .24
	var img := Image.create(128,128,false,Image.FORMAT_RGB8)
	var normals := Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			var n := .83 + surface_height(x,y,noise,seed_value)*.12
			img.set_pixel(x,y,Color(n,n,n))
			var dx := surface_height(x+1,y,noise,seed_value)-surface_height(x-1,y,noise,seed_value)
			var dy := surface_height(x,y+1,noise,seed_value)-surface_height(x,y-1,noise,seed_value)
			var normal := Vector3(-dx*1.1,-dy*1.1,1).normalized()
			normals.set_pixel(x,y,Color(normal.x*.5+.5,normal.y*.5+.5,normal.z*.5+.5))
	img.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	normals.generate_mipmaps()
	mat.normal_enabled=true
	mat.normal_texture=ImageTexture.create_from_image(normals)
	mat.normal_scale=.38
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE*5.5
	return mat

func _ready() -> void:
	helper = MeshTools.new()
	skin = organic(Color(.25,.32,.18),.73,31)
	flesh = organic(Color(.29,.075,.065),.67,17)
	edge = organic(Color(.36,.39,.20),.78,42)
	gold = MeshTools.metal(Color(.66,.53,.17),.16,.35)
	dark = MeshTools.metal(Color(.018,.022,.012),.0,.6)
	claw = MeshTools.metal(Color(.19,.16,.10),.05,.6)
	torso = helper.joint(self,Vector3.ZERO,"Torso")
	build_torso()
	build_head()
	for side in [-1,1]:
		build_arm(side)
		build_leg(side)
	helper.merge_parts(self)
	helper.free()

func shell(parent: Node3D, pos: Vector3, rings: Array, mat: Material) -> MeshInstance3D:
	return helper.shell(parent,pos,rings,mat,24)
func plate(parent: Node3D, pos: Vector3, points: Array, thickness: float, mat: Material) -> MeshInstance3D:
	# Rounded outline and concentric curved rings replace the flat bevel fan.
	var outline: Array = points.duplicate()
	for iteration in range(1):
		var rounded: Array = []
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var b: Vector2 = outline[(i+1)%outline.size()]
			rounded.append(a.lerp(b,.18))
			rounded.append(a.lerp(b,.82))
		outline=rounded
	var center := Vector2.ZERO
	for point in outline:
		center+=point
	center/=outline.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [1.0,.78,.45,.08]
	for r in range(rings.size()-1):
		for i in range(outline.size()):
			var vertices: Array[Vector3]=[]
			for item in [Vector2i(r,i),Vector2i(r,(i+1)%outline.size()),Vector2i(r+1,(i+1)%outline.size()),Vector2i(r+1,i)]:
				var radius: float=rings[item.x]
				var point: Vector2=center+(outline[item.y]-center)*radius
				vertices.append(Vector3(point.x,point.y,-thickness*(1-radius*radius)))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(vertices[index])
	for i in range(outline.size()):
		var a: Vector2=center+(outline[i]-center)*.08
		var b: Vector2=center+(outline[(i+1)%outline.size()]-center)*.08
		for vertex in [Vector3(center.x,center.y,-thickness),Vector3(b.x,b.y,-thickness*.9936),Vector3(a.x,a.y,-thickness*.9936)]:
			st.add_vertex(vertex)
	st.generate_normals()
	st.index()
	return helper.instance(parent,pos,st.commit(),mat)
func leaf(parent: Node3D, pos: Vector3, width: float, length: float, mat: Material) -> MeshInstance3D:
	return plate(parent,pos,[Vector2(-width*.35,length*.5),Vector2(width*.35,length*.5),Vector2(width*.5,length*.18),Vector2(width*.28,-length*.22),Vector2(0,-length*.5),Vector2(-width*.35,-length*.18)],width*.14,mat)
func build_torso() -> void:
	shell(torso,Vector3.ZERO,[Vector3(.96,.15,.12),Vector3(1.12,.19,.14),Vector3(1.35,.25,.16),Vector3(1.62,.32,.18),Vector3(1.78,.24,.14)],flesh)
	shell(torso,Vector3.ZERO,[Vector3(.88,.16,.12),Vector3(1.02,.23,.15),Vector3(1.13,.19,.13)],flesh)
	for side in [-1,1]:
		# Wide pectoral plates converge into a central keel.
		var chest_points := [Vector2(-.145,.13),Vector2(.025,.15),Vector2(.13,.075),Vector2(.16,.015),Vector2(.10,-.07),Vector2(.025,-.11),Vector2(-.045,-.08),Vector2(-.09,-.14),Vector2(-.145,-.04)]
		if side<0:
			for i in range(chest_points.size()):
				chest_points[i].x *= -1
			chest_points.reverse()
		plate(torso,Vector3(side*.125,1.565,-.158),chest_points,.037,skin)
		for row in range(3):
			for column in range(3):
				var x: float = side*(.065+column*.045+row*.006)
				var y := 1.52+row*.037
				Geo.ellipsoid(torso,Vector3(x,y,-.195),Vector3(.012,.017,.007),edge)
		for i in range(3):
			var y := 1.365-i*.105
			leaf(torso,Vector3(side*(.10-i*.012),y,-.15),.205-i*.025,.17,skin).rotation.z=side*.3
		leaf(torso,Vector3(side*.16,1.04,-.13),.19,.20,skin).rotation.z=side*.55
		# Overlapping dorsal plates and maroon rib folds.
		for i in range(3):
			leaf(torso,Vector3(side*.11,1.60-i*.16,.162),.20,.24,skin).rotation.y=PI
		for i in range(5):
			Geo.link(torso,Vector3(side*.18,1.16+i*.095,-.06),Vector3(side*(.23+i*.012),1.20+i*.095,.08),.018,flesh)
	leaf(torso,Vector3(0,1.12,-.168),.12,.33,skin)
	for i in range(6):
		leaf(torso,Vector3(0,1.12+i*.1,.17),.07,.13,edge).rotation.y=PI
	shell(torso,Vector3.ZERO,[Vector3(1.75,.10,.10),Vector3(1.91,.093,.09)],flesh)
	for side in [-1,1]:
		leaf(torso,Vector3(side*.15,1.76,-.11),.15,.17,flesh).rotation.z=side*.65

func build_head() -> void:
	head = helper.joint(torso,Vector3(0,1.85,0),"Head")
	shell(head,Vector3.ZERO,[Vector3(-.02,.065,.075),Vector3(.07,.14,.13),Vector3(.22,.15,.13),Vector3(.32,.105,.10),Vector3(.38,.045,.055)],skin)
	# Broad, volumetric crest grows from the forehead into a swept point.
	build_crest()
	for side in [-1,1]:
		var socket := leaf(head,Vector3(side*.087,.193,-.113),.112,.185,skin)
		socket.rotation.z=-side*.45
		var eye_points := [Vector2(0,.060),Vector2(.034,.028),Vector2(.035,-.021),Vector2(0,-.058),Vector2(-.032,-.022),Vector2(-.033,.027)]
		plate(head,Vector3(side*.087,.193,-.124),eye_points,.008,gold).rotation.z=-side*.45
		plate(head,Vector3(side*.087,.186,-.136),[Vector2(0,.029),Vector2(.006,.013),Vector2(.007,-.02),Vector2(0,-.03),Vector2(-.007,-.019),Vector2(-.006,.012)],.003,dark).rotation.z=-side*.45
		leaf(head,Vector3(side*.107,.079,-.103),.085,.17,skin).rotation.z=-side*.3
	for side in [-1,1]:
		var brow := leaf(head,Vector3(side*.078,.236,-.131),.040,.14,skin)
		brow.rotation.z=side*.75
	# Brow ridge, tapered snout, mouth seam and pointed lower jaw.
	plate(head,Vector3(0,.12,-.145),[Vector2(-.04,.13),Vector2(.04,.13),Vector2(.045,-.03),Vector2(0,-.07),Vector2(-.045,-.03)],.032,skin)
	Geo.link(head,Vector3(-.065,.04,-.137),Vector3(0,.056,-.169),.006,dark)
	Geo.link(head,Vector3(0,.056,-.169),Vector3(.065,.04,-.137),.006,dark)
	leaf(head,Vector3(0,.005,-.135),.13,.115,edge)
	for side in [-1,1]:
		for i in range(3):
			leaf(head,Vector3(side*.13,.06+i*.075,.055),.045,.10,flesh).rotation.y=side*PI/2

func build_arm(side: int) -> void:
	var arm: Node3D = helper.joint(torso,Vector3(side*.33,1.66,0),"ShoulderL" if side<0 else "ShoulderR")
	arms.append(arm)
	arm.rotation.z=side*.1
	shell(arm,Vector3.ZERO,[Vector3(-.31,.075,.075),Vector3(-.20,.105,.10),Vector3(-.055,.125,.11),Vector3(.035,.09,.09)],flesh)
	shell(arm,Vector3(0,.015,0),[Vector3(-.10,.135,.13),Vector3(-.025,.15,.14),Vector3(.055,.09,.09)],flesh)
	for i in range(4):
		var blade := leaf(arm,Vector3(side*(.10+i*.025),-.13-i*.026,.015+i*.035),.073,.31+i*.015,edge if i%2 else skin)
		blade.rotation.z=side*-.32
		blade.rotation.y=side*.55
	var elbow: Node3D = helper.joint(arm,Vector3(0,-.33,0),"Elbow")
	elbows.append(elbow)
	shell(elbow,Vector3.ZERO,[Vector3(-.04,.067,.067),Vector3(.04,.073,.073)],flesh)
	shell(elbow,Vector3.ZERO,[Vector3(-.29,.048,.05),Vector3(-.20,.078,.075),Vector3(-.08,.085,.08),Vector3(-.035,.064,.066)],skin)
	leaf(elbow,Vector3(0,-.16,-.079),.14,.29,skin)
	for i in range(3):
		Geo.ellipsoid(elbow,Vector3(side*.058,-.09-i*.063,-.048),Vector3(.025,.035,.022),edge)
	shell(elbow,Vector3(0,-.33,0),[Vector3(-.065,.057,.035),Vector3(.03,.048,.038)],skin)
	# Three hooked fingers plus an opposed thumb.
	for i in range(3):
		var x := -.041+i*.041
		Geo.link(elbow,Vector3(x,-.37,-.012),Vector3(x*1.22,-.425,-.025),.014,skin)
		Geo.link(elbow,Vector3(x*1.22,-.425,-.025),Vector3(x*1.18,-.45,-.058),.009,claw)
	Geo.link(elbow,Vector3(side*.05,-.32,0),Vector3(side*.085,-.37,-.035),.018,skin)
	Geo.link(elbow,Vector3(side*.085,-.37,-.035),Vector3(side*.07,-.39,-.065),.010,claw)

func build_leg(side: int) -> void:
	var hip: Node3D = helper.joint(self,Vector3(side*.14,.99,0),"HipL" if side<0 else "HipR")
	hips.append(hip)
	shell(hip,Vector3.ZERO,[Vector3(-.38,.078,.08),Vector3(-.24,.115,.115),Vector3(-.09,.13,.13),Vector3(.02,.09,.09)],flesh)
	leaf(hip,Vector3(side*.05,-.11,-.09),.13,.24,flesh).rotation.z=side*.2
	var knee: Node3D = helper.joint(hip,Vector3(0,-.43,0),"Knee")
	knees.append(knee)
	shell(knee,Vector3.ZERO,[Vector3(-.05,.07,.07),Vector3(.04,.08,.08)],flesh)
	leaf(knee,Vector3(0,.005,-.075),.15,.17,skin)
	shell(knee,Vector3.ZERO,[Vector3(-.41,.059,.065),Vector3(-.28,.075,.08),Vector3(-.14,.10,.10),Vector3(-.055,.075,.07)],flesh)
	leaf(knee,Vector3(0,-.22,-.082),.15,.35,skin)
	for i in range(3):
		Geo.ellipsoid(knee,Vector3(side*.044,-.12-i*.07,-.09),Vector3(.025,.03,.018),edge)
	shell(knee,Vector3(0,-.46,-.04),[Vector3(-.09,.078,.13),Vector3(-.065,.085,.145),Vector3(-.02,.074,.11),Vector3(.045,.058,.068)],skin)
	for i in range(3):
		Geo.link(knee,Vector3(-.05+i*.05,-.51,-.13),Vector3(-.05+i*.05,-.535,-.20),.019,claw)

# Shared by the combat actor and the inspection studio. attack_time < 0 means idle.
func animate(phase: float, movement: float, attack_time: float = -1.0) -> void:
	var stride := sin(phase)*movement*.30
	hips[0].rotation.x=stride
	hips[1].rotation.x=-stride
	knees[0].rotation.x=-maxf(0,sin(phase))*movement*.4
	knees[1].rotation.x=-maxf(0,-sin(phase))*movement*.4
	arms[0].rotation.x=-stride*.7
	arms[1].rotation.x=stride*.7
	arms[0].rotation.z=-.10
	arms[1].rotation.z=.10
	elbows[0].rotation.x=-.18
	elbows[1].rotation.x=-.18
	torso.rotation.y=sin(phase)*movement*.045
	torso.rotation.x=0
	if attack_time>=0:
		var pull := clampf(attack_time/.65,0,1)
		var release := clampf((attack_time-.65)/.18,0,1)
		var recover := clampf((attack_time-.83)/.62,0,1)
		arms[1].rotation.x=lerpf(.75,-1.45,release)*(1-recover)*pull
		arms[1].rotation.z=lerpf(.65,-.20,release)*(1-recover)
		elbows[1].rotation.x=-.7*(1-release)-.15
		torso.rotation.y=lerpf(-.22,.28,release)*(1-recover)*pull
		torso.rotation.x=.10*release*(1-recover)


func build_crest() -> void:
	var profile := [Vector4(.20,.072,.10,0),Vector4(.30,.077,.11,.018),Vector4(.39,.055,.09,.042),Vector4(.47,.028,.055,.075),Vector4(.54,.002,.008,.095)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(profile.size()-1):
		for i in range(16):
			var vertices: Array[Vector3]=[]
			for pair in [Vector2i(r,i),Vector2i(r,i+1),Vector2i(r+1,i+1),Vector2i(r+1,i)]:
				var ring: Vector4=profile[pair.x]
				var angle: float=TAU*pair.y/16.0
				vertices.append(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	helper.instance(head,Vector3.ZERO,st.commit(),skin)


func surface_height(x: float, y: float, noise: FastNoiseLite, seed_value: int) -> float:
	var grain := noise.get_noise_2d(x,y)
	var broad := noise.get_noise_2d(x*.31+53,y*.31-17)
	if seed_value==17:
		return .5+.12*sin(y*.24+broad*6.0)+grain*.24
	return .5+grain*.32+broad*.18
