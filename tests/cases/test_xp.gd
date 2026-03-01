class_name TestXP
extends RefCounted

## Tests for XPSystem — XP calc, level-up, stat growth, carry-over.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_calc_xp_same_level()
	_test_calc_xp_higher_enemy()
	_test_calc_xp_lower_enemy()
	_test_calc_xp_minimum()
	_test_check_level_up()
	_test_apply_level_up()
	_test_level_up_stat_growth()
	_test_level_up_deducts_xp()
	_test_xp_carry_over()
	_test_no_level_up_insufficient()
	_test_award_kill_xp()
	_test_level_progress()
	_test_multiple_level_ups()
	_test_level_up_learns_spell()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_calc_xp_same_level() -> void:
	# Same level: 30 + 0*5 = 30
	var xp: int = XPSystem.calc_xp(1, 1)
	_assert("same_level_30", xp == 30)


func _test_calc_xp_higher_enemy() -> void:
	# Enemy 3 levels higher: 30 + 3*5 = 45
	var xp: int = XPSystem.calc_xp(1, 4)
	_assert("higher_enemy_45", xp == 45)


func _test_calc_xp_lower_enemy() -> void:
	# Enemy 2 levels lower: 30 + (-2)*5 = 20
	var xp: int = XPSystem.calc_xp(5, 3)
	_assert("lower_enemy_20", xp == 20)


func _test_calc_xp_minimum() -> void:
	# Very low enemy: 30 + (-10)*5 = -20 -> clamped to 10
	var xp: int = XPSystem.calc_xp(15, 5)
	_assert("min_xp_10", xp == 10)


func _test_check_level_up() -> void:
	var u := _make_unit()
	u.xp = 50
	_assert("no_level_at_50", not XPSystem.check_level_up(u))
	u.xp = 100
	_assert("level_at_100", XPSystem.check_level_up(u))
	u.xp = 150
	_assert("level_at_150", XPSystem.check_level_up(u))


func _test_apply_level_up() -> void:
	var u := _make_unit_with_growth()
	u.xp = 100
	var gains := XPSystem.apply_level_up(u)
	_assert("level_up_success", gains.size() > 0)
	_assert("level_now_2", u.level == 2)


func _test_level_up_stat_growth() -> void:
	var u := _make_unit_with_growth()
	var old_hp: int = u.max_hp
	var old_atk: int = u.atk
	u.xp = 100
	var gains := XPSystem.apply_level_up(u)
	_assert("hp_grew", u.max_hp == old_hp + gains["hp"])
	_assert("atk_grew", u.atk == old_atk + gains["atk"])
	_assert("growth_hp_3", gains["hp"] == 3)
	_assert("growth_atk_2", gains["atk"] == 2)


func _test_level_up_deducts_xp() -> void:
	var u := _make_unit_with_growth()
	u.xp = 120
	XPSystem.apply_level_up(u)
	_assert("xp_deducted", u.xp == 20)


func _test_xp_carry_over() -> void:
	var u := _make_unit_with_growth()
	u.xp = 230
	XPSystem.apply_level_up(u)
	_assert("carry_over_130", u.xp == 130)
	# Can level again
	_assert("can_level_again", XPSystem.check_level_up(u))
	XPSystem.apply_level_up(u)
	_assert("level_3", u.level == 3)
	_assert("carry_over_30", u.xp == 30)


func _test_no_level_up_insufficient() -> void:
	var u := _make_unit_with_growth()
	u.xp = 50
	var gains := XPSystem.apply_level_up(u)
	_assert("no_gains", gains.size() == 0)
	_assert("still_level_1", u.level == 1)


func _test_award_kill_xp() -> void:
	var attacker := _make_unit()
	var defeated := _make_unit()
	defeated.level = 3
	var xp: int = XPSystem.award_kill_xp(attacker, defeated)
	# 30 + (3-1)*5 = 40
	_assert("award_40", xp == 40)
	_assert("attacker_xp_40", attacker.xp == 40)


func _test_level_progress() -> void:
	var u := _make_unit()
	u.xp = 0
	_assert("progress_0", XPSystem.get_level_progress(u) == 0.0)
	u.xp = 50
	_assert("progress_50", XPSystem.get_level_progress(u) == 0.5)
	u.xp = 100
	_assert("progress_100", XPSystem.get_level_progress(u) == 1.0)


func _test_multiple_level_ups() -> void:
	var u := _make_unit_with_growth()
	u.xp = 0
	# Award enough XP for 2 levels
	u.add_xp(200)
	XPSystem.apply_level_up(u)
	XPSystem.apply_level_up(u)
	_assert("multi_level_3", u.level == 3)


func _test_level_up_learns_spell() -> void:
	var u := _make_unit_with_growth()
	u._class_spells = [
		{ "id": "blaze", "level": 1 },
		{ "id": "heal", "level": 3 },
	]
	# At level 1, should know blaze
	u._update_known_spells()
	_assert("knows_blaze_at_1", u.known_spells.size() == 1)
	_assert("first_spell_blaze", u.known_spells[0].id == "blaze")
	# Level up to 3
	u.xp = 200
	u.level_up()
	u.level_up()
	_assert("now_level_3", u.level == 3)
	_assert("knows_heal_at_3", u.known_spells.size() == 2)


# --- Helpers ---

func _make_unit() -> UnitData:
	var u := UnitData.new()
	u.unit_name = "Test"
	u.max_hp = 20
	u.hp = 20
	u.atk = 8
	u.defense = 4
	u.spd = 5
	u.mov = 4
	u.level = 1
	u.xp = 0
	return u


func _make_unit_with_growth() -> UnitData:
	var u := _make_unit()
	u._growth = { "hp": 3, "mp": 0, "atk": 2, "def": 1, "spd": 1 }
	return u


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "xp_" + name, "status": status})
	print("  [%s] xp_%s" % [status, name])
