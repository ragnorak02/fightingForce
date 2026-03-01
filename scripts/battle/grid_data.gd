class_name BattleGrid
extends RefCounted

## 2D tile grid + occupancy map. Pure data — no Node dependencies.

const TILE_SIZE: int = 48

var width: int = 0
var height: int = 0
var tiles: Array = []  # Array[Array[BattleTile]] — row-major [y][x]
var occupancy: Dictionary = {}  # Dictionary<Vector2i, UnitData>


static func from_map_data(map_dict: Dictionary) -> BattleGrid:
	var gd := BattleGrid.new()
	gd.width = int(map_dict.get("width", 0))
	gd.height = int(map_dict.get("height", 0))

	var rows: Array = map_dict.get("tiles", [])
	gd.tiles = []
	for y in gd.height:
		var row_tiles: Array = []
		var row_str: String = rows[y] if y < rows.size() else ""
		for x in gd.width:
			var key := row_str[x] if x < row_str.length() else "."
			row_tiles.append(BattleTile.from_key(key))
		gd.tiles.append(row_tiles)

	return gd


func get_tile(pos: Vector2i) -> BattleTile:
	if not is_in_bounds(pos):
		return null
	return tiles[pos.y][pos.x]


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / TILE_SIZE, int(world_pos.y) / TILE_SIZE)


func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d: Vector2i in dirs:
		var neighbor: Vector2i = pos + d
		if is_in_bounds(neighbor):
			result.append(neighbor)
	return result


func get_unit_at(pos: Vector2i) -> Variant:
	return occupancy.get(pos, null)


func place_unit(unit: Variant, pos: Vector2i) -> void:
	# Remove from old position if occupied
	for p in occupancy:
		if occupancy[p] == unit:
			occupancy.erase(p)
			break
	occupancy[pos] = unit


func remove_unit_at(pos: Vector2i) -> void:
	occupancy.erase(pos)


func is_cell_free(pos: Vector2i) -> bool:
	return is_in_bounds(pos) and not occupancy.has(pos)


func is_cell_passable(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	var tile := get_tile(pos)
	return tile != null and not tile.impassable
