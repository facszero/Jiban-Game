extends RefCounted
## Chamfered equipment plates: actual silhouette and bevel normals, not painted edges.
static func plate(parent: Node3D, pos: Vector3, size: Vector3, material: Material, bevel: float=.04) -> MeshInstance3D:
	var b := minf(bevel,minf(size.x,size.y)*.20)
	var w := size.x*.5
	var h := size.y*.5
	var depth := size.z*.5
	var contour := PackedVector2Array([Vector2(-w+b,-h),Vector2(w-b,-h),Vector2(w,-h+b),Vector2(w,h-b),Vector2(w-b,h),Vector2(-w+b,h),Vector2(-w,h-b),Vector2(-w,-h+b)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var p := contour[i]
		var q := contour[(i+1)%8]
		var inner_p := p*Vector2((w-b*.45)/w,(h-b*.45)/h)
		var inner_q := q*Vector2((w-b*.45)/w,(h-b*.45)/h)
		var a := Vector3(p.x,p.y,depth-minf(b,depth))
		var c := Vector3(q.x,q.y,a.z)
		var f := Vector3(inner_p.x,inner_p.y,depth)
		var g := Vector3(inner_q.x,inner_q.y,depth)
		tri(st,Vector3(0,0,depth),f,g,Vector3.FORWARD*-1)
		var normal := Vector3((p+q).x,(p+q).y,b*10).normalized()
		tri(st,a,c,g,normal)
		tri(st,a,g,f,normal)
		var back_a := Vector3(p.x,p.y,-depth)
		var back_c := Vector3(q.x,q.y,-depth)
		var side_normal := Vector3((p+q).x,(p+q).y,0).normalized()
		tri(st,back_a,back_c,c,side_normal)
		tri(st,back_a,c,a,side_normal)
		tri(st,Vector3(0,0,-depth),back_c,back_a,Vector3(0,0,-1))
	var node := MeshInstance3D.new()
	node.mesh=st.commit()
	node.material_override=material
	node.position=pos
	parent.add_child(node)
	return node
static func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,n: Vector3) -> void:
	for p in [a,c,b]:
		st.set_normal(n)
		st.set_uv(Vector2(p.x,p.y))
		st.add_vertex(p)
static func label(parent: Node3D,pos: Vector3,text: String,width: float,color: Color=Color(.65,.73,.77)) -> Label3D:
	var sign := Label3D.new()
	sign.text=text
	sign.font_size=48
	sign.pixel_size=width/maxf(text.length()*29.0,1.0)
	sign.position=pos
	sign.modulate=color
	sign.outline_size=0
	parent.add_child(sign)
	return sign
