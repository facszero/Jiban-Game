extends SceneTree
var failures := 0
func _initialize():call_deferred("run")
func point(model, bone: String) -> Vector3:
	return model.to_local(model.skin_skeleton.to_global(model.skin_skeleton.get_bone_global_pose(model.skin_skeleton.find_bone(bone)).origin))
func check(ok: bool,label: String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failures+=1
func run():
	for character in ["jiban","bioron"]:
		var model=load("res://scripts/"+character+"_meshy_model.gd").new()
		root.add_child(model)
		var height_error := 0.0
		var knee_side_error := 0.0
		var planted_drift := 0.0
		var min_knee_forward := INF
		for running in [0.0,1.0]:
			for direction in [Vector2(0,-1),Vector2(0,1),Vector2(1,0),Vector2(-1,0)]:
				var previous := Vector3.ZERO
				var stance: float=model.stance_fraction(running)
				var half_step: float=model.stride_half(running,0)
				for frame in range(96):
					var cycle := float(frame)/96.0
					model.pose(cycle*TAU,1,running,0,direction,true)
					for side in ["L","R"]:
						var hip := point(model,"thigh."+side)
						var knee := point(model,"shin."+side)
						var ankle := point(model,"foot."+side)
						var axis := (ankle-hip).normalized()
						var offset := knee-hip-axis*(knee-hip).dot(axis)
						var plane_normal := axis.cross(Vector3.FORWARD).normalized()
						knee_side_error=maxf(knee_side_error,absf(offset.dot(plane_normal)))
						min_knee_forward=minf(min_knee_forward,offset.dot(Vector3.FORWARD))
					var foot := point(model,"foot.L")
					if cycle<stance*.76:
						var rest_y: float=model.to_local(model.skin_skeleton.to_global(model.skin_skeleton.get_bone_global_rest(model.skin_skeleton.find_bone("foot.L")).origin)).y
						height_error=maxf(height_error,absf(foot.y-rest_y))
						if frame>0:
							var expected := Vector3(-direction.x,0,-direction.y)*(2*half_step/stance/96.0)
							planted_drift=maxf(planted_drift,(foot-previous-expected).length())
					previous=foot
		print(character," support=",height_error," knee_side=",knee_side_error," drift=",planted_drift," knee_forward=",min_knee_forward)
		check(height_error<.02,character+" planted foot stays near ground")
		check(knee_side_error<.003 and min_knee_forward>0,character+" knees bend forward without side twist across whole cycles")
		check(planted_drift<.012,character+" stance follows travel in all directions")
		model.free()
	print("HUMANOID GAIT RESULT: %d failures"%failures)
	quit(1 if failures else 0)
