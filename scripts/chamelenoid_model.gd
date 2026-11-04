extends Node3D
## Segmented organic model based on the approved concept sheet; front is -Z.
const MeshTools = preload("res://scripts/jiban_model.gd")
const GAME_SCALE := 1.1
const BODY_WIDTH := 1.25
const BODY_DEPTH := 1.22
const Geo = preload("res://scripts/geometry.gd")
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var ankles: Array[Node3D] = []
var wrists: Array[Node3D] = []
const GAIT_PER_METER := 4.5
var torso: Node3D
var head: Node3D
var jaw: Node3D
var mouth: Node3D
var brows: Array[Node3D] = []
var expression := 0.0
var helper: Node3D
var skin: StandardMaterial3D
var flesh: StandardMaterial3D
var edge: StandardMaterial3D
var gold: StandardMaterial3D
var dark: StandardMaterial3D
var tendon: StandardMaterial3D
var claw: StandardMaterial3D

func organic(color: Color, roughness: float, seed_value: int) -> StandardMaterial3D:
	var mat = MeshTools.metal(color,.05,roughness)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = .24
	var img := Image.create(256,256,false,Image.FORMAT_RGB8)
	var normals := Image.create(256,256,false,Image.FORMAT_RGB8)
	for y in range(256):
		for x in range(256):
			var height := surface_height(x,y,noise,seed_value)
			var n := .40 + height*.90
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
	mat.normal_scale=.65
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE*2.8
	return mat

func _ready() -> void:
	helper = MeshTools.new()
	skin = organic(Color(.27,.33,.20),.55,31)
	flesh = organic(Color(.26,.065,.055),.49,17)
	edge = organic(Color(.36,.39,.20),.78,42)
	gold = MeshTools.metal(Color(.66,.53,.17),.16,.35)
	dark = MeshTools.metal(Color(.018,.022,.012),.0,.6)
	tendon = organic(Color(.30,.09,.075),.57,17)
	claw = MeshTools.metal(Color(.19,.16,.10),.05,.6)
	torso = helper.joint(self,Vector3.ZERO,"Torso")
	build_torso()
	build_head()
	for side in [-1,1]:
		build_arm(side)
		build_leg(side)
	# Broaden anatomy without enlarging the head or stretching the legs vertically.
	torso.scale=Vector3(BODY_WIDTH,1,BODY_DEPTH)
	head.scale=Vector3(1.0/BODY_WIDTH,1,1.0/BODY_DEPTH)
	for hip in hips:
		hip.position.x*=1.18
		hip.scale=Vector3(1.22,1,1.20)
	helper.merge_parts(self)
	helper.free()

func shell(parent: Node3D, pos: Vector3, rings: Array, mat: Material) -> MeshInstance3D:
	# Cubic profiles give flesh continuous bulges instead of conical segments.
	var smooth_rings: Array=[]
	for i in range(rings.size()-1):
		var a: Vector3=rings[maxi(0,i-1)]
		var b: Vector3=rings[i]
		var c: Vector3=rings[i+1]
		var d: Vector3=rings[mini(rings.size()-1,i+2)]
		for j in range(3):
			var t:=float(j)/3.0
			var curve:=b.cubic_interpolate(c,a,d,t)
			curve.x=lerpf(b.x,c.x,t)
			curve.y=maxf(.002,curve.y)
			curve.z=maxf(.002,curve.z)
			smooth_rings.append(curve)
	smooth_rings.append(rings[-1])
	return helper.shell(parent,pos,smooth_rings,mat,24)
