extends CharacterBody3D

signal defeated
const Geo = preload("res://scripts/geometry.gd")
@export var heavy := false
var health := 75.0
var speed := 2.2
var cooldown := 0.0
var player: CharacterBody3D
var state := "INACTIVO"
var eye: OmniLight3D
var model: Node3D
var limbs: Array[Node3D] = []
var gait := 0.0
var hit_flash := 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 7
	health = 175.0 if heavy else 75.0
	speed = 1.25 if heavy else 2.2
	var scale_factor := 1.35 if heavy else 1.0
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * scale_factor
	capsule.height = 1.7 * scale_factor
	col.shape = capsule
	col.position.y = capsule.height / 2.0
	add_child(col)
	model = Node3D.new()
	add_child(model)
	model.scale = Vector3.ONE * scale_factor
	build_creature()
	eye = Geo.light(self, Vector3(0, 1.5, -0.4), Color(1, 0.12, 0.03), 0.0, 2.0)
	player = get_tree().get_first_node_in_group("player")

func build_creature() -> void:
	# Reference-based low-poly adaptations; no ripped textures or meshes.
	var dark := Geo.material(Color(0.045, 0.055, 0.065), 0.25)
	var pale := Geo.material(Color(0.7, 0.8, 0.7), 0.25)
	var skin := Geo.material(Color(0.19, 0.31, 0.24), 0.1)
	var wine := Geo.material(Color(0.28, 0.08, 0.09), 0.1)
	var body_mat := wine if heavy else dark
	Geo.ellipsoid(model, Vector3(0, 1.14, 0), Vector3(0.75 if heavy else 0.57, 0.71, 0.39), body_mat)
	Geo.ellipsoid(model, Vector3(0, 0.83, 0), Vector3(0.48, 0.3, 0.33), dark)
	Geo.ellipsoid(model, Vector3(0, 1.65, 0), Vector3(0.45, 0.5, 0.4), skin if heavy else dark)
	if heavy:
		# Chamelenoid: tall central crest, pale orbital rings, burgundy shoulders.
		Geo.ellipsoid(model, Vector3(0, 1.92, 0.01), Vector3(0.14, 0.5, 0.3), skin)
		for side in [-1, 1]:
			Geo.ellipsoid(model, Vector3(side * 0.155, 1.7, -0.17), Vector3(0.19, 0.26, 0.095), pale)
			Geo.ellipsoid(model, Vector3(side * 0.16, 1.72, -0.222), Vector3(0.075, 0.11, 0.045), dark)
			for i in range(3):
				Geo.ellipsoid(model, Vector3(side * 0.14, 1.3 - i * 0.13, -0.21), Vector3(0.22, 0.11, 0.09), skin)
		Geo.link(model, Vector3(-0.13, 1.51, -0.2), Vector3(0, 1.55, -0.24), 0.025, dark)
		Geo.link(model, Vector3(0, 1.55, -0.24), Vector3(0.13, 1.51, -0.2), 0.025, dark)
	else:
		# Masques: black hood, circular forehead mark and pale U-shaped mask.
		Geo.ellipsoid(model, Vector3(0, 1.78, -0.19), Vector3(0.15, 0.15, 0.045), pale)
		Geo.ellipsoid(model, Vector3(0, 1.52, -0.17), Vector3(0.29, 0.14, 0.07), pale)
		for side in [-1, 1]:
			Geo.ellipsoid(model, Vector3(side * 0.12, 1.59, -0.18), Vector3(0.1, 0.2, 0.065), pale)
		Geo.box(model, Vector3(0, 1.13, -0.21), Vector3(0.04, 0.5, 0.03), pale)
		Geo.box(model, Vector3(0, 0.88, -0.18), Vector3(0.49, 0.06, 0.05), pale)
	for side in [-1, 1]:
		var leg := Node3D.new()
		model.add_child(leg)
		leg.position = Vector3(side * 0.17, 0.83, 0)
		Geo.ellipsoid(leg, Vector3(0, -0.19, 0), Vector3(0.24, 0.45, 0.26), body_mat)
		Geo.ellipsoid(leg, Vector3(0, -0.56, 0), Vector3(0.22, 0.4, 0.24), skin if heavy else dark)
		Geo.ellipsoid(leg, Vector3(0, -0.75, -0.07), Vector3(0.26, 0.16, 0.4), dark)
		limbs.append(leg)
		var arm := Node3D.new()
		model.add_child(arm)
		arm.position = Vector3(side * 0.4, 1.4, 0)
		Geo.ellipsoid(arm, Vector3(0, -0.1, 0), Vector3(0.34 if heavy else 0.23, 0.35, 0.3), body_mat)
		Geo.ellipsoid(arm, Vector3(side * 0.04, -0.39, -0.04), Vector3(0.21, 0.36, 0.22), skin if heavy else dark)
		Geo.ellipsoid(arm, Vector3(side * 0.04, -0.6, -0.08), Vector3(0.19, 0.19, 0.19), dark)
		if heavy:
			for i in range(3):
				Geo.link(arm, Vector3(side * (0.12 + i * 0.035), 0, 0.08), Vector3(side * (0.22 + i * 0.045), -0.3 - i * 0.04, 0.06), 0.045, skin)
		else:
			if side == 1:
				Geo.box(arm, Vector3(0.04, -0.61, -0.21), Vector3(0.09, 0.12, 0.28), pale)
		limbs.append(arm)

func animate_model(delta: float) -> void:
	gait += Vector2(velocity.x, velocity.z).length() * delta * 3.0
	var stride := sin(gait) * (0.35 if state == "PERSIGUIENDO" else 0.0)
	limbs[0].rotation.x = stride
	limbs[2].rotation.x = -stride
	var attack := sin((1.4 if heavy else 1.0) - cooldown) * -1.3 if state == "ATACANDO" else 0.0
	limbs[1].rotation.x = -stride * 0.6 + attack
	limbs[3].rotation.x = stride * 0.6 + attack
	hit_flash = maxf(0.0, hit_flash - delta)
	eye.light_energy = 2.5 if hit_flash > 0.0 else 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0.0 or health <= 0.0:
		return
	cooldown = maxf(0.0, cooldown - delta)
	var offset := player.global_position - global_position
	var distance := offset.length()
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.3, player.global_position + Vector3.UP * 1.3, 3, [get_rid()])
	var sight := get_world_3d().direct_space_state.intersect_ray(query)
	var visible_target: bool = not sight.is_empty() and sight.collider == player
	if distance < 19.0 and visible_target:
		state = "ATACANDO" if distance < (2.0 if heavy else 1.5) else "PERSIGUIENDO"
	else:
		state = "INACTIVO"
	var direction := Vector3(offset.x, 0, offset.z).normalized()
	if state != "INACTIVO" and direction.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 6.0))
	velocity.x = direction.x * speed if state == "PERSIGUIENDO" else 0.0
	velocity.z = direction.z * speed if state == "PERSIGUIENDO" else 0.0
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	animate_model(delta)
	if state == "ATACANDO" and cooldown <= 0.0:
		player.take_damage(28.0 if heavy else 12.0)
		cooldown = 1.4 if heavy else 1.0

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	hit_flash = 0.12
	if health <= 0.0:
		state = "MUERTO"
		remove_from_group("enemies")
		defeated.emit()
		queue_free()
