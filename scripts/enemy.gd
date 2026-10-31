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
	var model := Node3D.new()
	add_child(model)
	model.scale = Vector3.ONE * scale_factor
	var flesh := Geo.material(Color(0.24, 0.09, 0.12), 0.2)
	var armor := Geo.material(Color(0.09, 0.12, 0.15), 0.7)
	Geo.cylinder(model, Vector3(0, 1.1, 0), 0.4, 0.65, flesh)
	Geo.box(model, Vector3(0, 1.65, 0), Vector3(0.44, 0.37, 0.4), armor)
	var glow := Geo.material(Color(1, 0.05, 0.015), 0.1, 3.0)
	for side in [-1, 1]:
		Geo.box(model, Vector3(side * 0.12, 1.69, -0.22), Vector3(0.08, 0.07, 0.04), glow)
		Geo.box(model, Vector3(side * 0.23, 0.4, 0), Vector3(0.23, 0.8, 0.26), armor)
		Geo.box(model, Vector3(side * 0.52, 1.05, -0.1), Vector3(0.22, 0.8, 0.27), flesh)
	eye = Geo.light(self, Vector3(0, 1.5, -0.4), Color(1, 0.03, 0.01), 0.7, 2.0)
	player = get_tree().get_first_node_in_group("player")

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
	if state == "ATACANDO" and cooldown <= 0.0:
		player.take_damage(28.0 if heavy else 12.0)
		cooldown = 1.4 if heavy else 1.0

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	eye.light_energy = 3.0
	if health <= 0.0:
		state = "MUERTO"
		remove_from_group("enemies")
		defeated.emit()
		queue_free()
