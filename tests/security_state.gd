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
	var terminal=game.level.terminals[0]
	check(terminal.status_sign.text.contains("PENDIENTE"),"Console starts pending")
	terminal.interact()
	await process_frame
	await process_frame
	check(terminal.status_sign.text.contains("AUTORIZADO"),"Activation updates visible status")
	terminal.used=false
	await process_frame
	await process_frame
	check(terminal.status_sign.text.contains("PENDIENTE"),"Reset restores pending status")
	check(terminal.screen.mesh is QuadMesh,"Screen uses full image UVs")
	print("SECURITY RESULT: ",failures," failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
