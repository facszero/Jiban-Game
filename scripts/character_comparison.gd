extends Node3D
const Geo=preload("res://scripts/geometry.gd")
var characters: Array[Node3D]=[]
func _ready() -> void:
	var scripts=[preload("res://scripts/jiban_model.gd"),preload("res://scripts/mask_model.gd"),preload("res://scripts/chamelenoid_model.gd")]
	for i in range(3):
		var character: Node3D=scripts[i].new()
		add_child(character)
		character.position.x=[-1.7,0.0,1.8][i]
		if i==2: character.scale=Vector3.ONE*scripts[i].GAME_SCALE
		characters.append(character)
		var label:=Label3D.new()
		label.text=["JIBAN","MASK","CHAMELENOID"][i]
		label.font_size=44
		label.pixel_size=.004
		label.position=Vector3(character.position.x,.04,-.5)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	Geo.box(self,Vector3(0,-.04,0),Vector3(6.5,.06,2.2),Geo.material(Color(.08,.10,.13),0))
	var line=Geo.material(Color(.25,.40,.45),0)
	for i in range(7):
		Geo.box(self,Vector3(i-3,.0,0),Vector3(.012,.008,2.2),line)
	for z in [-1.0,0.0,1.0]:
		Geo.box(self,Vector3(0,0,z),Vector3(6.5,.008,.012),line)
	animate_all(0,false)
func animate_all(phase: float, walking: bool) -> void:
	if characters.size()!=3: return
	characters[0].animate(phase,1.0 if walking else 0.0,false)
	characters[1].animate(phase,1.0 if walking else 0.0,false)
	characters[2].animate(phase,1.0 if walking else 0.0)
