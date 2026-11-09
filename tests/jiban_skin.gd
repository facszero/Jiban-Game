extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func find_mesh(node):
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found=find_mesh(child)
		if found!=null:return found
	return null
func run():
	var model=load("res://scripts/jiban_meshy_model.gd").new()
	root.add_child(model)
	var mesh=find_mesh(model.skin_visual)
	var arrays=mesh.mesh.surface_get_arrays(0)
	var vertices=arrays[Mesh.ARRAY_VERTEX]
	var bones=arrays[Mesh.ARRAY_BONES]
	var weights=arrays[Mesh.ARRAY_WEIGHTS]
	var indices=arrays[Mesh.ARRAY_INDEX]
	var count:int=weights.size()/vertices.size()
	for spec in [["idle",0,0,0,0],["walk",PI/2,1,0,0],["run",PI/2,1,1,0],["aim",0,0,0,1],["aim_walk",PI/2,1,0,1]]:
		model.pose(spec[1],spec[2],spec[3],spec[4],Vector2(0,-1),true)
		var transforms=[]
		for bind in range(mesh.skin.get_bind_count()):
			var bone:int=mesh.skin.get_bind_bone(bind)
			if bone<0:bone=model.skin_skeleton.find_bone(mesh.skin.get_bind_name(bind))
			transforms.append(model.skin_skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind))
		var posed=PackedVector3Array()
		var floor_y:float=INF
		for i in range(vertices.size()):
			var v=Vector3.ZERO
			for slot in range(count):
				var w:float=weights[i*count+slot]
				if w>0:v+=(transforms[bones[i*count+slot]]*vertices[i])*w
			posed.append(v);floor_y=minf(floor_y,v.y)
		var worst:float=0
		for t in range(0,indices.size(),3):
			for pair in [[indices[t],indices[t+1]],[indices[t+1],indices[t+2]],[indices[t+2],indices[t]]]:
				var d:float=vertices[pair[0]].distance_to(vertices[pair[1]])
				if d>.004:
					var ratio:float=posed[pair[0]].distance_to(posed[pair[1]])/d
					if ratio>worst and ratio>10:print("EDGE ",vertices[pair[0]]," / ",vertices[pair[1]])
					worst=maxf(worst,ratio)
		print("SKIN ",spec[0]," stretch=",worst," floor=",floor_y)
		if worst>5 or floor_y<-.08:failures+=1
	model.free()
	print("JIBAN SKIN RESULT: %d failures"%failures)
	quit(1 if failures else 0)
