extends CharacterBody3D

signal fired(origin: Vector3, target: Vector3)
signal damaged
signal died
const Geo = preload("res://scripts/geometry.gd")
@export var walk_speed := 4.0
@export var run_speed := 6.5
@export var damage := 25.0
@export var sensitivity := 0.0025
var health := 180.0
var energy := 120.0
var ammo := 12
var reserve := 72
var cooldown := 0.0
var reload_time := 0.0
var hurt_time := 0.0
var first_person := false
var pitch := -0.04
var pivot: Node3D
var camera: Camera3D
var body_model: Node3D
var arm_left: Node3D
var arm_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var view_weapon: Node3D
var flash: OmniLight3D
var step_clock := 0.0
var lamp: SpotLight3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 5
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.9
	col.shape = shape
	col.position.y = 0.95
	add_child(col)
	build_model()
	Geo.light(self, Vector3(0, 2.4, 2.0), Color(0.65, 0.78, 1.0), 1.4, 7.0)
	pivot = Node3D.new()
	pivot.position.y = 1.72
	add_child(pivot)
	camera = Camera3D.new()
	pivot.add_child(camera)
	camera.current = true
	camera.near = 0.06
	view_weapon = Node3D.new()
	camera.add_child(view_weapon)
	build_view_weapon()

	flash = Geo.light(camera, Vector3(0.2, 0, -0.65), Color(0.3, 0.8, 1.0), 0.0, 6.0)
	lamp = SpotLight3D.new()
	camera.add_child(lamp)
	lamp.light_color = Color(0.7, 0.85, 1.0)
	lamp.light_energy = 3.0
	lamp.spot_range = 24.0
	lamp.spot_angle = 32.0
	lamp.visible = false
	update_camera(1.0)

func build_model() -> void:
	body_model = Node3D.new()
	add_child(body_model)
	var silver := Geo.material(Color(0.48, 0.59, 0.7), 0.85)
	var blue := Geo.material(Color(0.025, 0.07, 0.19), 0.7)
	var black := Geo.material(Color(0.02, 0.027, 0.04), 0.45)
	var red := Geo.material(Color(1.0, 0.02, 0.04), 0.4, 2.0)
	Geo.armor(body_model, Vector3(0, 1.25, 0), Vector3(0.72, 0.5, 0.42), silver, 0.68)
	Geo.box(body_model, Vector3(0, 1.3, -0.2), Vector3(0.40, 0.29, 0.045), blue)
	Geo.box(body_model, Vector3(0, 1.3, 0.2), Vector3(0.40, 0.29, 0.045), blue)
	Geo.box(body_model, Vector3(0, 0.91, 0), Vector3(0.5, 0.22, 0.3), black)
	Geo.box(body_model, Vector3(0, 0.84, 0), Vector3(0.57, 0.1, 0.35), silver)
	Geo.ellipsoid(body_model, Vector3(0, 1.75, 0), Vector3(0.46, 0.45, 0.42), blue)
	Geo.box(body_model, Vector3(0, 1.68, -0.15), Vector3(0.4, 0.19, 0.2), silver)
	Geo.box(body_model, Vector3(0, 1.78, -0.25), Vector3(0.4, 0.055, 0.04), red)
	Geo.box(body_model, Vector3(0, 1.97, -0.02), Vector3(0.13, 0.035, 0.35), silver)
	# Rounded helmet dome, jaw vents, temple plates and police chest hardware.
	Geo.ellipsoid(body_model, Vector3(0, 1.82, 0), Vector3(0.47, 0.42, 0.43), blue)
	Geo.box(body_model, Vector3(0, 1.79, -0.253), Vector3(0.43, 0.045, 0.04), red)
	Geo.box(body_model, Vector3(0, 1.62, -0.24), Vector3(0.18, 0.055, 0.07), black)
	Geo.box(body_model, Vector3(0, 1.92, -0.21), Vector3(0.10, 0.09, 0.035), silver)
	Geo.box(body_model, Vector3(0, 1.94, -0.235), Vector3(0.045, 0.025, 0.02), red)
	for side in [-1, 1]:
		Geo.ellipsoid(body_model, Vector3(side * 0.225, 1.76, 0), Vector3(0.065, 0.16, 0.2), silver)
		Geo.box(body_model, Vector3(side * 0.29, 1.29, -0.22), Vector3(0.06, 0.37, 0.06), silver)
		Geo.box(body_model, Vector3(side * 0.16, 1.32, 0.225), Vector3(0.025, 0.22, 0.025), silver)
		for y in [0.94, 1.00, 1.06]:
			Geo.box(body_model, Vector3(side * 0.18, y, -0.17), Vector3(0.12, 0.025, 0.04), silver)
	Geo.box(body_model, Vector3(0, 0.84, -0.2), Vector3(0.16, 0.09, 0.06), blue)
	Geo.box(body_model, Vector3(-0.15, 1.39, -0.24), Vector3(0.1, 0.1, 0.035), silver).rotation.z = PI / 4.0
	for i in range(3):
		Geo.box(body_model, Vector3(0.08 + i * 0.045, 1.19, -0.24), Vector3(0.025, 0.04, 0.02), red if i == 0 else silver)

	for side in [-1, 1]:
		var leg := Node3D.new()
		body_model.add_child(leg)
		leg.position = Vector3(side * 0.17, 1.0, 0)
		leg.scale = Vector3(0.95, 1.25, 0.95)
		Geo.ellipsoid(leg, Vector3(0, -0.18, 0), Vector3(0.25, 0.38, 0.28), blue)
		Geo.ellipsoid(leg, Vector3(0, -0.37, -0.04), Vector3(0.27, 0.17, 0.3), silver)
		Geo.armor(leg, Vector3(0, -0.53, 0), Vector3(0.25, 0.35, 0.29), silver, 0.68)
		Geo.ellipsoid(leg, Vector3(0, -0.72, -0.055), Vector3(0.25, 0.16, 0.36), black)
		var arm := Node3D.new()
		body_model.add_child(arm)
		arm.position = Vector3(side * 0.43, 1.53, 0)
		arm.scale = Vector3(0.9, 1.06, 0.9)
		Geo.ellipsoid(arm, Vector3(0, -0.06, 0), Vector3(0.28, 0.23, 0.34), silver)
		Geo.box(arm, Vector3(side * 0.1, -0.07, 0), Vector3(0.08, 0.18, 0.29), blue)
		Geo.box(arm, Vector3(0, -0.28, 0), Vector3(0.17, 0.25, 0.2), black)
		Geo.ellipsoid(arm, Vector3(0, -0.49, -0.05), Vector3(0.21, 0.28, 0.23), silver)
		Geo.ellipsoid(arm, Vector3(0, -0.65, -0.06), Vector3(0.16, 0.17, 0.18), black)
		if side == -1:
			leg_left = leg
			arm_left = arm
		else:
			leg_right = leg
			arm_right = arm
	Geo.box(arm_right, Vector3(0, -0.65, -0.15), Vector3(0.13, 0.17, 0.46), silver)

	# Raise the waist/hips and reduce the helmet to an adult heroic silhouette.
	# The collision capsule and camera stay stable; only visual geometry changes.
	for part in body_model.get_children():
		if part == leg_left or part == leg_right or part == arm_left or part == arm_right:
			continue
		if part.position.y > 1.57:
			part.position = Vector3(0, 1.83, 0) + (part.position - Vector3(0, 1.8, 0)) * 0.8
			part.scale *= 0.8
		elif part.position.y < 1.1:
			part.position.y += 0.16
		else:
			part.position.y += 0.08
	Geo.cylinder(body_model, Vector3(0, 1.64, 0), 0.105, 0.13, black)
	Geo.ellipsoid(body_model, Vector3(0, 0.97, 0), Vector3(0.43, 0.28, 0.3), blue)