func plate(parent: Node3D, pos: Vector3, points: Array, thickness: float, mat: Material, curvature: float = 0.0) -> MeshInstance3D:
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
	var half_height := .001
	for point in outline: half_height=maxf(half_height,absf(point.y-center.y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [1.0,.78,.45,.08]
	for r in range(rings.size()-1):
		for i in range(outline.size()):
			var vertices: Array[Vector3]=[]
			for item in [Vector2i(r,i),Vector2i(r,(i+1)%outline.size()),Vector2i(r+1,(i+1)%outline.size()),Vector2i(r+1,i)]:
				var radius: float=rings[item.x]
				var point: Vector2=center+(outline[item.y]-center)*radius
				vertices.append(Vector3(point.x,point.y,-thickness*(1-radius*radius)+curvature*pow((point.y-center.y)/half_height,2)))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(vertices[index])
	for i in range(outline.size()):
		var a: Vector2=center+(outline[i]-center)*.08
		var b: Vector2=center+(outline[(i+1)%outline.size()]-center)*.08
		for vertex in [Vector3(center.x,center.y,-thickness),Vector3(b.x,b.y,-thickness*.9936),Vector3(a.x,a.y,-thickness*.9936)]:
			st.add_vertex(vertex)
	for i in range(outline.size()):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+1)%outline.size()]
		var za:=curvature*pow((a.y-center.y)/half_height,2)
		var zb:=curvature*pow((b.y-center.y)/half_height,2)
		var wall: Array[Vector3]=[Vector3(a.x,a.y,za),Vector3(b.x,b.y,zb),Vector3(b.x,b.y,zb+.012),Vector3(a.x,a.y,za+.012)]
		for index in [0,1,2,0,2,3]: st.add_vertex(wall[index])
	st.generate_normals()
	st.index()
	return helper.instance(parent,pos,st.commit(),mat)
func leaf(parent: Node3D, pos: Vector3, width: float, length: float, mat: Material) -> MeshInstance3D:
	return plate(parent,pos,[Vector2(-width*.35,length*.5),Vector2(width*.35,length*.5),Vector2(width*.5,length*.18),Vector2(width*.28,-length*.22),Vector2(0,-length*.5),Vector2(-width*.35,-length*.18)],width*.20,mat,.045 if length>.25 else .012)
