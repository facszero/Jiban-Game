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
var view_pistol: Node3D
var view_weapon: Node3D
const WEAPON_REST := Vector3(0.23, -0.22, -0.77)
var weapon_clearance := 1.0
var weapon_probe := SphereShape3D.new()
var flash: OmniLight3D
var step_clock := 0.0
var last_visual_yaw := 0.0
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
	Geo.light(self, Vector3(0, 2.4, 2.0), Color(0.75, 0.82, 1.0), 0.65, 7.0)
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
	body_model = preload("res://scripts/jiban_model.gd").new()
	add_child(body_model)
	arm_left = body_model.arm_left
	arm_right = body_model.arm_right
	leg_left = body_model.leg_left
	leg_right = body_model.leg_right

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
	var turn_speed := angle_difference(last_visual_yaw,rotation.y)/maxf(delta,.001)
	last_visual_yaw=rotation.y
	body_model.update_locomotion(delta,global_basis.inverse()*velocity,running,Input.is_action_pressed("aim") or Input.is_action_pressed("fire"),is_on_floor(),turn_speed)
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
	update_weapon_clearance(delta)
	camera.fov = lerpf(camera.fov, 60.0 if Input.is_action_pressed("aim") else 76.0, minf(1.0, delta * 12.0))

func update_weapon_clearance(delta: float) -> void:
	if not first_person:
		view_weapon.visible = false
		return
	# A swept volume covers barrel, receiver and hand, including off-centre obstacles.
	weapon_probe.radius = 0.28
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = weapon_probe
	query.transform = Transform3D(Basis.IDENTITY, camera.global_position)
	query.collision_mask = 5
	query.exclude = [get_rid()]
	var space := get_world_3d().direct_space_state
	var safe := 0.0
	if space.intersect_shape(query, 1).is_empty():
		query.motion = camera.global_basis * Vector3(0.28, -0.30, -0.74)
		var fractions := space.cast_motion(query)
		safe = 1.0 if fractions[0] >= 1.0 else maxf(0.0, fractions[0] - 0.08)
	# Retreat immediately to prevent a one-frame intersection; ease back out.
	weapon_clearance = minf(safe, move_toward(weapon_clearance, safe, delta * 5.0))
	view_weapon.position = WEAPON_REST * weapon_clearance
	view_weapon.scale = Vector3.ONE * maxf(weapon_clearance, 0.01)
	# At contact, lower the weapon out of view instead of displaying a clipped mesh.
	view_weapon.visible = weapon_clearance >= 0.65

func ray(from: Vector3, to: Vector3, mask: int = 5) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [get_rid()])
	query.hit_from_inside = true
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
	# The muzzle can extend beyond a close surface even though the body cannot.
	var hit := ray(pivot.global_position, muzzle, 1)
	if not hit.is_empty():
		muzzle = pivot.global_position
	else:
		hit = ray(muzzle, target + (target - muzzle).normalized() * 0.05)
	if not hit.is_empty():
		target = hit.position
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage)
	# Keep physical damage resolution above; render the shot from the visible barrel.
	var visual_origin := muzzle
	if first_person and view_weapon.visible:
		visual_origin = view_pistol.get_node("Muzzle").global_position
		# A visual ray must not cross a surface between the barrel and resolved impact.
		var visual_hit := ray(visual_origin, target)
		if not visual_hit.is_empty():
			target = visual_hit.position
	flash.global_position = visual_origin
	flash.light_energy = 7.0
	fired.emit(visual_origin, target)

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
	view_weapon.position = WEAPON_REST
	view_pistol = preload("res://scripts/service_weapon.gd").new()
	view_pistol.include_hand = true
	view_weapon.add_child(view_pistol)

