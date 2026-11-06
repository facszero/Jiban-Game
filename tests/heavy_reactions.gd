extends SceneTree
var failures := 0
var defeat_count := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	for old in get_nodes_in_group("enemies"): old.free()
	var enemy=load("res://scripts/enemy.gd").new()
	enemy.heavy=true
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position=Vector3(0,.1,0)
	game.player.position=Vector3(0,.1,-1.6)
	enemy.attack_elapsed=.45
	enemy.take_damage(25)
	check(enemy.hit_elapsed==0 and enemy.stagger_elapsed<0,"Single bullet causes a light reaction")
	check(is_equal_approx(enemy.attack_elapsed,.45),"Light impact preserves committed swipe")
	enemy.model.animate(0,0)
	var chest: int=enemy.model.skeleton.find_bone("chest")
	var chest_rest: Quaternion=enemy.model.skeleton.get_bone_pose_rotation(chest)
	enemy.model.animate(0,0,-1,true,.11)
	check(enemy.model.skeleton.get_bone_pose_rotation(chest).angle_to(chest_rest)>.08,"Light impact visibly recoils chest")
	enemy.model.animate(0,0)
	check(enemy.model.skeleton.get_bone_pose_rotation(chest).angle_to(chest_rest)<.001,"Light recoil does not accumulate")
	enemy.take_damage(25)
	check(enemy.stagger_elapsed==0 and enemy.attack_elapsed<0,"Two rapid hits interrupt swipe with stagger")
	var player_health: float=game.player.health
	var start: Vector3=enemy.position
	for i in range(48):
		await physics_frame
		enemy.update_heavy(1.0/60)
	check(enemy.position.z>start.z+.1 and enemy.position.z<start.z+.4,"Strong hit produces bounded backward recoil")
	check(game.player.health==player_health,"Interrupted swipe never delivers stale impact")
	check(enemy.stagger_elapsed<0,"Stagger finishes and returns to combat")
	enemy.take_damage(50)
	check(enemy.stagger_elapsed<0,"Stagger cooldown prevents repeated stun locking")
	# A separate strong impact after cooldown also staggers; walls constrain recoil.
	enemy.health=175
	enemy.stagger_cooldown=0
	enemy.position=Vector3(0,.1,0)
	enemy.velocity=Vector3.ZERO
	var wall=load("res://scripts/geometry.gd").box(game,Vector3(0,1,.65),Vector3(3,2,.15),StandardMaterial3D.new(),true)
	await physics_frame
	enemy.take_damage(45)
	check(enemy.stagger_elapsed==0,"One strong hit triggers stagger")
	for i in range(25):
		await physics_frame
		enemy.update_heavy(1.0/60)
	check(enemy.position.z<.10,"Wall stops physical recoil")
	wall.free()
	# Death persists visually but immediately stops blocking and threatening the player.
	enemy.defeated.connect(func(): defeat_count+=1)
	enemy.take_damage(999)
	enemy.take_damage(999)
	check(defeat_count==1,"Defeat signal is emitted once")
	check(enemy.health==0 and enemy.death_elapsed==0,"Lethal hit starts death animation")
	check(not enemy.is_in_group("enemies") and enemy.is_in_group("enemy_corpses"),"Corpse no longer blocks encounter completion")
	check(enemy.collision_layer==0 and enemy.attack_elapsed<0,"Corpse cannot block player or attack")
	enemy.model.animate(0,0,-1,true,-1,-1,1.8)
	check(enemy.model.joint_position("head").y<1.0,"Death ends with head near floor")
	check(absf(enemy.model.joint_position("head").z-enemy.model.joint_position("foot.R").z)>1.0,"Death leaves body collapsed forward")
	enemy.update_death(4.1)
	await process_frame
	check(not is_instance_valid(enemy),"Corpse is removed after its display time")
	game.open_model_review()
	game.model_review.select_model(1)
	check(game.model_review.reaction_selector.visible,"Creature viewer exposes reactions")
	game.model_review.reaction_selector.item_selected.emit(3)
	check(game.model_review.preview_death==0,"Viewer starts death preview")
	game.model_review.select_model(0)
	check(game.model_review.preview_death<0 and not game.model_review.reaction_selector.visible,"Switching character clears death preview")
	game.model_review.close()
	game.free()
	paused=false
	print("HEAVY REACTIONS RESULT: %d failures" % failures)
	quit(1 if failures else 0)
