class_name TestStatus
extends RefCounted

## Tests for StatusEffect — poison/slow creation, tick, expiry, unit integration.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_poison_creation()
	_test_slow_creation()
	_test_from_name()
	_test_from_name_invalid()
	_test_poison_tick()
	_test_poison_expiry()
	_test_slow_modifiers()
	_test_slow_expiry()
	_test_unit_add_status()
	_test_unit_has_status()
	_test_unit_status_no_stack()
	_test_unit_tick_poison_damage()
	_test_unit_tick_removes_expired()
	_test_unit_clear_status()
	_test_unit_clear_all_status()
	_test_slow_affects_mov()
	_test_slow_affects_spd()
	_test_poison_kills()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_poison_creation() -> void:
	var e := StatusEffect.create_poison()
	_assert("poison_type", e.effect_type == StatusEffect.Type.POISON)
	_assert("poison_turns", e.turns_remaining == 3)
	_assert("poison_dmg", e.damage_per_turn == 3)
	_assert("poison_name", e.get_type_name() == "Poison")


func _test_slow_creation() -> void:
	var e := StatusEffect.create_slow()
	_assert("slow_type", e.effect_type == StatusEffect.Type.SLOW)
	_assert("slow_turns", e.turns_remaining == 2)
	_assert("slow_spd_mod", e.spd_modifier == -3)
	_assert("slow_mov_mod", e.mov_modifier == -1)
	_assert("slow_name", e.get_type_name() == "Slow")


func _test_from_name() -> void:
	var p := StatusEffect.from_name("poison")
	_assert("from_name_poison", p != null and p.effect_type == StatusEffect.Type.POISON)
	var s := StatusEffect.from_name("slow")
	_assert("from_name_slow", s != null and s.effect_type == StatusEffect.Type.SLOW)


func _test_from_name_invalid() -> void:
	var n := StatusEffect.from_name("nonexistent")
	_assert("from_name_null", n == null)


func _test_poison_tick() -> void:
	var e := StatusEffect.create_poison()
	var result := e.tick()
	_assert("poison_tick_dmg", result["damage"] == 3)
	_assert("poison_tick_not_expired", not result["expired"])
	_assert("poison_turns_left_2", e.turns_remaining == 2)


func _test_poison_expiry() -> void:
	var e := StatusEffect.create_poison()
	e.tick()  # 2 left
	e.tick()  # 1 left
	var result := e.tick()  # 0 left
	_assert("poison_expired", result["expired"])


func _test_slow_modifiers() -> void:
	var e := StatusEffect.create_slow()
	_assert("slow_spd", e.spd_modifier == -3)
	_assert("slow_mov", e.mov_modifier == -1)
	_assert("slow_no_dmg", e.damage_per_turn == 0)


func _test_slow_expiry() -> void:
	var e := StatusEffect.create_slow()
	e.tick()  # 1 left
	var result := e.tick()  # 0 left
	_assert("slow_expired", result["expired"])
	_assert("slow_no_tick_dmg", result["damage"] == 0)


func _test_unit_add_status() -> void:
	var u := _make_unit()
	u.add_status(StatusEffect.create_poison())
	_assert("add_status_count", u.status_effects.size() == 1)


func _test_unit_has_status() -> void:
	var u := _make_unit()
	_assert("no_status_initially", not u.has_status(StatusEffect.Type.POISON))
	u.add_status(StatusEffect.create_poison())
	_assert("has_poison", u.has_status(StatusEffect.Type.POISON))
	_assert("no_slow", not u.has_status(StatusEffect.Type.SLOW))


func _test_unit_status_no_stack() -> void:
	var u := _make_unit()
	u.add_status(StatusEffect.create_poison())
	u.add_status(StatusEffect.create_poison())
	_assert("no_stack", u.status_effects.size() == 1)


func _test_unit_tick_poison_damage() -> void:
	var u := _make_unit()
	u.hp = 20
	u.add_status(StatusEffect.create_poison())
	var results := u.tick_status_effects()
	_assert("tick_result_count", results.size() == 1)
	_assert("tick_damage", results[0]["damage"] == 3)
	_assert("tick_hp_reduced", u.hp == 17)


func _test_unit_tick_removes_expired() -> void:
	var u := _make_unit()
	var e := StatusEffect.create_poison()
	e.turns_remaining = 1
	u.add_status(e)
	u.tick_status_effects()
	_assert("expired_removed", u.status_effects.size() == 0)


func _test_unit_clear_status() -> void:
	var u := _make_unit()
	u.add_status(StatusEffect.create_poison())
	u.add_status(StatusEffect.create_slow())
	u.clear_status(StatusEffect.Type.POISON)
	_assert("clear_poison", not u.has_status(StatusEffect.Type.POISON))
	_assert("slow_remains", u.has_status(StatusEffect.Type.SLOW))


func _test_unit_clear_all_status() -> void:
	var u := _make_unit()
	u.add_status(StatusEffect.create_poison())
	u.add_status(StatusEffect.create_slow())
	u.clear_all_status()
	_assert("clear_all", u.status_effects.size() == 0)


func _test_slow_affects_mov() -> void:
	var u := _make_unit()
	u.mov = 4
	u.add_status(StatusEffect.create_slow())
	_assert("slow_reduces_mov", u.get_effective_mov() == 3)


func _test_slow_affects_spd() -> void:
	var u := _make_unit()
	u.spd = 5
	u.add_status(StatusEffect.create_slow())
	_assert("slow_reduces_spd", u.get_effective_spd() == 2)


func _test_poison_kills() -> void:
	var u := _make_unit()
	u.hp = 2
	u.add_status(StatusEffect.create_poison())
	u.tick_status_effects()
	_assert("poison_kills", not u.is_alive)


# --- Helpers ---

func _make_unit() -> UnitData:
	var u := UnitData.new()
	u.unit_name = "Test"
	u.max_hp = 50
	u.hp = 50
	u.atk = 8
	u.defense = 4
	u.spd = 5
	u.mov = 4
	return u


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "status_" + name, "status": status})
	print("  [%s] status_%s" % [status, name])
