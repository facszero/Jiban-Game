extends Node3D
## Same service pistol in both perspectives. Visual geometry only.
const Armor = preload("res://scripts/jiban_model.gd")
const Geo = preload("res://scripts/geometry.gd")
@export var include_hand := false
func _ready() -> void:
	var mesh_tools = Armor.new()
	var silver = mesh_tools.silver
	var dark = mesh_tools.rubber
	var navy = mesh_tools.navy
	var steel = mesh_tools.steel
	var red = Geo.material(Color(.65,.012,.02),.3,.5)
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
		mesh_tools.shell(self,Vector3(0,-.07,.068),[Vector3(-.043,.038,.038),Vector3(.03,.038,.038)],dark,16)
		for i in range(3):
			Geo.box(self,Vector3(.023,-.047-i*.019,.016),Vector3(.038,.014,.027),dark)
		Geo.box(self,Vector3(-.035,-.045,.046),Vector3(.023,.052,.027),dark).rotation.z=-.25
		mesh_tools.shell(self,Vector3(.006,-.16,.095),[Vector3(-.055,.045,.055),Vector3(.045,.038,.043)],silver,12)
		Geo.box(self,Vector3(.006,-.16,.148),Vector3(.045,.075,.008),navy)
	mesh_tools.merge_parts(self)
	mesh_tools.free()
