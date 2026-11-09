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
var attack_elapsed := -1.0
var attack_hit := false
var attack_right := true
var next_attack_right := true
var hit_elapsed := -1.0
var stagger_elapsed := -1.0
var stagger_cooldown := 0.0
var damage_window := 0.0
var stagger_damage := 0.0
var recoil_direction := Vector3.ZERO
var death_elapsed := -1.0
const STAGGER_DURATION := .70
const CORPSE_DURATION := 4.0
const LUNGE_START := .58
const LUNGE_END := .90
const LUNGE_SPEED := 2.8
const HEAVY_WINDUP := 0.65
const HEAVY_IMPACT := 0.78
const HEAVY_DURATION := 1.45

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 7
	health = 175.0 if heavy else 75.0
	speed = preload("res://scripts/chamelenoid_model.gd").CHASE_SPEED if heavy else 2.2
	var scale_factor := 1.35 if heavy else 1.0
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * scale_factor
	capsule.height = 1.7 * scale_factor
	col.shape = capsule
	col.position.y = capsule.height / 2.0
	add_child(col)
	model = preload("res://scripts/chamelenoid_model.gd").new() if heavy else preload("res://scripts/bioron_meshy_model.gd").new()
	add_child(model)
	model.scale = Vector3.ONE * (preload("res://scripts/chamelenoid_model.gd").GAME_SCALE if heavy else scale_factor)
	eye = Geo.light(self, Vector3(0, 1.5, -0.4), Color(1, 0.12, 0.03), 0.0, 2.0)
	player = get_tree().get_first_node_in_group("player")

func animate_model(delta: float) -> void:
	if heavy:
		gait += Vector2(velocity.x, velocity.z).length() * delta * preload("res://scripts/chamelenoid_model.gd").GAIT_PER_METER
		model.animate(gait, 1.0 if state == "PERSIGUIENDO" else 0.0, attack_elapsed, attack_right, hit_elapsed, stagger_elapsed, death_elapsed)
		hit_flash = maxf(0.0, hit_flash - delta)
		eye.light_energy = 2.5 if hit_flash > 0 else (0.7 if state == "PREPARANDO" else 0.0)
		return
	model.update_locomotion(delta,global_basis.inverse()*velocity,false,state=="ATACANDO",is_on_floor())
	model.upper_body.rotation.x += sin(hit_flash*PI/.12)*.12
	if model.has_method("sync_skin"): model.sync_skin()
	hit_flash = maxf(0.0, hit_flash - delta)
	eye.light_energy = 2.5 if hit_flash > 0.0 else 0.0

func _physics_process(delta: float) -> void:
	if heavy and death_elapsed >= 0:
		update_death(delta)
		return
	if not is_instance_valid(player) or player.health <= 0.0 or health <= 0.0:
		return
	if heavy:
		update_heavy(delta)
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
	if health <= 0.0 or amount <= 0.0:
		return
	health = maxf(0.0,health-amount)
	hit_flash = .12
	if health <= 0.0:
		state = "MUERTO"
		remove_from_group("enemies")
		attack_elapsed = -1
		attack_hit = true
		defeated.emit()
		if heavy:
			death_elapsed=0
			stagger_elapsed=-1
			hit_elapsed=-1
			velocity=Vector3.ZERO
			collision_layer=0
			collision_mask=1
			add_to_group("enemy_corpses")
			animate_model(0)
		else:
			queue_free()
		return
	if heavy:
		hit_elapsed=0
		stagger_damage=(stagger_damage if damage_window>0 else 0.0)+amount
		damage_window=.8
		if stagger_cooldown<=0 and (amount>=45 or stagger_damage>=50):
			stagger_elapsed=0
			stagger_cooldown=1.8
			stagger_damage=0
			attack_elapsed=-1
			attack_hit=true
			cooldown=maxf(cooldown,STAGGER_DURATION+.2)
			state="ATURDIDO"
			recoil_direction=global_basis.z
			if is_instance_valid(player):
				var away := global_position-player.global_position
				away.y=0
				if away.length()>.01: recoil_direction=away.normalized()

func update_death(delta: float) -> void:
	death_elapsed+=delta
	velocity.x=0
	velocity.z=0
	if not is_on_floor(): velocity.y-=20.0*delta
	move_and_slide()
	animate_model(delta)
	if death_elapsed>=CORPSE_DURATION: queue_free()

func update_stagger(delta: float) -> void:
	stagger_elapsed+=delta
	var push := 1.7*(1.0-smoothstep(0,.32,stagger_elapsed))
	velocity.x=recoil_direction.x*push
	velocity.z=recoil_direction.z*push
	if not is_on_floor(): velocity.y-=20.0*delta
	move_and_slide()
	state="ATURDIDO"
	animate_model(delta)
	if stagger_elapsed>=STAGGER_DURATION:
		stagger_elapsed=-1
		state="RECUPERANDO"

func sees_player() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.3, player.global_position + Vector3.UP * 1.3, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player

func update_heavy(delta: float) -> void:
	if death_elapsed >= 0:
		update_death(delta)
		return
	stagger_cooldown=maxf(0,stagger_cooldown-delta)
	damage_window=maxf(0,damage_window-delta)
	if damage_window<=0: stagger_damage=0
	if hit_elapsed>=0:
		hit_elapsed+=delta
		if hit_elapsed>=.22: hit_elapsed=-1
	if stagger_elapsed>=0:
		cooldown=maxf(0,cooldown-delta)
		update_stagger(delta)
		return
	var pending_impact := false
	cooldown = maxf(0.0, cooldown-delta)
	var offset := player.global_position-global_position
	var distance := offset.length()
	var direction := Vector3(offset.x,0,offset.z).normalized()
	velocity.x=0
	velocity.z=0
	if attack_elapsed >= 0:
		# Commit to the direction of the windup, so a sidestep can evade the swipe.
		var previous := attack_elapsed
		attack_elapsed += delta
		pending_impact=attack_elapsed>=HEAVY_IMPACT and not attack_hit
		var overlap := maxf(0.0, minf(attack_elapsed,LUNGE_END)-maxf(previous,LUNGE_START))
		var lunge := -global_basis.z * LUNGE_SPEED * overlap / maxf(delta,.0001)
		velocity.x=lunge.x
		velocity.z=lunge.z
		state = "PREPARANDO" if attack_elapsed < HEAVY_WINDUP else ("ATACANDO" if attack_elapsed < .9 else "RECUPERANDO")
		if attack_elapsed >= HEAVY_DURATION:
			attack_elapsed=-1
			cooldown=.35
			state="RECUPERANDO"
	elif distance < 19.0 and sees_player():
		rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),minf(1.0,delta*6.0))
		if distance < 2.7:
			state="RECUPERANDO"
			if cooldown <= 0:
				rotation.y=atan2(-direction.x,-direction.z)
				attack_right=next_attack_right
				next_attack_right=not next_attack_right
				attack_elapsed=0
				attack_hit=false
				state="PREPARANDO"
		else:
			state="PERSIGUIENDO"
			velocity.x=direction.x*speed
			velocity.z=direction.z*speed
	else:
		state="INACTIVO"
	if not is_on_floor():
		velocity.y-=20.0*delta
	move_and_slide()
	if pending_impact:
		attack_hit=true
		var target := player.global_position-global_position
		var planar := Vector3(target.x,0,target.z)
		if target.length() < 2.1 and (-global_basis.z).dot(planar.normalized()) > .35 and sees_player():
			player.take_damage(28.0)
	animate_model(delta)

