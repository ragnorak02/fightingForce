extends Control

## Boot scene — title screen entry point.
## Shows "FIGHTING FORCE" title with blinking "PRESS START" prompt.
## In headless mode, confirms boot success and exits.

@onready var press_start: Label = %PressStart

var _blink_timer: float = 0.0
var _transitioning: bool = false
const BLINK_INTERVAL: float = 0.6


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.TITLE)
	GameManager.log_info("Boot scene ready")

	if GameManager.is_headless:
		GameManager.log_info("Headless boot successful — all autoloads initialized")
		return

	# Ensure the prompt starts visible
	press_start.visible = true


func _process(delta: float) -> void:
	if GameManager.is_headless:
		return

	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer -= BLINK_INTERVAL
		press_start.visible = not press_start.visible


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_headless:
		return

	if event.is_action_pressed("confirm") and not _transitioning:
		_transitioning = true
		GameManager.log_info("Start pressed — transitioning to main menu")
		get_viewport().set_input_as_handled()
		SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
