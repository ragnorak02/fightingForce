extends Node

## Global game state manager. First autoload — other systems depend on this.

enum GameState { BOOT, TITLE, TOWN, BATTLE, MENU, CUTSCENE }

var current_state: GameState = GameState.BOOT
var is_headless: bool = false

# Debug flags — all default false
var DEBUG_BATTLE: bool = false
var DEBUG_AI: bool = false
var DEBUG_INPUT: bool = false
var DEBUG_SAVE: bool = false
var DEBUG_UI: bool = false
var DEBUG_PATHFIND: bool = false


func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"
	_load_config()
	log_info("GameManager ready | headless=%s" % str(is_headless))


func set_state(new_state: GameState) -> void:
	var old := current_state
	current_state = new_state
	log_info("State: %s -> %s" % [GameState.keys()[old], GameState.keys()[new_state]])


func log_info(msg: String) -> void:
	print("[GameManager] %s" % msg)


func log_debug(flag: bool, msg: String) -> void:
	if flag:
		print("[DEBUG] %s" % msg)


func _load_config() -> void:
	var path := "res://game.config.json"
	if not FileAccess.file_exists(path):
		push_warning("game.config.json not found")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("game.config.json parse error: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	log_info("Config loaded: %s v%s" % [data.get("title", "?"), data.get("engineVersion", "?")])
