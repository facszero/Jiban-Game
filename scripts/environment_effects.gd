extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const Materials = preload("res://scripts/industrial_materials.gd")
const Hard = preload("res://scripts/hard_surface.gd")
const PUFF_SHADER = preload("res://assets/environment/vapor_puff.gdshader")
var rng := RandomNumberGenerator.new()
var vents: Array = []
var puffs: Array = []
var arc_segments: Array[MeshInstance3D] = []
var sparks: Array = []
var arc_light: OmniLight3D
var arc_audio: AudioStreamPlayer3D
var arc_origin := Vector3(-3.50,2.65,-38.8)
var arc_time := 0.0
var arc_wait := 4.0
var hiss: AudioStreamWAV
var active_puffs := 0
var door_bursts := 0

func _ready() -> void:
	rng.seed=112
	hiss=make_sound(false)
	make_vent(Vector3(-5.05,1.1,-25.3),Vector3(.9,.35,.15),false,1.0)
	make_vent(Vector3(5.05,1.35,-33.3),Vector3(-.9,.3,.15),false,3.0)
	make_vent(Vector3(-2.63,.55,-19.0),Vector3(.28,.6,.6),true,0)
	make_vent(Vector3(2.63,.55,-19.0),Vector3(-.28,.6,.6),true,0)
	build_arc()

