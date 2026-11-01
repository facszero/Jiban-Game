extends Node3D
## Armor authored as fitted cross sections and beveled plates; front faces -Z.
const Geo = preload("res://scripts/geometry.gd")
var arm_left: Node3D
var arm_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var elbows: Array[Node3D] = []
var knees: Array[Node3D] = []
var silver := metal(Color(.36,.40,.46),.65,.42)
var navy := metal(Color(.018,.040,.085),.5,.38)
var rubber := metal(Color(.013,.018,.025),.1,.62)
var steel := metal(Color(.19,.24,.30),.65,.35)
var gold := metal(Color(.76,.50,.12),.65,.3)
var red := metal(Color(.8,.008,.02),.35,.22)
static func metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	mat.metallic=metallic
	mat.roughness=roughness
	return mat
func _ready() -> void:
	red.emission_enabled=true
	red.emission=Color(.85,.005,.015)
	red.emission_energy_multiplier=.8
	build_torso()
	build_head()
	for side in [-1,1]:
		build_arm(side)
		build_leg(side)
	merge_parts(self)
func joint(parent: Node3D, at: Vector3, title: String) -> Node3D:
	var node := Node3D.new()
	node.name=title
	parent.add_child(node)
	node.position=at
	return node
func instance(parent: Node3D, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	parent.add_child(node)
	node.position=at
	return node
# Each ring contains height, half width, half depth.
func shell(parent: Node3D, at: Vector3, rings: Array, material: Material, segments: int=24) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings.size()-1):
		for i in range(segments):
			var points: Array[Vector3]=[]
			for pair in [Vector2i(r,i),Vector2i(r,i+1),Vector2i(r+1,i+1),Vector2i(r+1,i)]:
				var ring: Vector3=rings[pair.x]
				var angle: float=TAU*pair.y/float(segments)
				points.append(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z))
			for idx in [0,2,1,0,3,2]:
				st.add_vertex(points[idx])
	for end in [0,rings.size()-1]:
		var ring: Vector3=rings[end]
		for i in range(segments):
			var a := TAU*i/float(segments)
			var b := TAU*(i+1)/float(segments)
			var p := Vector3(sin(a)*ring.y,ring.x,cos(a)*ring.z)
			var q := Vector3(sin(b)*ring.y,ring.x,cos(b)*ring.z)
			st.add_vertex(Vector3(0,ring.x,0))
			st.add_vertex(q if end==0 else p)
			st.add_vertex(p if end==0 else q)
	st.generate_normals()
	st.index()
	return instance(parent,at,st.commit(),material)
# Outline clockwise in XY, bevel toward -Z.
func plate(parent: Node3D, at: Vector3, outline: Array, depth: float, material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	for p in outline:
		center+=p
	center/=outline.size()
	for i in range(outline.size()):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+1)%outline.size()]
		var ai: Vector2=center+(a-center)*.88
		var bi: Vector2=center+(b-center)*.88
		var v := [Vector3(a.x,a.y,0),Vector3(b.x,b.y,0),Vector3(bi.x,bi.y,-depth),Vector3(ai.x,ai.y,-depth)]
		for idx in [0,2,1,0,3,2]:
			st.add_vertex(v[idx])
		for p in [Vector3(center.x,center.y,-depth),v[2],v[3]]:
			st.add_vertex(p)
	st.generate_normals()
	st.index()
	return instance(parent,at,st.commit(),material)
func ribs(parent: Node3D, y: float, count: int, radius: float, depth: float) -> void:
	for i in range(count):
		var h := y+i*.023
		shell(parent,Vector3.ZERO,[Vector3(h,radius,depth),Vector3(h+.008,radius+.005,depth+.005),Vector3(h+.018,radius,depth)],rubber,16)
