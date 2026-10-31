extends RefCounted

static func setup() -> void:
	if InputMap.has_action("forward"):
		return
	var keys := {"left": KEY_A, "right": KEY_D, "forward": KEY_W, "back": KEY_S,
		"jump": KEY_SPACE, "sprint": KEY_SHIFT, "interact": KEY_E, "view": KEY_V,
		"reload": KEY_R, "pause_game": KEY_ESCAPE, "scan": KEY_F}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for pair in [["fire", MOUSE_BUTTON_LEFT], ["aim", MOUSE_BUTTON_RIGHT]]:
		InputMap.add_action(pair[0])
		var event := InputEventMouseButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0], event)
	var buttons := {"jump": JOY_BUTTON_A, "interact": JOY_BUTTON_X, "reload": JOY_BUTTON_B,
		"view": JOY_BUTTON_Y, "pause_game": JOY_BUTTON_START, "sprint": JOY_BUTTON_LEFT_STICK,
		"scan": JOY_BUTTON_RIGHT_STICK}
	for action in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = buttons[action]
		InputMap.action_add_event(action, event)
	for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0],
		["forward", JOY_AXIS_LEFT_Y, -1.0], ["back", JOY_AXIS_LEFT_Y, 1.0],
		["fire", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["aim", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = pair[1]
		event.axis_value = pair[2]
		InputMap.action_add_event(pair[0], event)