func make_sound(electric: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := 4410 if electric else 26460
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var random := RandomNumberGenerator.new()
	random.seed=71 if electric else 29
	var low := 0.0
	for i in range(count):
		var t := float(i)/count
		var n := random.randf_range(-1,1)
		low=lerpf(low,n,.14)
		var sample := (n-low)*.28 if electric else low*.9+(n-low)*.07
		var envelope := pow(1.0-t,3.0) if electric else sin(PI*t)*(.75+.25*sin(t*11))
		bytes.encode_s16(i*2,int(sample*envelope*19000))
	var sound := AudioStreamWAV.new()
	sound.format=AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate=rate
	sound.data=bytes
	return sound

func audio_at(pos: Vector3,stream: AudioStreamWAV,volume: float) -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.position=pos
	audio.stream=stream
	audio.volume_db=volume
	audio.max_distance=16
	audio.unit_size=3
	add_child(audio)
	return audio

func make_vent(pos: Vector3,direction: Vector3,door_only: bool,delay: float) -> void:
	var metal := Materials.metal()
	var dark := Geo.material(Color(.035,.04,.045),.6)
	Geo.link(self,Vector3(pos.x,.25,pos.z),pos-Vector3(0,.08,0),.085,metal)
	if not door_only:
		Geo.link(self,Vector3(pos.x,.25,pos.z),Vector3(signf(pos.x)*5.8,.25,pos.z),.085,metal)
	Geo.link(self,pos-Vector3(0,.08,0),pos,.075,metal)
	Geo.link(self,pos-direction*.11,pos+direction*.05,.10,dark)
	var rim := Geo.cylinder(self,pos,.12,.045,metal)
	rim.quaternion=Quaternion(Vector3.UP,direction.normalized())
	var vent := {"pos":pos,"direction":direction,"door_only":door_only,"wait":delay,"remaining":0.0,"emit":0.0,"audio":audio_at(pos,hiss,-10),"pool":[]}
	for i in range(16):
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size=Vector2.ONE
		mesh.mesh=quad
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader=PUFF_SHADER
		material.set_shader_parameter("seed",rng.randf()*80)
		material.set_shader_parameter("tint",Vector3(.66,.69,.72) if door_only else Vector3(.66,.56,.54))
		mesh.material_override=material
		mesh.visible=false
		add_child(mesh)
		var puff := {"mesh":mesh,"material":material,"age":10.0,"life":1.7,"velocity":Vector3.ZERO,"origin":pos,"spin":rng.randf()*TAU}
		puffs.append(puff)
		vent.pool.append(puff)
	vents.append(vent)

func start_vent(index: int) -> void:
	var vent: Dictionary=vents[index]
	vent.remaining=.72 if vent.door_only else .90
	vent.emit=0.0
	vent.audio.play()

func release_door() -> void:
	door_bursts+=1
	start_vent(2)
	start_vent(3)

func build_arc() -> void:
	var dark := Geo.material(Color(.025,.03,.04),.5)
	Hard.plate(self,arc_origin+Vector3(0,0,-.10),Vector3(.92,.75,.22),Materials.metal(),.06)
	Hard.plate(self,arc_origin+Vector3(0,0,.03),Vector3(.75,.56,.05),dark,.035)
	Hard.plate(self,arc_origin+Vector3(0,.46,0),Vector3(.92,.17,.05),dark,.02)
	Hard.label(self,arc_origin+Vector3(0,.46,.03),"ALTA TENSIÓN",.85,Color(.7,.47,.17))
	for side in [-1,1]:
		Geo.link(self,arc_origin+Vector3(side*.27,-.1,.07),arc_origin+Vector3(side*.27,.1,.12),.055,Materials.metal())
		Geo.link(self,arc_origin+Vector3(side*.27,-.1,.07),arc_origin+Vector3(side*.27,-.7,-.02),.022,dark)
	var glow := Geo.material(Color(.42,.7,1),0,4)
	for i in range(9):
		var segment := Geo.cylinder(self,Vector3.ZERO,.009,1,glow)
		segment.visible=false
		segment.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc_segments.append(segment)
	var amber := Geo.material(Color(1,.5,.08),0,3)
	for i in range(8):
		var mesh := Geo.ellipsoid(self,arc_origin,Vector3(.025,.06,.025),amber)
		mesh.visible=false
		sparks.append({"mesh":mesh,"velocity":Vector3.ZERO})
	arc_light=Geo.light(self,arc_origin+Vector3(0,0,.3),Color(.35,.6,1),0,2.3)
	arc_audio=audio_at(arc_origin,make_sound(true),-9)

func fire_arc() -> void:
	arc_time=.28
	arc_audio.play()
	var previous := arc_origin+Vector3(-.27,.1,.12)
	for i in range(9):
		var next := arc_origin+Vector3(lerpf(-.27,.27,(i+1)/9.0),.1+(rng.randf_range(-.085,.085) if i<8 else 0),.12)
		var segment: MeshInstance3D=arc_segments[i]
		segment.position=(previous+next)*.5
		segment.scale.y=previous.distance_to(next)
		segment.quaternion=Quaternion(Vector3.UP,(next-previous).normalized())
		previous=next
	for spark in sparks:
		spark.mesh.position=arc_origin+Vector3(0,.1,.14)
		spark.velocity=Vector3(rng.randf_range(-.6,.6),rng.randf_range(.3,1.0),rng.randf_range(.2,.6))

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	for index in range(vents.size()):
		var vent: Dictionary=vents[index]
		if not vent.door_only:
			vent.wait-=delta
			if vent.wait<=0:
				vent.wait=rng.randf_range(5.5,8.5)
				if camera!=null and camera.global_position.distance_to(vent.pos)<22: start_vent(index)
		if vent.remaining>0:
			vent.remaining-=delta
			vent.emit-=delta
			if vent.emit<=0:
				vent.emit=.065
				for puff in vent.pool:
					if puff.age>=puff.life:
						puff.age=0.0
						puff.life=rng.randf_range(1.25,1.8)
						puff.origin=vent.pos
						puff.velocity=vent.direction*rng.randf_range(.8,1.25)+Vector3(rng.randf_range(-.09,.09),0,rng.randf_range(-.09,.09))
						break
	active_puffs=0
	for puff in puffs:
		puff.age+=delta
		var alive: bool=puff.age<puff.life
		puff.mesh.visible=alive
		if not alive: continue
		active_puffs+=1
		var t: float=puff.age/puff.life
		puff.mesh.position=puff.origin+puff.velocity*puff.age+Vector3.UP*puff.age*puff.age*.17
		var size: float=.10+.92*t
		if camera!=null: puff.mesh.basis=camera.global_basis*Basis(Vector3.FORWARD,puff.spin+t*.4)
		puff.mesh.scale=Vector3.ONE*size
		puff.material.set_shader_parameter("opacity",sin(PI*t)*.68)
		puff.material.set_shader_parameter("age",puff.age)
	arc_wait-=delta
	if arc_wait<=0:
		arc_wait=rng.randf_range(6.5,10.0)
		if camera!=null and camera.global_position.distance_to(arc_origin)<20: fire_arc()
	arc_time=maxf(0,arc_time-delta)
	var lit := arc_time>.16
	for segment in arc_segments: segment.visible=lit
	arc_light.light_energy=1.7 if lit else 0.0
	for spark in sparks:
		spark.mesh.visible=arc_time>0
		if arc_time>0:
			spark.velocity.y-=delta*4.0
			spark.mesh.position+=spark.velocity*delta
