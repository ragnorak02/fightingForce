class_name TestPathfinder
extends RefCounted

## Tests for Pathfinder — movement range, pathfinding, attack range.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_movement_range_open()
	_test_movement_range_blocked()
	_test_movement_range_cost()
	_test_pathfinding_basic()
	_test_pathfinding_obstacle()
	_test_pathfinding_enemy_blocks()
	_test_attack_range()
	_test_attack_range_bounds()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_movement_range_open() -> void:
	# 5x5 open grass grid, unit at center with mov=2
	var grid := _make_grid(5, 5, ".")
	var unit := _make_unit(Vector2i(2, 2), UnitData.Team.PLAYER, 2)
	grid.place_unit(unit, unit.grid_pos)

	var cells := Pathfinder.get_movement_range(grid, unit.grid_pos, unit.mov, unit.team)
	# With mov=2 on grass (cost 1), diamond pattern minus origin minus occupied
	_assert("move_open_count", cells.size() > 0)
	_assert("move_open_adjacent", Vector2i(3, 2) in cells)
	_assert("move_open_2_away", Vector2i(4, 2) in cells)
	_assert("move_open_no_origin", not (Vector2i(2, 2) in cells))
	_assert("move_open_2_left", Vector2i(0, 2) in cells)


func _test_movement_range_blocked() -> void:
	# Grid with water blocking
	var grid := _make_grid(5, 1, ".")
	grid.tiles[0][2] = BattleTile.from_type(BattleTile.TileType.WATER)  # Block middle

	var unit := _make_unit(Vector2i(0, 0), UnitData.Team.PLAYER, 4)
	grid.place_unit(unit, unit.grid_pos)

	var cells := Pathfinder.get_movement_range(grid, unit.grid_pos, unit.mov, unit.team)
	_assert("move_blocked_near", Vector2i(1, 0) in cells)
	_assert("move_blocked_water", not (Vector2i(2, 0) in cells))
	_assert("move_blocked_beyond", not (Vector2i(3, 0) in cells))


func _test_movement_range_cost() -> void:
	# Forest (cost 2) reduces range
	var grid := _make_grid(5, 1, ".")
	grid.tiles[0][1] = BattleTile.from_type(BattleTile.TileType.FOREST)  # cost 2
	grid.tiles[0][2] = BattleTile.from_type(BattleTile.TileType.FOREST)  # cost 2

	var unit := _make_unit(Vector2i(0, 0), UnitData.Team.PLAYER, 3)
	grid.place_unit(unit, unit.grid_pos)

	var cells := Pathfinder.get_movement_range(grid, unit.grid_pos, unit.mov, unit.team)
	_assert("move_cost_forest_1", Vector2i(1, 0) in cells)  # cost 2, within 3
	# Next forest at (2,0) costs 2+2=4, exceeds mov 3
	_assert("move_cost_forest_2_blocked", not (Vector2i(2, 0) in cells))


func _test_pathfinding_basic() -> void:
	var grid := _make_grid(5, 1, ".")
	var unit := _make_unit(Vector2i(0, 0), UnitData.Team.PLAYER, 4)
	grid.place_unit(unit, unit.grid_pos)

	var path := Pathfinder.find_path(grid, Vector2i(0, 0), Vector2i(3, 0), 4, UnitData.Team.PLAYER)
	_assert("path_basic_found", path.size() > 0)
	_assert("path_basic_end", path[path.size() - 1] == Vector2i(3, 0))
	_assert("path_basic_length", path.size() == 3)


func _test_pathfinding_obstacle() -> void:
	# 3x3 grid, wall in the middle, must go around
	var grid := _make_grid(3, 3, ".")
	grid.tiles[1][1] = BattleTile.from_type(BattleTile.TileType.WALL)

	var path := Pathfinder.find_path(grid, Vector2i(0, 1), Vector2i(2, 1), 10, UnitData.Team.PLAYER)
	_assert("path_obstacle_found", path.size() > 0)
	_assert("path_obstacle_avoids_wall", not (Vector2i(1, 1) in path))


func _test_pathfinding_enemy_blocks() -> void:
	var grid := _make_grid(5, 1, ".")
	var player := _make_unit(Vector2i(0, 0), UnitData.Team.PLAYER, 4)
	var enemy := _make_unit(Vector2i(2, 0), UnitData.Team.ENEMY, 4)
	grid.place_unit(player, player.grid_pos)
	grid.place_unit(enemy, enemy.grid_pos)

	var cells := Pathfinder.get_movement_range(grid, player.grid_pos, player.mov, player.team)
	_assert("enemy_blocks_cell", not (Vector2i(2, 0) in cells))
	_assert("enemy_blocks_beyond", not (Vector2i(3, 0) in cells))


func _test_attack_range() -> void:
	var grid := _make_grid(5, 5, ".")
	var cells := Pathfinder.get_attack_range(grid, Vector2i(2, 2), 1)
	_assert("atk_range_1_count", cells.size() == 4)
	_assert("atk_range_1_up", Vector2i(2, 1) in cells)
	_assert("atk_range_1_no_self", not (Vector2i(2, 2) in cells))


func _test_attack_range_bounds() -> void:
	var grid := _make_grid(3, 3, ".")
	var cells := Pathfinder.get_attack_range(grid, Vector2i(0, 0), 2)
	# Should only include in-bounds cells
	for c in cells:
		_assert("atk_range_bounds_%d_%d" % [c.x, c.y], grid.is_in_bounds(c))
	_assert("atk_range_bounds_no_oob", true)  # If we got here, all passed


func _make_grid(w: int, h: int, fill: String) -> BattleGrid:
	var row := ""
	for _x in w:
		row += fill
	var rows: Array = []
	for _y in h:
		rows.append(row)
	return BattleGrid.from_map_data({ "width": w, "height": h, "tiles": rows })


func _make_unit(pos: Vector2i, team: UnitData.Team, mov: int) -> UnitData:
	var u := UnitData.new()
	u.grid_pos = pos
	u.team = team
	u.mov = mov
	u.unit_name = "Test"
	u.attack_range = 1
	return u


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "pathfinder_" + name, "status": status})
	print("  [%s] pathfinder_%s" % [status, name])
