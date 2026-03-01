class_name TestTurnManager
extends RefCounted

## Tests for TurnManager — phase cycling, exhaustion, reset, victory/defeat.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_setup()
	_test_phase_cycling()
	_test_exhaustion_check()
	_test_reset_on_phase()
	_test_victory_detection()
	_test_defeat_detection()
	_test_no_end_while_alive()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_setup() -> void:
	var tm := TurnManager.new()
	var p := [_make_unit(UnitData.Team.PLAYER)]
	var e := [_make_unit(UnitData.Team.ENEMY)]
	tm.setup(p, e)
	_assert("setup_player_phase", tm.current_phase == TurnManager.Phase.PLAYER_PHASE)
	_assert("setup_no_result", tm.battle_result == TurnManager.BattleResult.NONE)


func _test_phase_cycling() -> void:
	var tm := TurnManager.new()
	var p := [_make_unit(UnitData.Team.PLAYER)]
	var e := [_make_unit(UnitData.Team.ENEMY)]
	tm.setup(p, e)

	_assert("cycle_start_player", tm.current_phase == TurnManager.Phase.PLAYER_PHASE)
	tm.start_enemy_phase()
	_assert("cycle_to_enemy", tm.current_phase == TurnManager.Phase.ENEMY_PHASE)
	tm.start_player_phase()
	_assert("cycle_back_player", tm.current_phase == TurnManager.Phase.PLAYER_PHASE)


func _test_exhaustion_check() -> void:
	var tm := TurnManager.new()
	var p1 := _make_unit(UnitData.Team.PLAYER)
	var p2 := _make_unit(UnitData.Team.PLAYER)
	tm.setup([p1, p2], [_make_unit(UnitData.Team.ENEMY)])

	_assert("phase_not_done", not tm.is_phase_done())
	p1.exhaust()
	_assert("phase_still_not_done", not tm.is_phase_done())
	p2.exhaust()
	_assert("phase_done", tm.is_phase_done())


func _test_reset_on_phase() -> void:
	var tm := TurnManager.new()
	var p := _make_unit(UnitData.Team.PLAYER)
	p.exhaust()
	tm.setup([p], [_make_unit(UnitData.Team.ENEMY)])

	# After setup, player units should be reset
	_assert("reset_moved", not p.has_moved)
	_assert("reset_acted", not p.has_acted)
	_assert("reset_exhausted", not p.is_exhausted)


func _test_victory_detection() -> void:
	var tm := TurnManager.new()
	var p := _make_unit(UnitData.Team.PLAYER)
	var e := _make_unit(UnitData.Team.ENEMY)
	tm.setup([p], [e])

	e.is_alive = false
	var result := tm.check_battle_end()
	_assert("victory", result == TurnManager.BattleResult.VICTORY)


func _test_defeat_detection() -> void:
	var tm := TurnManager.new()
	var p := _make_unit(UnitData.Team.PLAYER)
	var e := _make_unit(UnitData.Team.ENEMY)
	tm.setup([p], [e])

	p.is_alive = false
	var result := tm.check_battle_end()
	_assert("defeat", result == TurnManager.BattleResult.DEFEAT)


func _test_no_end_while_alive() -> void:
	var tm := TurnManager.new()
	var p := _make_unit(UnitData.Team.PLAYER)
	var e := _make_unit(UnitData.Team.ENEMY)
	tm.setup([p], [e])

	var result := tm.check_battle_end()
	_assert("no_end", result == TurnManager.BattleResult.NONE)


func _make_unit(team: UnitData.Team) -> UnitData:
	var u := UnitData.new()
	u.team = team
	u.unit_name = "Test"
	u.is_alive = true
	u.max_hp = 10
	u.hp = 10
	return u


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "turn_" + name, "status": status})
	print("  [%s] turn_%s" % [status, name])