func build_torso() -> void:
	shell(torso,Vector3.ZERO,[Vector3(.96,.15,.12),Vector3(1.12,.19,.14),Vector3(1.35,.235,.16),Vector3(1.52,.31,.195),Vector3(1.66,.33,.19),Vector3(1.78,.25,.145)],flesh)
	shell(torso,Vector3.ZERO,[Vector3(.88,.16,.12),Vector3(1.02,.23,.15),Vector3(1.13,.19,.13)],flesh)
	for side in [-1,1]:
		# Wide pectoral plates converge into a central keel.
		var chest_points := [Vector2(-.145,.13),Vector2(.025,.15),Vector2(.13,.075),Vector2(.16,.015),Vector2(.10,-.07),Vector2(.025,-.11),Vector2(-.045,-.08),Vector2(-.09,-.14),Vector2(-.145,-.04)]
		if side<0:
			for i in range(chest_points.size()):
				chest_points[i].x *= -1
			chest_points.reverse()
		plate(torso,Vector3(side*.125,1.565,-.194),chest_points,.073,skin)
		leaf(torso,Vector3(side*.15,1.435,-.17),.23,.12,skin).rotation.z=side*.2
		for i in range(3):
			var y := 1.365-i*.105
			leaf(torso,Vector3(side*(.10-i*.012),y,-.15),.205-i*.025,.17,skin).rotation.z=side*.3
		leaf(torso,Vector3(side*.16,1.04,-.13),.19,.20,skin).rotation.z=side*.55
		# Overlapping dorsal plates and maroon rib folds.
		for i in range(3):
			leaf(torso,Vector3(side*(.13-i*.025),1.62-i*.16,.195),.26-i*.035,.26,skin).rotation.y=PI
		for i in range(5):
			Geo.link(torso,Vector3(side*.18,1.16+i*.095,-.06),Vector3(side*(.23+i*.012),1.20+i*.095,.08),.018,flesh)
	for side in [-1,1]:
		for row in range(3):
			leaf(torso,Vector3(side*(.11+row*.025),1.77-row*.035,-.09),.13,.12,flesh).rotation.z=side*.55
		for row in range(3):
			leaf(torso,Vector3(side*.18,1.10+row*.085,-.10),.13,.15,flesh).rotation.y=-side*.7
	leaf(torso,Vector3(0,1.12,-.168),.12,.33,skin)
	for i in range(6):
		leaf(torso,Vector3(0,1.12+i*.1,.205),.07,.13,edge).rotation.y=PI
	shell(torso,Vector3.ZERO,[Vector3(1.72,.14,.12),Vector3(1.80,.125,.11),Vector3(1.91,.095,.09)],flesh)
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
		# Inner corners sit lower than the outer corners: a focused predatory gaze.
		var eye_points := [Vector2(-.047,-.006),Vector2(.040,.036),Vector2(.052,.018),Vector2(.025,-.023),Vector2(-.019,-.028)]
		if side<0:
			for i in range(eye_points.size()): eye_points[i].x*=-1
			eye_points.reverse()
		plate(head,Vector3(side*.087,.193,-.145),eye_points,.010,gold)
		plate(head,Vector3(side*.087,.190,-.161),[Vector2(0,.020),Vector2(.006,.009),Vector2(.006,-.015),Vector2(0,-.022),Vector2(-.006,-.015),Vector2(-.006,.009)],.003,dark)
		leaf(head,Vector3(side*.107,.079,-.110),.10,.19,skin).rotation.z=-side*.3
	for side in [-1,1]:
		var brow: Node3D = helper.joint(head,Vector3(side*.078,.231,-.157),"BrowL" if side<0 else "BrowR")
		brows.append(brow)
		leaf(brow,Vector3.ZERO,.050,.17,skin).rotation.z=-side*1.02
		Geo.link(brow,Vector3(-side*.050,-.025,-.006),Vector3(side*.045,.027,-.006),.007,skin)
	for side in [-1,1]:
		for i in range(4):
			var scale_plate:=leaf(head,Vector3(side*.10,.07+i*.065,.087),.09,.13,skin)
			scale_plate.rotation.y=side*2.3
			scale_plate.rotation.z=side*.4
	# Brow ridge, tapered snout, mouth seam and pointed lower jaw.
	plate(head,Vector3(0,.12,-.145),[Vector2(-.04,.13),Vector2(.04,.13),Vector2(.045,-.03),Vector2(0,-.07),Vector2(-.045,-.03)],.032,skin)
	# Separate mouth and mandible survive material batching and can articulate.
	mouth=helper.joint(head,Vector3(0,.025,-.171),"Mouth")
	mouth.add_child(Node3D.new())
	var cavity:=StandardMaterial3D.new()
	cavity.albedo_color=Color(.025,.005,.008)
	cavity.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	plate(mouth,Vector3.ZERO,[Vector2(-.065,.045),Vector2(.065,.045),Vector2(.070,-.025),Vector2(.035,-.065),Vector2(-.035,-.065),Vector2(-.070,-.025)],.003,cavity)
	for side in [-1,1]:
		var tooth:=MeshInstance3D.new()
		var cone:=CylinderMesh.new()
		cone.top_radius=.008
		cone.bottom_radius=0
		cone.height=.026
		cone.radial_segments=8
		tooth.mesh=cone
		tooth.material_override=edge
		mouth.add_child(tooth)
		tooth.position=Vector3(side*.044,.037,-.019)
	jaw=helper.joint(head,Vector3(0,.055,-.070),"Jaw")
	leaf(jaw,Vector3(0,-.050,-.078),.14,.115,edge)
	Geo.link(jaw,Vector3(-.065,-.013,-.079),Vector3(0,-.014,-.110),.007,dark)
	Geo.link(jaw,Vector3(0,-.014,-.110),Vector3(.065,-.013,-.079),.007,dark)
	mouth.visible=false
	for side in [-1,1]:
		for i in range(3):
			leaf(head,Vector3(side*.13,.06+i*.075,.055),.045,.10,flesh).rotation.y=side*PI/2

