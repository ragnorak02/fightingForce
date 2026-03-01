extends Node

## Slot-based save/load with versioned schema.

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1
const MAX_SLOTS := 3


func _ready() -> void:
	_ensure_save_dir()
	GameManager.log_info("SaveManager ready | dir=%s" % SAVE_DIR)


func save_game(slot: int, data: Dictionary) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: invalid slot %d" % slot)
		return false

	data["_saveVersion"] = SAVE_VERSION
	data["_timestamp"] = Time.get_datetime_string_from_system(true)

	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	GameManager.log_info("Saved to slot %d" % slot)
	return true


func load_game(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		GameManager.log_info("No save in slot %d" % slot)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SaveManager: parse error in slot %d" % slot)
		return {}

	var data: Dictionary = json.data
	var version: int = data.get("_saveVersion", 0)
	if version < SAVE_VERSION:
		data = _migrate(data, version)

	GameManager.log_info("Loaded slot %d (v%d)" % [slot, version])
	return data


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		GameManager.log_info("Deleted save slot %d" % slot)


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	GameManager.log_info("Migrating save from v%d to v%d" % [from_version, SAVE_VERSION])
	# Future migrations go here
	data["_saveVersion"] = SAVE_VERSION
	return data