func build_torso() -> void:
	shell(self,Vector3.ZERO,[Vector3(1.04,.15,.11),Vector3(1.18,.17,.12),Vector3(1.40,.255,.145),Vector3(1.59,.23,.12)],rubber)
	shell(self,Vector3.ZERO,[Vector3(1.30,.16,.115),Vector3(1.36,.23,.145),Vector3(1.50,.265,.145),Vector3(1.60,.225,.12)],silver)
	plate(self,Vector3(0,1.46,-.145),[Vector2(-.23,.12),Vector2(.23,.12),Vector2(.24,-.015),Vector2(.16,-.12),Vector2(-.16,-.12),Vector2(-.24,-.015)],.035,navy)
	plate(self,Vector3(0,1.46,.145),[Vector2(-.20,.1),Vector2(.20,.1),Vector2(.23,-.04),Vector2(.13,-.13),Vector2(-.13,-.13),Vector2(-.23,-.04)],.028,silver).rotation.y=PI
	plate(self,Vector3(0,1.55,.16),[Vector2(-.16,.025),Vector2(.16,.025),Vector2(.14,-.027),Vector2(-.14,-.027)],.008,navy).rotation.y=PI
	for side in [-1,1]:
		Geo.box(self,Vector3(side*.13,1.46,.174),Vector3(.007,.12,.006),steel)
		for y in [1.40,1.52]:
			Geo.box(self,Vector3(side*.18,y,.162),Vector3(.012,.012,.006),steel)
	for i in range(4):
		Geo.box(self,Vector3(0,1.49+i*.014,.178),Vector3(.085,.007,.008),rubber)
		var y := 1.12+i*.053
		shell(self,Vector3.ZERO,[Vector3(y,.159+i*.005,.119),Vector3(y+.04,.166+i*.005,.128)],navy)
		plate(self,Vector3(0,y+.02,-.128),[Vector2(-.075,.018),Vector2(.075,.018),Vector2(.07,-.018),Vector2(-.07,-.018)],.012,navy)
	shell(self,Vector3.ZERO,[Vector3(.94,.14,.10),Vector3(1.01,.19,.13),Vector3(1.095,.17,.12)],navy)
	shell(self,Vector3.ZERO,[Vector3(1.07,.18,.132),Vector3(1.13,.18,.132)],silver)
	Geo.box(self,Vector3(0,1.10,-.146),Vector3(.105,.057,.03),steel)
	Geo.box(self,Vector3(0,1.10,-.166),Vector3(.068,.025,.012),red)
	for side in [-1,1]:
		Geo.box(self,Vector3(side*.135,1.1,-.11),Vector3(.045,.065,.055),silver)
		Geo.box(self,Vector3(side*.175,1.1,.01),Vector3(.026,.043,.055),steel)
		plate(self,Vector3(side*.174,1.57,-.12),[Vector2(-.022,.025),Vector2(.022,.025),Vector2(.025,-.08),Vector2(-.025,-.08)],.012,silver).rotation.x=-.35
	plate(self,Vector3(-.115,1.49,-.184),[Vector2(-.031,.038),Vector2(.031,.038),Vector2(.027,-.018),Vector2(0,-.043),Vector2(-.027,-.018)],.006,gold)
	Geo.box(self,Vector3(-.115,1.49,-.194),Vector3(.006,.052,.004),navy)
	Geo.box(self,Vector3(-.115,1.50,-.194),Vector3(.042,.006,.004),navy)
	ribs(self,1.60,4,.079,.075)
