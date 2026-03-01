class_name TestAI
extends RefCounted

## Tests for AIBrain — approach target, attack when adjacent, no targets.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_attack_when_adjacent()
	_test_approach_target()
	_test_no_targets()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_attack_when_adjacent() -> void:
	# Enemy adjacent to player should move_attack
	var grid := _make_grid(5, 1, ".")
	var enemy := _make_unit(Vector2i(1, 0), UnitData.Team.ENEMY, 4, 1)
	var player := _make_unit(Vector2i(2, 0), UnitData.Team.PLAYER, 4, 1)
	grid.place_unit(enemy, enemy.grid_pos)
	grid.place_unit(player, player.grid_pos)

	var decision := AIBrain.decide(enemy, grid, [player])
	_assert("adjacent_type", decision["type"] == "move_attack")
	_assert("adjacent_target", decision["target"] == player)


func _test_approach_target() -> void:
	# Enemy far from player should move closer
	var grid := _make_grid(10, 1, ".")
	var enemy := _make_unit(Vector2i(0, 0), UnitData.Team.ENEMY, 3, 1)
	var player := _make_unit(Vector2i(9, 0), UnitData.Team.PLAYER, 4, 1)
	grid.place_unit(enemy, enemy.grid_pos)
	grid.place_unit(player, player.grid_pos)

	var decision := AIBrain.decide(enemy, grid, [player])
	_assert("approach_type", decision["type"] == "move")
	# Should move toward the player (higher x)
	_assert("approach_closer", decision["move_to"].x > enemy.grid_pos.x)


func _test_no_targets() -> void:
	var grid := _make_grid(5, 1, ".")
	var enemy := _make_unit(Vector2i(0, 0), UnitData.Team.ENEMY, 4, 1)
	grid.place_unit(enemy, enemy.grid_pos)

	var decision := AIBrain.decide(enemy, grid, [])
	_assert("no_targets_wait", decision["type"] == "wait")


func _make_grid(w: int, h: int, fill: String) -> BattleGrid:
	var row := ""
	for _x in w:
		row += fill
	var rows: Array = []
	for _y in h:
		rows.append(row)
	return BattleGrid.from_map_data({ "width": w, "height": h, "tiles": rows })


func _make_unit(pos: Vector2i, team: UnitData.Team, mov: int, atk_range: int) -> UnitData:
	var u := UnitData.new()
	u.grid_pos = pos
	u.team = team
	u.mov = mov
	u.attack_range = atk_range
	u.unit_name = "Test"
	u.atk = 8
	u.defense = 3
	u.spd = 5
	u.is_alive = true
	return u


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "ai_" + name, "status": status})
	print("  [%s] ai_%s" % [status, name])
