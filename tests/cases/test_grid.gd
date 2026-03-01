class_name TestGrid
extends RefCounted

## Tests for BattleGrid and BattleTile — grid construction, tiles, bounds, occupancy, coordinates.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_tile_from_type()
	_test_tile_from_key()
	_test_tile_properties()
	_test_grid_construction()
	_test_grid_bounds()
	_test_grid_neighbors()
	_test_grid_occupancy()
	_test_grid_coordinate_conversion()
	_test_cell_passable()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_tile_from_type() -> void:
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)
	_assert("tile_grass_type", tile.tile_type == BattleTile.TileType.GRASS)
	_assert("tile_grass_cost", tile.move_cost == 1)
	_assert("tile_grass_not_impassable", tile.impassable == false)

	var wall := BattleTile.from_type(BattleTile.TileType.WALL)
	_assert("tile_wall_impassable", wall.impassable == true)


func _test_tile_from_key() -> void:
	var grass := BattleTile.from_key(".")
	_assert("tile_key_grass", grass.tile_type == BattleTile.TileType.GRASS)
	var forest := BattleTile.from_key("F")
	_assert("tile_key_forest", forest.tile_type == BattleTile.TileType.FOREST)
	var water := BattleTile.from_key("W")
	_assert("tile_key_water", water.tile_type == BattleTile.TileType.WATER)


func _test_tile_properties() -> void:
	var forest := BattleTile.from_type(BattleTile.TileType.FOREST)
	_assert("forest_move_cost_2", forest.move_cost == 2)
	_assert("forest_def_bonus", forest.def_bonus == 2)
	_assert("forest_eva_bonus", forest.eva_bonus == 10)

	var hills := BattleTile.from_type(BattleTile.TileType.HILLS)
	_assert("hills_move_cost_3", hills.move_cost == 3)
	_assert("hills_def_bonus", hills.def_bonus == 3)


func _test_grid_construction() -> void:
	var map_data := {
		"width": 3, "height": 2,
		"tiles": [".F.", "W.X"]
	}
	var grid := BattleGrid.from_map_data(map_data)
	_assert("grid_width", grid.width == 3)
	_assert("grid_height", grid.height == 2)
	_assert("grid_tile_00_grass", grid.get_tile(Vector2i(0, 0)).tile_type == BattleTile.TileType.GRASS)
	_assert("grid_tile_10_forest", grid.get_tile(Vector2i(1, 0)).tile_type == BattleTile.TileType.FOREST)
	_assert("grid_tile_02_water", grid.get_tile(Vector2i(0, 1)).tile_type == BattleTile.TileType.WATER)
	_assert("grid_tile_22_wall", grid.get_tile(Vector2i(2, 1)).tile_type == BattleTile.TileType.WALL)


func _test_grid_bounds() -> void:
	var map_data := { "width": 4, "height": 3, "tiles": ["....", "....", "...."] }
	var grid := BattleGrid.from_map_data(map_data)
	_assert("bounds_in", grid.is_in_bounds(Vector2i(0, 0)))
	_assert("bounds_in_max", grid.is_in_bounds(Vector2i(3, 2)))
	_assert("bounds_out_neg", not grid.is_in_bounds(Vector2i(-1, 0)))
	_assert("bounds_out_x", not grid.is_in_bounds(Vector2i(4, 0)))
	_assert("bounds_out_y", not grid.is_in_bounds(Vector2i(0, 3)))
	_assert("bounds_null_tile", grid.get_tile(Vector2i(-1, -1)) == null)


func _test_grid_neighbors() -> void:
	var map_data := { "width": 3, "height": 3, "tiles": ["...", "...", "..."] }
	var grid := BattleGrid.from_map_data(map_data)
	var center_neighbors := grid.get_neighbors(Vector2i(1, 1))
	_assert("neighbors_center_4", center_neighbors.size() == 4)
	var corner_neighbors := grid.get_neighbors(Vector2i(0, 0))
	_assert("neighbors_corner_2", corner_neighbors.size() == 2)


func _test_grid_occupancy() -> void:
	var map_data := { "width": 3, "height": 3, "tiles": ["...", "...", "..."] }
	var grid := BattleGrid.from_map_data(map_data)

	var unit := UnitData.new()
	unit.unit_name = "Test"
	var pos := Vector2i(1, 1)
	grid.place_unit(unit, pos)
	_assert("occupancy_placed", grid.get_unit_at(pos) == unit)
	_assert("occupancy_free_other", grid.is_cell_free(Vector2i(0, 0)))
	_assert("occupancy_not_free", not grid.is_cell_free(pos))

	grid.remove_unit_at(pos)
	_assert("occupancy_removed", grid.get_unit_at(pos) == null)
	_assert("occupancy_free_after_remove", grid.is_cell_free(pos))


func _test_grid_coordinate_conversion() -> void:
	var map_data := { "width": 3, "height": 3, "tiles": ["...", "...", "..."] }
	var grid := BattleGrid.from_map_data(map_data)
	var world := grid.grid_to_world(Vector2i(2, 1))
	_assert("coord_grid_to_world_x", world.x == 2 * BattleGrid.TILE_SIZE)
	_assert("coord_grid_to_world_y", world.y == 1 * BattleGrid.TILE_SIZE)
	var back := grid.world_to_grid(world)
	_assert("coord_roundtrip", back == Vector2i(2, 1))


func _test_cell_passable() -> void:
	var map_data := { "width": 3, "height": 1, "tiles": [".WX"] }
	var grid := BattleGrid.from_map_data(map_data)
	_assert("passable_grass", grid.is_cell_passable(Vector2i(0, 0)))
	_assert("impassable_water", not grid.is_cell_passable(Vector2i(1, 0)))
	_assert("impassable_wall", not grid.is_cell_passable(Vector2i(2, 0)))
	_assert("impassable_oob", not grid.is_cell_passable(Vector2i(-1, 0)))


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "grid_" + name, "status": status})
	print("  [%s] grid_%s" % [status, name])