func build_head() -> void:
	var head := joint(self,Vector3(0,1.69,0),"Helmet")
	shell(head,Vector3.ZERO,[Vector3(0,.073,.076),Vector3(.065,.119,.112),Vector3(.17,.125,.119),Vector3(.23,.107,.106),Vector3(.267,.06,.068),Vector3(.278,.008,.015)],navy,32)
	for entry in [[.13,.165,silver],[.105,.125,red],[.085,.10,steel]]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(20):
			var a := PI*.40+PI*1.20*i/20.0
			var b := PI*.40+PI*1.20*(i+1)/20.0
			var points := [Vector3(sin(a)*.128,entry[0],cos(a)*.124),Vector3(sin(b)*.128,entry[0],cos(b)*.124),Vector3(sin(b)*.128,entry[1],cos(b)*.124),Vector3(sin(a)*.128,entry[1],cos(a)*.124)]
			for idx in [0,2,1,0,3,2]:
				st.add_vertex(points[idx])
		st.generate_normals()
		instance(head,Vector3.ZERO,st.commit(),entry[2])
	plate(head,Vector3(0,.148,-.122),[Vector2(-.115,.018),Vector2(.115,.018),Vector2(.118,-.016),Vector2(-.118,-.016)],.008,silver)
	plate(head,Vector3(0,.045,-.10),[Vector2(-.105,.04),Vector2(.105,.04),Vector2(.065,-.035),Vector2(.035,-.06),Vector2(-.035,-.06),Vector2(-.065,-.035)],.022,silver)
	plate(head,Vector3(0,-.003,-.124),[Vector2(-.032,.017),Vector2(.032,.017),Vector2(.024,-.014),Vector2(-.024,-.014)],.009,steel)
	Geo.box(head,Vector3(0,.031,-.124),Vector3(.003,.065,.003),steel)
	for i in range(3):
		Geo.box(head,Vector3(-.018+i*.018,-.004,-.135),Vector3(.008,.006,.004),rubber)
	for side in [-1,1]:
		plate(head,Vector3(side*.085,.035,-.089),[Vector2(-.014,.033),Vector2(.014,.033),Vector2(.01,-.03),Vector2(-.01,-.03)],.009,steel).rotation.y=side*.45
	var crown := SurfaceTool.new()
	crown.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [Vector2(.14,-.126),Vector2(.17,-.123),Vector2(.23,-.110),Vector2(.267,-.072),Vector2(.282,-.016),Vector2(.282,.016),Vector2(.267,.072),Vector2(.23,.110),Vector2(.17,.123),Vector2(.14,.126)]
	for i in range(profile.size()-1):
		var a: Vector2=profile[i]
		var b: Vector2=profile[i+1]
		var points := [Vector3(-.018,a.x,a.y),Vector3(.018,a.x,a.y),Vector3(.018,b.x,b.y),Vector3(-.018,b.x,b.y)]
		for idx in [0,2,1,0,3,2]:
			crown.add_vertex(points[idx])
	crown.generate_normals()
	instance(head,Vector3.ZERO,crown.commit(),silver)
	for side in [-1,1]:
		shell(head,Vector3(side*.126,.10,0),[Vector3(-.007,.045,.045),Vector3(.007,.045,.045)],silver).rotation.z=PI/2
		shell(head,Vector3(side*.138,.10,0),[Vector3(-.003,.032,.032),Vector3(.003,.032,.032)],steel,20).rotation.z=PI/2
		Geo.box(head,Vector3(side*.145,.10,0),Vector3(.008,.048,.007),silver)
	for i in range(3):
		Geo.box(head,Vector3(0,.08+i*.012,.115),Vector3(.052,.005,.007),rubber)
func build_arm(side: int) -> void:
	var arm := joint(self,Vector3(side*.285,1.55,0),"LeftShoulder" if side<0 else "RightShoulder")
	arm.rotation.z=side*.07
	shell(arm,Vector3.ZERO,[Vector3(-.16,.085,.09),Vector3(-.06,.112,.123),Vector3(.035,.10,.112),Vector3(.07,.055,.07)],silver)
	plate(arm,Vector3(side*.025,-.035,-.117),[Vector2(-.045,.055),Vector2(.045,.055),Vector2(.05,-.055),Vector2(-.05,-.055)],.009,navy)
	shell(arm,Vector3.ZERO,[Vector3(-.27,.062,.065),Vector3(-.14,.082,.079)],silver)
	var elbow := joint(arm,Vector3(0,-.29,0),"Elbow")
	elbows.append(elbow)
	ribs(elbow,-.045,4,.063,.065)
	shell(elbow,Vector3.ZERO,[Vector3(-.23,.052,.061),Vector3(-.20,.063,.07),Vector3(-.075,.075,.075),Vector3(-.055,.066,.069)],silver)
	plate(elbow,Vector3(0,-.13,-.075),[Vector2(-.035,.065),Vector2(.035,.065),Vector2(.027,-.08),Vector2(-.027,-.08)],.012,navy)
	ribs(elbow,-.27,2,.048,.05)
	shell(elbow,Vector3(0,-.30,0),[Vector3(-.04,.045,.035),Vector3(.025,.05,.038)],rubber,16)
	plate(elbow,Vector3(0,-.30,.038),[Vector2(-.035,.027),Vector2(.035,.027),Vector2(.03,-.025),Vector2(-.03,-.025)],.008,silver).rotation.y=PI
	for f in range(4):
		Geo.box(elbow,Vector3(-.031+f*.021,-.351,-.005),Vector3(.017,.045,.042),rubber)
	Geo.box(elbow,Vector3(side*.046,-.315,-.025),Vector3(.025,.053,.028),rubber)
	if side<0:
		arm_left=arm
	else:
		arm_right=arm
		var gun := joint(elbow,Vector3(0,-.34,-.025),"ServicePistol")
		gun.rotation.x=PI/2
		var pistol = load("res://scripts/service_weapon.gd").new()
		gun.add_child(pistol)
