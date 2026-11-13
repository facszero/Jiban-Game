extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var fx=game.level.effects
	fx.set_process(false)
	check(fx.puffs.size()==64,"Fixed vapor pool caps allocation")
	game.level.open_door()
	check(fx.door_bursts==1,"Door opening triggers pressure release")
	for i in range(40): fx.advance(.016)
	check(fx.active_puffs>0 and fx.active_puffs<=32,"Door vapor emits within budget")
	for i in range(200): fx.advance(.016)
	check(fx.active_puffs==0,"Vapor fully dissipates")
	fx.fire_arc()
	fx.advance(.02)
	check(fx.arc_light.light_energy>0 and fx.arc_segments[0].visible,"Arc and local light synchronize")
	fx.advance(.4)
	check(fx.arc_light.light_energy==0 and not fx.arc_segments[0].visible,"Arc light and sparks stop")
	check(fx.hiss.data.size()>0 and fx.arc_audio.max_distance==16,"Generated positional audio configured")
	print("EFFECTS RESULT: ",failures," failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
