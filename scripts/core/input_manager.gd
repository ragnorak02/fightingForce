extends Node

## Central input abstraction. Programmatic InputMap for Xbox controller + keyboard.
## Auto-detects input method (controller vs keyboard).

enum InputMethod { KEYBOARD, CONTROLLER }

var current_method: InputMethod = InputMethod.KEYBOARD

signal input_method_changed(method: InputMethod)


func _ready() -> void:
	_setup_input_map()
	GameManager.log_info("InputManager ready | mappings configured")


func _input(event: InputEvent) -> void:
	var new_method := current_method
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_method = InputMethod.CONTROLLER
	elif event is InputEventKey or event is InputEventMouseButton:
		new_method = InputMethod.KEYBOARD

	if new_method != current_method:
		current_method = new_method
		input_method_changed.emit(current_method)
		GameManager.log_debug(GameManager.DEBUG_INPUT,
			"Input method: %s" % InputMethod.keys()[current_method])


func _setup_input_map() -> void:
	# Movement
	_add_action("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], Vector2.UP)
	_add_action("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], Vector2.DOWN)
	_add_action("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], Vector2.LEFT)
	_add_action("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], Vector2.RIGHT)

	# Face buttons
	_add_action("confirm", [KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A])
	_add_action("back", [KEY_ESCAPE, KEY_BACKSPACE], [JOY_BUTTON_B])
	_add_action("action", [KEY_J], [JOY_BUTTON_X])
	_add_action("info", [KEY_K], [JOY_BUTTON_Y])

	# Shoulders
	_add_action("tab_left", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER])
	_add_action("tab_right", [KEY_E], [JOY_BUTTON_RIGHT_SHOULDER])

	# System
	_add_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START])

	# Wire Godot built-in UI actions for Control focus navigation
	_add_to_builtin("ui_accept", [KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A])
	_add_to_builtin("ui_cancel", [KEY_ESCAPE], [JOY_BUTTON_B])
	_add_to_builtin("ui_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP])
	_add_to_builtin("ui_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN])
	_add_to_builtin("ui_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT])
	_add_to_builtin("ui_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT])


func _add_action(action_name: String, keys: Array, buttons: Array, stick_dir: Vector2 = Vector2.ZERO) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for key in keys:
		var ev := InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(action_name, ev)

	for btn in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = btn
		InputMap.action_add_event(action_name, ev)

	# Left stick axis for directional actions
	if stick_dir != Vector2.ZERO:
		var ev := InputEventJoypadMotion.new()
		if stick_dir.x != 0:
			ev.axis = JOY_AXIS_LEFT_X
			ev.axis_value = stick_dir.x
		else:
			ev.axis = JOY_AXIS_LEFT_Y
			ev.axis_value = stick_dir.y
		InputMap.action_add_event(action_name, ev)


func _add_to_builtin(action_name: String, keys: Array, buttons: Array) -> void:
	for key in keys:
		var ev := InputEventKey.new()
		ev.keycode = key
		if not _action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)

	for btn in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = btn
		if not _action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)


func _action_has_event(action_name: String, check_event: InputEvent) -> bool:
	if not InputMap.has_action(action_name):
		return false
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and check_event is InputEventKey:
			if ev.keycode == check_event.keycode:
				return true
		if ev is InputEventJoypadButton and check_event is InputEventJoypadButton:
			if ev.button_index == check_event.button_index:
				return true
	return false
