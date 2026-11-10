extends "res://scripts/jiban_model.gd"
## Meshy surface driven by the existing, tested locomotion controller.
var skin_skeleton: Skeleton3D
var skin_visual: Node3D
var proxy_nodes := {}
var proxy_rest := {}
var skin_rest := []
var gait_phase := 0.0
var gait_movement := 0.0
var gait_running := 0.0
var gait_aiming := 0.0
var gait_direction := Vector2(0,-1)
var gait_grounded := true
func stride_half(run: float, aim: float) -> float:
	return lerpf(.36,.52,run)*lerpf(1.0,.85,aim)
func stance_fraction(run: float) -> float:
	return lerpf(.56,.42,run)
func update_locomotion(delta: float, local_velocity: Vector3, running: bool, aiming: bool, grounded: bool, turn_speed: float = 0.0) -> void:
	var previous_phase := locomotion_phase
	super.update_locomotion(delta,local_velocity,running,aiming,grounded,turn_speed)
	var speed := Vector2(local_velocity.x,local_velocity.z).length()
	locomotion_phase=previous_phase
	if speed>.08 and grounded:
		locomotion_phase+=speed*delta*TAU*stance_fraction(run_blend)/(2.0*stride_half(run_blend,aim_blend))
	pose(locomotion_phase,move_blend,run_blend,aim_blend,travel,grounded)
func neutralize_arms() -> bool:
	return false
func asset_path() -> String:
	return "res://assets/jiban_meshy/jiban.glb"
func _ready() -> void:
	super._ready()
	remove_proxy_meshes(self)
	proxy_nodes={"pelvis":pelvis,"chest":upper_body,"head":upper_body,
		"upper_arm.L":arm_left,"upper_arm.R":arm_right,
		"forearm.L":elbows[0],"forearm.R":elbows[1],
		"hand.L":elbows[0],"hand.R":elbows[1],
		"thigh.L":leg_left,"thigh.R":leg_right,
		"shin.L":knees[0],"shin.R":knees[1],
		"foot.L":ankles[0],"foot.R":ankles[1]}
	for key in proxy_nodes: proxy_rest[key]=global_basis.inverse()*proxy_nodes[key].global_basis
	skin_visual=load(asset_path()).instantiate()
	skin_visual.rotation.y=PI
	add_child(skin_visual)
	find_skin(skin_visual)
	assert(skin_skeleton!=null)
	for i in range(skin_skeleton.get_bone_count()):
		var rest := skin_skeleton.get_bone_global_rest(i).basis
		var key := skin_skeleton.get_bone_name(i)
		if neutralize_arms() and (key.begins_with("upper_arm.") or key.begins_with("forearm.") or key.begins_with("hand.")):
			var conversion := skin_skeleton.global_basis.inverse()*global_basis
			var axis := (conversion.inverse()*rest.y).normalized()
			var outward := -.16 if key.ends_with(".L") else .16
			var relaxed := Vector3(outward,-1,0).normalized()
			rest=conversion*Basis(Quaternion(axis,relaxed))*conversion.inverse()*rest
		skin_rest.append(rest)
	pose(0,0,0,0,Vector2(0,-1),true)
func remove_proxy_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D: child.free()
		else: remove_proxy_meshes(child)
func find_skin(node: Node) -> void:
	if node is Skeleton3D: skin_skeleton=node
	for child in node.get_children():find_skin(child)
func pose(phase: float,movement: float,running: float,aiming: float,direction: Vector2,grounded: bool) -> void:
	super.pose(phase,movement,running,aiming,direction,grounded)
	gait_phase=phase
	gait_movement=movement
	gait_running=running
	gait_aiming=aiming
	gait_direction=direction
	gait_grounded=grounded
	# Small vertical travel, relaxed shoulders and opposite arm/leg timing.
	var bob := movement*(lerpf(.015,.10,running)+lerpf(.055,.07,running)*pow(cos(phase),2))
	pelvis.position=Vector3(sin(phase)*.008*movement,.99-bob,0)+Vector3(direction.x,0,direction.y)*lerpf(.085,.11,running)*movement
	pelvis.rotation=Vector3.ZERO
	upper_body.position=Vector3(pelvis.position.x*.5,1.2-bob,0)
	upper_body.rotation=Vector3((.10+.035*running)*direction.y*movement,-sin(phase)*.025*movement*(1-aiming),-sin(phase)*.008*movement)
	arm_left.rotation.z=-.07
	arm_right.rotation.z=.07
	var swing := cos(phase)*movement*lerpf(.20,.34,running)
	arm_left.rotation.x=lerpf(.04-swing,.65,aiming)
	arm_right.rotation.x=lerpf(.04+swing,PI/2-.12-upper_body.rotation.x,aiming)
	elbows[0].rotation.x=lerpf(.12+running*.25,.6,aiming)
	elbows[1].rotation.x=lerpf(.12+running*.25,.12,aiming)
	sync_skin()