func build_arm(side: int) -> void:
	var arm: Node3D = helper.joint(torso,Vector3(side*.33,1.66,0),"ShoulderL" if side<0 else "ShoulderR")
	arms.append(arm)
	arm.rotation.z=side*.1
	shell(arm,Vector3.ZERO,[Vector3(-.32,.072,.075),Vector3(-.26,.095,.10),Vector3(-.16,.118,.12),Vector3(-.055,.125,.11),Vector3(.035,.09,.09)],flesh)
	shell(arm,Vector3(0,.015,0),[Vector3(-.10,.135,.13),Vector3(-.025,.15,.14),Vector3(.055,.09,.09)],flesh)
	var mantle:=shell(arm,Vector3(0,.015,0),[Vector3(-.11,.13,.12),Vector3(-.07,.155,.145),Vector3(.015,.145,.135),Vector3(.075,.075,.075)],flesh)
	mantle.rotation.z=-side*.15
	for i in range(5):
		var blade := leaf(arm,Vector3(side*(.09+i*.014),-.15-i*.018,-.045+i*.040),.085,.33-i*.020,edge if i%2 else skin)
		blade.rotation.z=side*-.32
		blade.rotation.y=side*.85
	for i in range(3):
		var x:=(-1+i)*.035
		Geo.link(arm,Vector3(x,-.10,-.105),Vector3(x*.9,-.21,-.108),.005,tendon)
		Geo.link(arm,Vector3(x*.9,-.21,-.108),Vector3(x*.5,-.29,-.078),.004,tendon)
	var elbow: Node3D = helper.joint(arm,Vector3(0,-.33,0),"Elbow")
	elbows.append(elbow)
	shell(elbow,Vector3.ZERO,[Vector3(-.04,.067,.067),Vector3(.04,.073,.073)],flesh)
	shell(elbow,Vector3.ZERO,[Vector3(-.29,.048,.05),Vector3(-.20,.078,.075),Vector3(-.08,.085,.08),Vector3(-.035,.064,.066)],skin)
	leaf(elbow,Vector3(0,-.16,-.079),.14,.29,skin)
	for i in range(3):
		Geo.ellipsoid(elbow,Vector3(side*.058,-.09-i*.063,-.048),Vector3(.025,.035,.022),edge)
	build_hand(elbow,side)

func build_hand(elbow: Node3D, side: int) -> void:
	var wrist: Node3D=helper.joint(elbow,Vector3(0,-.30,0),"Wrist")
	wrists.append(wrist)
	# Palm normal is local -Z. Mirrored rotation points both palms toward thighs.
	wrist.rotation.y=side*PI/2
	shell(wrist,Vector3.ZERO,[Vector3(-.09,.062,.035),Vector3(-.045,.068,.040),Vector3(.025,.047,.037)],skin)
	leaf(wrist,Vector3(0,-.04,.035),.115,.11,skin).rotation.y=PI
	for i in range(3):
		var x:=(-1+i)*.046
		var length:=.11-absf(float(i-1))*.015
		var p0:=Vector3(x,-.085,0)
		var p1:=Vector3(x*1.1,-.085-length*.55,-.015)
		var p2:=Vector3(x*1.08,-.085-length,-.050)
		var p3:=Vector3(x,-.075-length,-.085)
		Geo.link(wrist,p0,p1,.018,skin)
		Geo.ellipsoid(wrist,p1,Vector3(.019,.020,.018),skin)
		Geo.link(wrist,p1,p2,.015,skin)
		Geo.link(wrist,p2,p3,.012,claw)
	Geo.link(wrist,Vector3(side*.057,-.025,0),Vector3(side*.095,-.065,-.040),.021,skin)
	Geo.link(wrist,Vector3(side*.095,-.065,-.040),Vector3(side*.075,-.10,-.075),.013,claw)

