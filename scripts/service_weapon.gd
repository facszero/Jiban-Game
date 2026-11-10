extends Node3D
## Same service pistol in both perspectives. Visual geometry only.
const Armor = preload("res://scripts/jiban_model.gd")
const Geo = preload("res://scripts/geometry.gd")
const MUZZLE_POSITION := Vector3(0, 0, -0.181)
var muzzle: Marker3D
@export var include_hand := false
@export var include_pistol_mesh := true
func _ready() -> void:
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	add_child(muzzle)
	muzzle.position = MUZZLE_POSITION
	var mesh_tools = Armor.new()
	var silver = mesh_tools.silver
	var dark = mesh_tools.rubber
	var navy = mesh_tools.navy
	var steel = mesh_tools.steel
	var red = Geo.material(Color(.65,.012,.02),.3,.5)
	if include_pistol_mesh:
		# Shaped slide with beveled end caps, instead of a solid octagonal rod.
		mesh_tools.shell(self,Vector3.ZERO,[Vector3(-.16,.026,.027),Vector3(-.14,.035,.033),Vector3(.065,.035,.033),Vector3(.08,.026,.027)],silver,8).rotation.x=PI/2
		Geo.box(self,Vector3(0,.035,-.035),Vector3(.046,.012,.19),navy)
		Geo.box(self,Vector3(0,-.063,.042),Vector3(.043,.105,.052),dark).rotation.x=-.2
		Geo.box(self,Vector3(0,-.117,.052),Vector3(.052,.013,.055),steel)
		# Trigger guard and trigger are separate visible parts.
		Geo.box(self,Vector3(0,-.055,-.032),Vector3(.026,.009,.071),steel)
		Geo.box(self,Vector3(0,-.032,-.067),Vector3(.026,.05,.009),steel)
		Geo.box(self,Vector3(0,-.031,-.012),Vector3(.012,.03,.009),dark).rotation.x=.25
		mesh_tools.shell(self,Vector3(0,0,-.169),[Vector3(-.007,.023,.023),Vector3(.007,.023,.023)],steel,20).rotation.x=PI/2
		mesh_tools.shell(self,Vector3(0,0,-.178),[Vector3(-.002,.014,.014),Vector3(.002,.014,.014)],dark,20).rotation.x=PI/2
		for side in [-1,1]:
			Geo.box(self,Vector3(side*.036,.003,-.06),Vector3(.003,.023,.085),dark)
			Geo.box(self,Vector3(side*.038,.003,-.06),Vector3(.002,.008,.065),red)
			for i in range(4):
				Geo.box(self,Vector3(side*.036,.005,.015+i*.013),Vector3(.003,.037,.004),dark)
		Geo.box(self,Vector3(0,.047,-.12),Vector3(.012,.015,.014),red)
		for side in [-1,1]:
			Geo.box(self,Vector3(side*.018,.045,.057),Vector3(.008,.014,.018),steel)
	if include_hand:
		# The hand wraps the grip; the forearm continues behind the lower screen edge.
		var glove = Armor.metal(Color(.075,.09,.115),.12,.60)
		mesh_tools.shell(self,Vector3(0,-.067,.065),[Vector3(-.052,.044,.044),Vector3(.028,.043,.044)],glove,16)
		for i in range(3):
			var y := -.043-i*.023
			Geo.box(self,Vector3(.026,y,.018),Vector3(.047,.018,.034),glove)
			Geo.box(self,Vector3(.046,y,.043),Vector3(.018,.016,.027),steel)
		# Thumb crosses the near side of the grip; plates make the glove readable in shadow.
		Geo.box(self,Vector3(-.034,-.044,.087),Vector3(.027,.057,.034),glove).rotation.z=-.35
		Geo.box(self,Vector3(0,-.066,.111),Vector3(.047,.052,.008),silver)
		for i in range(3):
			Geo.box(self,Vector3(-.016+i*.016,-.025,.103),Vector3(.012,.013,.013),steel)
		var forearm := Node3D.new()
		forearm.name = "ViewForearm"
		add_child(forearm)
		forearm.position = Vector3(.006,-.112,.076)
		forearm.rotation.x = -.5
		mesh_tools.ribs(forearm,-.055,3,.040,.045)
		mesh_tools.shell(forearm,Vector3.ZERO,[Vector3(-.48,.085,.085),Vector3(-.30,.073,.076),Vector3(-.09,.052,.058),Vector3(-.045,.043,.048)],silver,16)
		mesh_tools.plate(forearm,Vector3(0,-.23,.073),[Vector2(-.042,.13),Vector2(.042,.13),Vector2(.058,-.16),Vector2(-.058,-.16)],.009,navy).rotation.y=PI
	mesh_tools.merge_parts(self)
	mesh_tools.free()

