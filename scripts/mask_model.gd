extends "res://scripts/jiban_model.gd"
## Fitted cloth and light protection based on the approved Mask design sheet.
var cloth: StandardMaterial3D
var protection: StandardMaterial3D
var insignia: StandardMaterial3D
func _ready() -> void:
	cloth=metal(Color(.024,.029,.034),0,.91)
	protection=metal(Color(.055,.065,.075),.15,.52)
	insignia=metal(Color(.62,.65,.55),.12,.65)
	var img:=Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in range(64):
		for x in range(64):
			var v:=.93 if (x+y)%2==0 else .86
			img.set_pixel(x,y,Color(v,v,v))
	img.generate_mipmaps()
	cloth.albedo_texture=ImageTexture.create_from_image(img)
	cloth.uv1_triplanar=true
	cloth.uv1_scale=Vector3.ONE*10
	super._ready()
func build_torso() -> void:
	shell(upper_body,Vector3.ZERO,[Vector3(.91,.15,.105),Vector3(1.03,.155,.115),Vector3(1.14,.145,.10),Vector3(1.34,.20,.12),Vector3(1.49,.235,.125),Vector3(1.56,.19,.10),Vector3(1.62,.075,.07)],cloth,24)
	shell(upper_body,Vector3.ZERO,[Vector3(1.06,.162,.12),Vector3(1.12,.162,.12)],insignia,24)
	Geo.box(upper_body,Vector3(0,1.09,-.124),Vector3(.085,.058,.014),protection)
	Geo.box(upper_body,Vector3(0,1.09,-.135),Vector3(.067,.043,.006),insignia)
	for spec in [[1.20,.11,.15],[1.35,.126,.15],[1.50,.128,.15],[.99,.116,.12]]:
		Geo.box(upper_body,Vector3(0,spec[0],-spec[1]),Vector3(.026,spec[2],.006),insignia)
	plate(upper_body,Vector3(0,1.565,-.105),[Vector2(-.065,.025),Vector2(.065,.025),Vector2(.018,-.035),Vector2(-.018,-.035)],.004,insignia)
	shell(upper_body,Vector3.ZERO,[Vector3(1.60,.07,.065),Vector3(1.74,.068,.066)],cloth,24)
func build_head() -> void:
	var head:=joint(upper_body,Vector3(0,1.69,0),"MaskHood")
	shell(head,Vector3.ZERO,[Vector3(-.005,.065,.065),Vector3(.045,.087,.085),Vector3(.14,.112,.105),Vector3(.22,.10,.095),Vector3(.27,.065,.065),Vector3(.29,.01,.012)],cloth,32)
	for side in [-1,1]:
		var eye_points := [Vector2(-.045,.035),Vector2(-.012,.031),Vector2(.035,.005),Vector2(.041,-.028),Vector2(.006,-.023),Vector2(-.032,.004)]
		if side>0:
			for i in range(eye_points.size()): eye_points[i].x*=-1
			eye_points.reverse()
		plate(head,Vector3(side*.052,.14,-.093),eye_points,.008,insignia)
		var inset: Array=[]
		for point in eye_points: inset.append(point*.72)
		plate(head,Vector3(side*.052,.14,-.103),inset,.004,rubber)
	Geo.ellipsoid(head,Vector3(0,.232,-.091),Vector3(.037,.037,.009),insignia)
	plate(head,Vector3(0,.045,-.084),[Vector2(-.064,.017),Vector2(-.035,.005),Vector2(0,0),Vector2(.035,.005),Vector2(.064,.017),Vector2(.042,-.020),Vector2(0,-.027),Vector2(-.042,-.020)],.004,insignia)
func build_arm(side: int) -> void:
	var arm:=joint(upper_body,Vector3(side*.24,1.53,0),"LeftShoulder" if side<0 else "RightShoulder")
	shell(arm,Vector3.ZERO,[Vector3(.035,.058,.065),Vector3(-.04,.084,.080),Vector3(-.17,.066,.065),Vector3(-.29,.049,.050)],cloth,24)
	var elbow:=joint(arm,Vector3(0,-.29,0),"Elbow")
	elbows.append(elbow)
	shell(elbow,Vector3.ZERO,[Vector3(.025,.052,.052),Vector3(-.08,.061,.060),Vector3(-.20,.050,.047),Vector3(-.28,.035,.034)],cloth,24)
	plate(elbow,Vector3(0,-.16,-.052),[Vector2(-.048,.09),Vector2(.048,.09),Vector2(.032,-.10),Vector2(-.032,-.10)],.009,protection)
	shell(elbow,Vector3(0,-.30,0),[Vector3(-.06,.038,.028),Vector3(.025,.034,.032)],protection,16)
	for i in range(4):
		Geo.box(elbow,Vector3(-.026+i*.017,-.365,-.008),Vector3(.013,.040,.032),protection)
	Geo.box(elbow,Vector3(side*.035,-.315,-.020),Vector3(.020,.045,.024),protection)
	if side<0:
		arm_left=arm
	else:
		arm_right=arm
		var gun:=joint(elbow,Vector3(0,-.34,-.025),"ServicePistol")
		gun.rotation.x=-PI/2
		gun.add_child(load("res://scripts/service_weapon.gd").new())
func build_leg(side: int) -> void:
	var leg:=joint(pelvis,Vector3(side*.105,.99,0),"LeftHip" if side<0 else "RightHip")
	shell(leg,Vector3.ZERO,[Vector3(.01,.090,.095),Vector3(-.09,.092,.09),Vector3(-.24,.072,.075),Vector3(-.38,.054,.058)],cloth,24)
	var knee:=joint(leg,Vector3(0,-.39,0),"Knee")
	knees.append(knee)
	shell(knee,Vector3.ZERO,[Vector3(.02,.056,.060),Vector3(-.10,.065,.065),Vector3(-.25,.052,.052),Vector3(-.46,.038,.043)],cloth,24)
	plate(knee,Vector3(0,-.25,-.056),[Vector2(-.051,.11),Vector2(.051,.11),Vector2(.035,-.12),Vector2(-.035,-.12)],.008,protection)
	var ankle:=joint(knee,Vector3(0,-.46,0),"Ankle")
	ankles.append(ankle)
	shell(ankle,Vector3(0,-.055,-.038),[Vector3(-.085,.059,.112),Vector3(-.065,.063,.12),Vector3(-.025,.057,.105),Vector3(.045,.038,.065)],protection,24)
	shell(ankle,Vector3(0,-.055,-.038),[Vector3(-.09,.060,.114),Vector3(-.079,.062,.117)],rubber,24)
	if side<0: leg_left=leg
	else: leg_right=leg

func shell(parent: Node3D, at: Vector3, rings: Array, material: Material, segments: int=24) -> MeshInstance3D:
	# Ring order determines outward normals; cloth profiles also need smooth curves.
	var ordered:=rings.duplicate()
	ordered.sort_custom(func(a,b): return a.x<b.x)
	var rounded: Array=[]
	for i in range(ordered.size()-1):
		var a: Vector3=ordered[i]
		var b: Vector3=ordered[i+1]
		for j in range(3):
			var t:=j/3.0
			var v:=a.cubic_interpolate(b,ordered[maxi(0,i-1)],ordered[mini(ordered.size()-1,i+2)],t)
			v.x=lerpf(a.x,b.x,t)
			v.y=maxf(v.y,.005)
			v.z=maxf(v.z,.005)
			rounded.append(v)
	rounded.append(ordered.back())
	return super.shell(parent,at,rounded,material,segments)