func build_leg(side: int) -> void:
	var hip: Node3D = helper.joint(self,Vector3(side*.14,.99,0),"HipL" if side<0 else "HipR")
	hips.append(hip)
	shell(hip,Vector3.ZERO,[Vector3(-.39,.075,.08),Vector3(-.30,.105,.12),Vector3(-.17,.139,.145),Vector3(-.07,.14,.14),Vector3(.02,.105,.11)],flesh)
	leaf(hip,Vector3(side*.05,-.11,-.09),.13,.24,flesh).rotation.z=side*.2
	for i in range(3):
		var x:=(-1+i)*.04
		Geo.link(hip,Vector3(x,-.08,-.132),Vector3(x*.95,-.22,-.142),.006,tendon)
		Geo.link(hip,Vector3(x*.95,-.22,-.142),Vector3(x*.45,-.36,-.092),.004,tendon)
	var knee: Node3D = helper.joint(hip,Vector3(0,-.43,0),"Knee")
	knees.append(knee)
	shell(knee,Vector3.ZERO,[Vector3(-.05,.07,.07),Vector3(.04,.08,.08)],flesh)
	leaf(knee,Vector3(0,.005,-.075),.15,.17,skin)
	shell(knee,Vector3.ZERO,[Vector3(-.41,.059,.065),Vector3(-.30,.077,.085),Vector3(-.19,.105,.12),Vector3(-.11,.10,.105),Vector3(-.055,.075,.07)],flesh)
	leaf(knee,Vector3(0,-.22,-.121),.18,.39,skin)
	for i in range(3):
		Geo.ellipsoid(knee,Vector3(side*.044,-.12-i*.07,-.09),Vector3(.025,.03,.018),edge)
	var ankle: Node3D = helper.joint(knee,Vector3(0,-.46,0),"Ankle")
	ankles.append(ankle)
	shell(ankle,Vector3(0,0,-.04),[Vector3(-.09,.078,.13),Vector3(-.065,.085,.145),Vector3(-.02,.074,.11),Vector3(.045,.058,.068)],skin)
	for i in range(3):
		Geo.link(ankle,Vector3(-.05+i*.05,-.05,-.13),Vector3(-.05+i*.05,-.075,-.20),.019,claw)