func _unhandled_input(event: InputEvent) -> void:
	if health <= 0.0 or get_tree().paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.25, 1.25)
	if event.is_action_pressed("view"):
		first_person = not first_person
	if event.is_action_pressed("reload"):
		reload_weapon()
	if event.is_action_pressed("scan"):
		lamp.visible = not lamp.visible

func _physics_process(delta: float) -> void:
	if health <= 0.0:
		return
	var devices := Input.get_connected_joypads()
	if not devices.is_empty():
		var look := Vector2(Input.get_joy_axis(devices[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(devices[0], JOY_AXIS_RIGHT_Y))
		if look.length() > 0.2:
			rotate_y(-look.x * 2.1 * delta)
			pitch = clampf(pitch - look.y * 1.6 * delta, -1.25, 1.25)
	cooldown = maxf(0.0, cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	flash.light_energy = maxf(0.0, flash.light_energy - delta * 65.0)
	if reload_time > 0.0:
		reload_time -= delta
		if reload_time <= 0.0:
			var amount := mini(12 - ammo, reserve)
			ammo += amount
			reserve -= amount
	var axis := Input.get_vector("left", "right", "forward", "back")
	var direction := global_basis * Vector3(axis.x, 0, axis.y)
	var running := Input.is_action_pressed("sprint") and energy > 1.0 and axis.length() > 0.1
	var speed := run_speed if running else walk_speed
	energy = clampf(energy + (-18.0 if running else 12.0) * delta, 0.0, 120.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 6.0
	move_and_slide()
	if global_position.y < -12.0:
		take_damage(999.0)
	step_clock += Vector2(velocity.x, velocity.z).length() * delta * 2.2
	var stride := sin(step_clock) * minf(axis.length(), 1.0) * 0.4
	leg_left.rotation.x = stride
	leg_right.rotation.x = -stride
	arm_left.rotation.x = -stride * 0.5
	arm_right.rotation.x = -1.35 if Input.is_action_pressed("aim") or Input.is_action_pressed("fire") else stride * 0.4
	update_camera(delta)
	if Input.is_action_pressed("fire"):
		shoot()

func update_camera(delta: float) -> void:
	pivot.rotation.x = pitch
	body_model.visible = not first_person
	view_weapon.visible = first_person
	var desired := Vector3.ZERO if first_person else Vector3(0.65, 0.25, 3.5)
	if not first_person and Input.is_action_pressed("aim"):
		desired = Vector3(0.6, 0.15, 1.8)
	if not first_person:
		# A swept sphere protects the camera near corners, not just its center ray.
		var sphere := SphereShape3D.new()
		sphere.radius = 0.18
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform = Transform3D(Basis.IDENTITY, pivot.global_position)
		query.motion = pivot.global_basis * desired
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var fractions := get_world_3d().direct_space_state.cast_motion(query)
		desired *= maxf(0.0, fractions[0] - 0.025)
	camera.position = desired
	if first_person:
		camera.rotation = Vector3.ZERO
	else:
		# Both views converge on the sight line from Jiban's visor.
		# Changing perspective preserves the intended target at close range.
		var aim_point := pivot.global_position - pivot.global_basis.z * 90.0
		var aim_hit := ray(pivot.global_position, aim_point)
		if not aim_hit.is_empty():
			aim_point = aim_hit.position
		if camera.global_position.distance_squared_to(aim_point) > 0.01:
			camera.look_at(aim_point, Vector3.UP)
	camera.fov = lerpf(camera.fov, 60.0 if Input.is_action_pressed("aim") else 76.0, minf(1.0, delta * 12.0))

func ray(from: Vector3, to: Vector3, mask: int = 5) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func shoot() -> void:
	if cooldown > 0.0 or reload_time > 0.0 or health <= 0.0:
		return
	if ammo <= 0:
		reload_weapon()
		return
	ammo -= 1
	cooldown = 0.24
	var target := camera.global_position - camera.global_basis.z * 90.0
	var aim_hit := ray(camera.global_position, target)
	if not aim_hit.is_empty():
		target = aim_hit.position
	# Resolve damage from the same body muzzle in either perspective, so walls block it.
	var muzzle := global_position + global_basis * Vector3(0.32, 1.45, -0.5)
	var hit := ray(muzzle, target + (target - muzzle).normalized() * 0.05)
	if not hit.is_empty():
		target = hit.position
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage)
	flash.light_energy = 7.0
	fired.emit(muzzle, target)

func reload_weapon() -> void:
	if ammo < 12 and reserve > 0 and reload_time <= 0.0:
		reload_time = 1.2

func take_damage(amount: float) -> void:
	if hurt_time > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	hurt_time = 0.35
	damaged.emit()
	if health <= 0.0:
		died.emit()


func build_view_weapon() -> void:
	var silver := Geo.material(Color(0.46, 0.53, 0.61), 0.85)
	var dark := Geo.material(Color(0.025, 0.04, 0.065), 0.5)
	var blue := Geo.material(Color(0.035, 0.10, 0.22), 0.6)
	var red := Geo.material(Color(0.8, 0.03, 0.015), 0.2, 0.8)
	# Farther from the eye and lower in frame; an identifiable receiver and grip.
	view_weapon.position = Vector3(0.28, -0.24, -0.72)
	Geo.armor(view_weapon, Vector3(0, 0, 0), Vector3(0.12, 0.3, 0.095), silver, 0.85).rotation.x = PI / 2.0
	Geo.box(view_weapon, Vector3(0, 0.05, -0.03), Vector3(0.085, 0.025, 0.24), blue)
	Geo.box(view_weapon, Vector3(0, -0.085, 0.09), Vector3(0.08, 0.14, 0.085), dark).rotation.x = -0.2
	Geo.box(view_weapon, Vector3(0, -0.07, 0), Vector3(0.065, 0.015, 0.095), silver)
	Geo.box(view_weapon, Vector3(0, -0.04, -0.045), Vector3(0.065, 0.07, 0.015), silver)
	Geo.box(view_weapon, Vector3(0, 0.005, -0.17), Vector3(0.08, 0.065, 0.055), dark)
	Geo.box(view_weapon, Vector3(0, 0.005, -0.2), Vector3(0.045, 0.034, 0.012), black_muzzle())
	Geo.box(view_weapon, Vector3(0, 0.078, -0.11), Vector3(0.018, 0.025, 0.025), red)
	for i in range(4):
		Geo.box(view_weapon, Vector3(0.056, 0.008, -0.08 + i * 0.045), Vector3(0.006, 0.035, 0.012), dark)
	Geo.ellipsoid(view_weapon, Vector3(0, -0.12, 0.13), Vector3(0.12, 0.11, 0.13), dark)
	Geo.armor(view_weapon, Vector3(0.015, -0.21, 0.17), Vector3(0.15, 0.14, 0.16), silver)

func black_muzzle() -> Material:
	return Geo.material(Color(0.004, 0.006, 0.009))
