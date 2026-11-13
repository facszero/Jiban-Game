extends Node3D
## Fixed right glove around the service pistol, in pistol-local coordinates.
var glove: StandardMaterial3D
var finger_paths := []
func _ready() -> void:
	glove=StandardMaterial3D.new()
	glove.albedo_color=Color(.032,.039,.047)
	glove.roughness=.66
	glove.metallic=.04
	ellipsoid(Vector3(.009,-.067,.077),Vector3(.037,.048,.027))
	# A rounded cuff bridges the imported wrist without an open seam.
	ellipsoid(Vector3(0,-.065,.113),Vector3(.032,.033,.036))
	for y in [-.055,-.078,-.100]:
		tube([Vector3(.028,y,.078),Vector3(.046,y,.051),Vector3(.043,y,.027),Vector3(.023,y,.010),Vector3(-.008,y,.012),Vector3(-.027,y,.029),Vector3(-.025,y,.044)],.0105)
	# Index reaches the trigger guard; thumb crosses the opposite grip face.
	tube([Vector3(.030,-.030,.075),Vector3(.044,-.026,.043),Vector3(.042,-.025,.007),Vector3(.029,-.025,-.022),Vector3(.012,-.026,-.030),Vector3(.003,-.030,-.018)],.010)
	tube([Vector3(-.010,-.037,.093),Vector3(-.030,-.027,.077),Vector3(-.043,-.029,.051),Vector3(-.038,-.036,.028),Vector3(-.027,-.041,.017)],.013)
func ellipsoid(center: Vector3,size: Vector3) -> void:
	var instance:=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=1
	sphere.height=2
	sphere.radial_segments=16
	sphere.rings=10
	instance.mesh=sphere
	instance.material_override=glove
	instance.position=center
	instance.scale=size
	add_child(instance)
func tube(points: Array, radius: float) -> void:
	finger_paths.append(points)
	var samples: Array[Vector3]=[]
	for segment in range(points.size()-1):
		var a: Vector3=points[maxi(0,segment-1)]
		var b: Vector3=points[segment]
		var c: Vector3=points[segment+1]
		var d: Vector3=points[mini(points.size()-1,segment+2)]
		for step in range(3):samples.append(b.cubic_interpolate(c,a,d,step/3.0))
	samples.append(points[-1])
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array=[]
	for i in range(samples.size()):
		var tangent: Vector3=(samples[mini(i+1,samples.size()-1)]-samples[maxi(0,i-1)]).normalized()
		var u:=tangent.cross(Vector3.UP).normalized()
		if u.length()<.1:u=tangent.cross(Vector3.RIGHT).normalized()
		var v:=tangent.cross(u).normalized()
		var ring: Array[Vector3]=[]
		var taper:=lerpf(1.0,.72,float(i)/(samples.size()-1))
		for j in range(10):ring.append(samples[i]+(u*cos(TAU*j/10)+v*sin(TAU*j/10))*radius*taper)
		rings.append(ring)
	for i in range(rings.size()-1):
		for j in range(10):
			var k: int=(j+1)%10
			for vertex in [rings[i][j],rings[i+1][j],rings[i+1][k],rings[i][j],rings[i+1][k],rings[i][k]]:st.add_vertex(vertex)
	st.generate_normals()
	var instance:=MeshInstance3D.new()
	instance.mesh=st.commit()
	instance.material_override=glove
	add_child(instance)
	ellipsoid(samples[-1],Vector3.ONE*radius*.74)
