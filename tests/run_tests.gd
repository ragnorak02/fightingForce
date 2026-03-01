extends SceneTree

## Headless test runner for AMATRIS compliance.
## Runs deterministic unit tests, outputs test_results.json.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_all_tests()
	_write_results()
	quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	print("[TestRunner] Starting Phase 1 compliance tests...")

	# Checkpoint 1: Directory structure
	_test("dirs_assets", _dir_exists("res://assets"))
	_test("dirs_assets_credits", _dir_exists("res://assets/_credits"))
	_test("dirs_assets_tiles", _dir_exists("res://assets/tiles"))
	_test("dirs_assets_sprites_units", _dir_exists("res://assets/sprites/units"))
	_test("dirs_assets_sprites_enemies", _dir_exists("res://assets/sprites/enemies"))
	_test("dirs_assets_sprites_effects", _dir_exists("res://assets/sprites/effects"))
	_test("dirs_assets_ui", _dir_exists("res://assets/ui"))
	_test("dirs_assets_audio_music", _dir_exists("res://assets/audio/music"))
	_test("dirs_assets_audio_sfx", _dir_exists("res://assets/audio/sfx"))
	_test("dirs_scenes_boot", _dir_exists("res://scenes/boot"))
	_test("dirs_scenes_overworld", _dir_exists("res://scenes/overworld"))
	_test("dirs_scenes_battle", _dir_exists("res://scenes/battle"))
	_test("dirs_scenes_ui", _dir_exists("res://scenes/ui"))
	_test("dirs_scripts_core", _dir_exists("res://scripts/core"))
	_test("dirs_scripts_battle", _dir_exists("res://scripts/battle"))
	_test("dirs_scripts_overworld", _dir_exists("res://scripts/overworld"))
	_test("dirs_scripts_ui", _dir_exists("res://scripts/ui"))
	_test("dirs_scripts_data", _dir_exists("res://scripts/data"))
	_test("dirs_data_units", _dir_exists("res://data/units"))
	_test("dirs_data_items", _dir_exists("res://data/items"))
	_test("dirs_data_classes", _dir_exists("res://data/classes"))
	_test("dirs_data_maps", _dir_exists("res://data/maps"))
	_test("dirs_data_skills", _dir_exists("res://data/skills"))
	_test("dirs_tests_cases", _dir_exists("res://tests/cases"))

	# Checkpoint 2: game.config.json
	_test("game_config_exists", _file_exists("res://game.config.json"))
	_test("game_config_valid", _json_valid("res://game.config.json"))
	_test("game_config_has_id", _json_has_key("res://game.config.json", "id"))
	_test("game_config_has_engine", _json_has_key("res://game.config.json", "engine"))
	_test("game_config_has_controller", _json_has_key("res://game.config.json", "controllerRequired"))

	# Checkpoint 3: project_status.json
	_test("project_status_exists", _file_exists("res://project_status.json"))
	_test("project_status_valid", _json_valid("res://project_status.json"))
	_test("project_status_schema_v1", _json_key_equals("res://project_status.json", "schemaVersion", 1))

	# Checkpoint 4: Godot project
	_test("project_godot_exists", _file_exists("res://project.godot"))

	# Checkpoint 7: Autoloads
	_test("autoload_game_manager", _file_exists("res://scripts/core/game_manager.gd"))
	_test("autoload_scene_manager", _file_exists("res://scripts/core/scene_manager.gd"))
	_test("autoload_input_manager", _file_exists("res://scripts/core/input_manager.gd"))
	_test("autoload_data_db", _file_exists("res://scripts/core/data_db.gd"))
	_test("autoload_audio_manager", _file_exists("res://scripts/core/audio_manager.gd"))
	_test("autoload_save_manager", _file_exists("res://scripts/core/save_manager.gd"))

	# Checkpoint 8: Boot scene
	_test("boot_scene_exists", _file_exists("res://scenes/boot/boot.tscn"))
	_test("boot_script_exists", _file_exists("res://scenes/boot/boot.gd"))

	# Checkpoint 10: Test runner
	_test("test_runner_bat", _file_exists("res://tests/run-tests.bat"))
	_test("test_runner_gd", _file_exists("res://tests/run_tests.gd"))

	# Checkpoint 12: Credits
	_test("credits_file", _file_exists("res://assets/_credits/credits.md"))

	print("[TestRunner] Completed: %d passed, %d failed, %d total" % [_passed, _failed, _passed + _failed])


func _test(name: String, passed: bool) -> void:
	var status := "PASS" if passed else "FAIL"
	if passed:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": name, "status": status})
	print("  [%s] %s" % [status, name])


func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func _dir_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)


func _json_valid(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	return json.parse(text) == OK


func _json_has_key(path: String, key: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	if json.data is Dictionary:
		return json.data.has(key)
	return false


func _json_key_equals(path: String, key: String, expected_value: Variant) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	if json.data is Dictionary:
		return json.data.get(key) == expected_value
	return false


func _write_results() -> void:
	var timestamp := Time.get_datetime_string_from_system(true)
	var output := {
		"gameId": "fightingforce",
		"timestamp": timestamp,
		"testsTotal": _passed + _failed,
		"testsPassed": _passed,
		"testsFailed": _failed,
		"status": "pass" if _failed == 0 else "fail",
		"results": _results
	}

	var path := "res://tests/test_results.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[TestRunner] Cannot write test_results.json")
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print("[TestRunner] Results written to %s" % path)
