extends Node

## Handles scene transitions with optional fade.

var _transitioning: bool = false


func _ready() -> void:
	GameManager.log_info("SceneManager ready")


func change_scene(scene_path: String) -> void:
	if _transitioning:
		push_warning("Scene transition already in progress")
		return
	_transitioning = true
	GameManager.log_info("Changing scene to: %s" % scene_path)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene: %s (error %d)" % [scene_path, err])
	_transitioning = false
