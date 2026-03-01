extends Node

## Loads and caches data catalogs from JSON/tres files.

var _catalogs: Dictionary = {}


func _ready() -> void:
	GameManager.log_info("DataDB ready")


func load_catalog(catalog_name: String, path: String) -> Array:
	if _catalogs.has(catalog_name):
		return _catalogs[catalog_name]

	if not FileAccess.file_exists(path):
		push_warning("DataDB: catalog not found: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("DataDB: parse error in %s: %s" % [path, json.get_error_message()])
		return []

	var data: Array = json.data if json.data is Array else []
	_catalogs[catalog_name] = data
	GameManager.log_info("DataDB: loaded %s (%d entries)" % [catalog_name, data.size()])
	return data


func get_catalog(catalog_name: String) -> Array:
	return _catalogs.get(catalog_name, [])


func clear_catalog(catalog_name: String) -> void:
	_catalogs.erase(catalog_name)