func sync_skin() -> void:
	if skin_skeleton==null:return
	var desired := []
	var conversion: Basis=skin_skeleton.global_basis.inverse()*global_basis
	for i in range(skin_skeleton.get_bone_count()):
		var key: String=skin_skeleton.get_bone_name(i)
		var delta: Basis=global_basis.inverse()*proxy_nodes[key].global_basis*proxy_rest[key].inverse()
		desired.append(conversion*delta*conversion.inverse()*skin_rest[i])
	solve_skin_legs(desired,conversion)
	for i in range(skin_skeleton.get_bone_count()):
		var parent: int=skin_skeleton.get_bone_parent(i)
		var parent_basis: Basis=desired[parent] if parent>=0 else Basis.IDENTITY
		var local: Basis=parent_basis.inverse()*desired[i]
		skin_skeleton.set_bone_pose_rotation(i,local.orthonormalized().get_rotation_quaternion())
	var hip: int=skin_skeleton.find_bone("pelvis")
	var shift: Vector3=pelvis.position-Vector3(0,.99,0)
	skin_skeleton.set_bone_pose_position(hip,skin_skeleton.get_bone_rest(hip).origin+conversion*shift)
	skin_skeleton.force_update_all_bone_transforms()

# Solve the imported chain itself, rather than adding angles from differently
# proportioned proxy legs to its already bent bind pose.
func solve_skin_legs(desired: Array, conversion: Basis) -> void:
	var to_model := global_transform.affine_inverse()*skin_skeleton.global_transform
	var shift := pelvis.position-Vector3(0,.99,0)
	for i in range(2):
		var side := "L" if i==0 else "R"
		var thigh := skin_skeleton.find_bone("thigh."+side)
		var shin := skin_skeleton.find_bone("shin."+side)
		var foot := skin_skeleton.find_bone("foot."+side)
		var h := to_model*skin_skeleton.get_bone_global_rest(thigh).origin
		var k := to_model*skin_skeleton.get_bone_global_rest(shin).origin
		var a := to_model*skin_skeleton.get_bone_global_rest(foot).origin
		var upper := h.distance_to(k)
		var lower := k.distance_to(a)
		var hip := h+shift
		var cycle := fposmod(gait_phase/TAU+i*.5,1.0)
		var stance := stance_fraction(gait_running)
		var swing := clampf((cycle-stance)/(1.0-stance),0,1)
		var half_step := stride_half(gait_running,gait_aiming)
		var travel_z := lerpf(-half_step,half_step,cycle/stance) if cycle<stance else half_step*cos(PI*swing)
		var lift := sin(PI*swing)*lerpf(.095,.14,gait_running) if cycle>=stance else 0.0
		# Keep the ankle under its hip and use the real bone lengths.
		var floor_height := a.y
		var target := Vector3(h.x,floor_height,h.z)+Vector3(-gait_direction.x,0,-gait_direction.y)*travel_z*gait_movement
		target.y+=lift*gait_movement
		# Peel the heel away before recovery, with the toe as the support pivot.
		var peel := smoothstep(stance*.76,stance,cycle) if cycle<stance else 0.0
		var foot_roll := -.30*peel if cycle<stance else lerpf(-.30,.08,smoothstep(0,.65,swing))*(1-smoothstep(.75,1,swing))
		foot_roll*=gait_movement
		var sole_pivot := Vector3(0,-floor_height,-.16)
		var foot_rotation := Basis(Vector3.RIGHT,foot_roll)
		var pivot_shift := sole_pivot-foot_rotation*sole_pivot
		target+=pivot_shift
		if not gait_grounded:target=Vector3(h.x,floor_height+.08,.04 if i==0 else -.04)
		var reach := target-hip
		var distance := minf(reach.length(),(upper+lower)*.998)
		var axis := reach.normalized()
		var pole := Vector3.FORWARD-axis*Vector3.FORWARD.dot(axis)
		pole=pole.normalized()
		var along := (upper*upper-lower*lower+distance*distance)/(2.0*distance)
		var knee := hip+axis*along+pole*sqrt(maxf(0,upper*upper-along*along))
		var ankle := hip+axis*distance
		for spec in [[thigh,k-h,knee-hip],[shin,a-k,ankle-knee]]:
			var rotation := Basis(Quaternion((spec[1] as Vector3).normalized(),(spec[2] as Vector3).normalized()))
			desired[spec[0]]=conversion*rotation*conversion.inverse()*skin_rest[spec[0]]
		# Keep the soles level instead of inheriting knee twist.
		desired[foot]=conversion*foot_rotation*conversion.inverse()*skin_rest[foot]