func build_leg(side: int) -> void:
	var leg := joint(self,Vector3(side*.12,.99,0),"LeftHip" if side<0 else "RightHip")
	shell(leg,Vector3.ZERO,[Vector3(-.34,.072,.078),Vector3(-.25,.084,.088),Vector3(-.055,.098,.10),Vector3(0,.083,.083)],silver)
	plate(leg,Vector3(0,-.17,-.09),[Vector2(-.045,.11),Vector2(.045,.11),Vector2(.038,-.12),Vector2(-.038,-.12)],.009,silver)
	var knee := joint(leg,Vector3(0,-.39,0),"Knee")
	knees.append(knee)
	ribs(knee,-.055,5,.066,.065)
	plate(knee,Vector3(0,0,-.071),[Vector2(-.06,.055),Vector2(.06,.055),Vector2(.065,-.005),Vector2(.035,-.07),Vector2(-.035,-.07),Vector2(-.065,-.005)],.025,silver)
	shell(knee,Vector3.ZERO,[Vector3(-.43,.059,.067),Vector3(-.30,.065,.074),Vector3(-.15,.085,.09),Vector3(-.08,.076,.079)],silver)
	plate(knee,Vector3(0,-.26,-.083),[Vector2(-.047,.105),Vector2(.047,.105),Vector2(.031,-.14),Vector2(-.031,-.14)],.014,navy)
	ribs(knee,-.46,2,.059,.066)
	shell(knee,Vector3(0,-.51,-.042),[Vector3(-.085,.071,.135),Vector3(-.06,.075,.14),Vector3(-.02,.067,.128),Vector3(.045,.06,.075)],silver)
	shell(knee,Vector3(0,-.51,-.042),[Vector3(-.09,.074,.139),Vector3(-.073,.074,.139)],rubber)
	plate(knee,Vector3(0,-.49,-.13),[Vector2(-.037,.02),Vector2(.037,.02),Vector2(.045,-.045),Vector2(-.045,-.045)],.006,navy)
	if side<0:
		leg_left=leg
	else:
		leg_right=leg
func animate(phase: float, movement: float, aiming: bool) -> void:
	var stride := sin(phase)*movement*.40
	leg_left.rotation.x=stride
	leg_right.rotation.x=-stride
	knees[0].rotation.x=-maxf(0,sin(phase))*movement*.55
	knees[1].rotation.x=-maxf(0,-sin(phase))*movement*.55
	arm_left.rotation.x=-stride*.65
	arm_right.rotation.x=-1.45 if aiming else stride*.65
	elbows[0].rotation.x=-.12-absf(stride)*.3
	elbows[1].rotation.x=-.12
func merge_parts(parent: Node3D) -> void:
	# Geo.box uses an unanimated Node3D wrapper; bake that transform before batching.
	for wrapper in parent.get_children():
		if wrapper is Node3D and not wrapper is MeshInstance3D and wrapper.get_script() == null and wrapper.get_child_count() == 1 and wrapper.get_child(0) is MeshInstance3D:
			var mesh: MeshInstance3D = wrapper.get_child(0)
			var baked: Transform3D = wrapper.transform * mesh.transform
			wrapper.remove_child(mesh)
			parent.add_child(mesh)
			mesh.transform = baked
			parent.remove_child(wrapper)
			wrapper.free()
	var groups := {}
	for child in parent.get_children():
		if child is MeshInstance3D:
			var mat: Material=child.material_override
			if not groups.has(mat):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[mat]=st
			groups[mat].append_from(child.mesh,0,child.transform)
			parent.remove_child(child)
			child.free()
		elif child is Node3D:
			merge_parts(child)
	for mat in groups:
		instance(parent,Vector3.ZERO,groups[mat].commit(),mat)