# Shared by the combat actor and the inspection studio. attack_time < 0 means idle.
func animate(phase: float, movement: float, attack_time: float = -1.0) -> void:
	# Long support phase, low foot clearance and a short compression after contact.
	# +X raises a hanging arm towards the model's forward direction (-Z).
	var moving := clampf(movement,0,1)
	if attack_time>=0: moving=0
	var cycle := fposmod(phase/TAU,1.0)
	var contact := fposmod(cycle*2.0,1.0)
	var compression := sin(PI*clampf(contact/.24,0,1))*.025*moving
	var sway := cos(phase)*.032*moving
	var pelvis_y := .94-compression
	var stride := sin(phase)
	for i in range(2):
		var side := -1.0 if i==0 else 1.0
		var step := fposmod(cycle+i*.5,1.0)
		var foot_z: float
		var lift := 0.0
		if step<.66:
			foot_z=lerpf(-.28,.28,step/.66)
		else:
			var swing := (step-.66)/.34
			foot_z=lerpf(.28,-.28,smoothstep(0,1,swing))
			lift=sin(swing*PI)*.10
		foot_z*=moving
		lift*=moving
		hips[i].position=Vector3(side*.14*1.18+sway,pelvis_y,0)
		# Solve the hip/knee chain, keeping the sole level through the step.
		var down := pelvis_y-(.09+lift)
		var reach := clampf(Vector2(down,foot_z).length(),.05,.889)
		var bend := acos(clampf((.43*.43+.46*.46-reach*reach)/(2*.43*.46),-1,1))
		var hip_angle := atan2(-foot_z,down)+acos(clampf((.43*.43+reach*reach-.46*.46)/(2*.43*reach),-1,1))
		hips[i].rotation.x=hip_angle
		knees[i].rotation.x=bend-PI
		ankles[i].rotation.x=-hip_angle-knees[i].rotation.x
		arms[i].rotation=Vector3(.16+side*sin(phase-.35)*.16*moving,0,side*.24)
		elbows[i].rotation.x=.22+side*sin(phase-.65)*.07*moving
		wrists[i].rotation.y=side*PI/2
	torso.rotation=Vector3(-.13-.025*moving,-stride*.065*moving,-sway*.7)
	head.rotation=Vector3(.10,stride*.035*moving,sway*.4)
	if attack_time>=0:
		var pull := smoothstep(0,.65,attack_time)
		var release := smoothstep(.65,.83,attack_time)
		var recover := smoothstep(.83,1.45,attack_time)
		var weight := 1-recover
		wrists[1].rotation.y=lerpf(PI/2,.3,pull*weight)
		arms[1].rotation.x=lerpf(.16,lerpf(.75,1.55,release),pull*weight)
		arms[1].rotation.z=lerpf(.24,lerpf(.65,-.20,release),pull*weight)
		elbows[1].rotation.x=lerpf(.28,lerpf(.85,.18,release),pull*weight)
		torso.rotation.y=lerpf(-.22,.28,release)*weight*pull
		torso.rotation.x-=.10*release*weight
	animate_face(attack_time)
	# Rotate around the waist instead of tipping the whole chest around ground level.
	var pivot := Vector3(0,.99,0)
	torso.position=pivot-Quaternion.from_euler(torso.rotation)*pivot
	torso.position+=Vector3(sway,pelvis_y-.99,0)


func build_crest() -> void:
	var profile := [Vector4(.20,.072,.10,0),Vector4(.30,.077,.11,.018),Vector4(.37,.052,.095,.035),Vector4(.44,.033,.073,.061),Vector4(.50,.018,.043,.085),Vector4(.54,.009,.020,.105),Vector4(.55,.002,.003,.12)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(profile.size()-1):
		for i in range(16):
			var vertices: Array[Vector3]=[]
			for pair in [Vector2i(r,i),Vector2i(r,i+1),Vector2i(r+1,i+1),Vector2i(r+1,i)]:
				var ring: Vector4=profile[pair.x]
				var angle: float=TAU*pair.y/16.0
				vertices.append(Vector3(sin(angle)*ring.y*.60,ring.x,cos(angle)*ring.z+ring.w))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	helper.instance(head,Vector3.ZERO,st.commit(),skin)


func surface_height(x: float, y: float, noise: FastNoiseLite, seed_value: int) -> float:
	var grain := noise.get_noise_2d(x,y)
	var broad := noise.get_noise_2d(x*.31+53,y*.31-17)
	if seed_value==17:
		return .50+noise.get_noise_2d(x*.65+broad*9,y*2.2)*.24+grain*.16
	return .50+grain*.28+broad*.20


func animate_face(attack_time: float) -> void:
	# Anticipation, open-mouth exertion at impact, then a gradual return to rest.
	expression=0.0
	if attack_time>=0:
		expression=smoothstep(.18,.65,attack_time)*(1.0-smoothstep(.86,1.40,attack_time))
	jaw.rotation.x=-.62*expression
	jaw.position.z=-.070-.065*expression
	mouth.visible=expression>.035
	mouth.scale.y=maxf(.08,expression)
	for i in range(brows.size()):
		var side: float=-1.0 if i==0 else 1.0
		brows[i].position.y=.231-.012*expression
		brows[i].rotation.z=side*.12*expression
	head.rotation.x-=.14*expression
