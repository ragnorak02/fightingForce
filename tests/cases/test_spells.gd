class_name TestSpells
extends RefCounted

## Tests for SpellData — creation, type helpers, status effects, MP cost.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_offense_from_dict()
	_test_support_from_dict()
	_test_status_effect_spell()
	_test_no_status_spell()
	_test_type_helpers()
	_test_default_values()
	_test_mp_cost()
	_test_spell_range()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_offense_from_dict() -> void:
	var d := { "id": "blaze", "name": "Blaze", "type": "offense", "element": "fire", "mpCost": 3, "power": 8, "hit": 90, "range": 2 }
	var s := SpellData.from_dict(d)
	_assert("offense_id", s.id == "blaze")
	_assert("offense_name", s.spell_name == "Blaze")
	_assert("offense_type", s.type == "offense")
	_assert("offense_element", s.element == "fire")
	_assert("offense_power", s.power == 8)
	_assert("offense_hit", s.hit_chance == 90)


func _test_support_from_dict() -> void:
	var d := { "id": "heal", "name": "Heal", "type": "support", "element": "holy", "mpCost": 3, "power": 15, "hit": 100, "range": 2 }
	var s := SpellData.from_dict(d)
	_assert("support_id", s.id == "heal")
	_assert("support_type", s.type == "support")
	_assert("support_power", s.power == 15)
	_assert("support_hit_100", s.hit_chance == 100)


func _test_status_effect_spell() -> void:
	var d := { "id": "freeze", "name": "Freeze", "type": "offense", "mpCost": 5, "power": 12, "hit": 80, "range": 2, "statusEffect": "slow", "statusChance": 40 }
	var s := SpellData.from_dict(d)
	_assert("status_effect_name", s.status_effect == "slow")
	_assert("status_chance", s.status_chance == 40)
	_assert("has_status", s.has_status_effect())


func _test_no_status_spell() -> void:
	var d := { "id": "blaze", "name": "Blaze", "type": "offense", "mpCost": 3, "power": 8, "hit": 90, "range": 2, "statusEffect": null }
	var s := SpellData.from_dict(d)
	_assert("no_status_effect", s.status_effect == "")
	_assert("no_status_chance", s.status_chance == 0)
	_assert("no_has_status", not s.has_status_effect())


func _test_type_helpers() -> void:
	var offense := SpellData.from_dict({ "type": "offense" })
	_assert("is_offensive", offense.is_offensive())
	_assert("not_support", not offense.is_support())

	var support := SpellData.from_dict({ "type": "support" })
	_assert("is_support", support.is_support())
	_assert("not_offensive", not support.is_offensive())


func _test_default_values() -> void:
	var s := SpellData.from_dict({})
	_assert("default_id", s.id == "")
	_assert("default_name", s.spell_name == "Unknown")
	_assert("default_type", s.type == "offense")
	_assert("default_mp", s.mp_cost == 0)
	_assert("default_range", s.spell_range == 2)


func _test_mp_cost() -> void:
	var cheap := SpellData.from_dict({ "mpCost": 2 })
	_assert("mp_cost_2", cheap.mp_cost == 2)

	var expensive := SpellData.from_dict({ "mpCost": 10 })
	_assert("mp_cost_10", expensive.mp_cost == 10)


func _test_spell_range() -> void:
	var short := SpellData.from_dict({ "range": 1 })
	_assert("range_1", short.spell_range == 1)

	var long := SpellData.from_dict({ "range": 3 })
	_assert("range_3", long.spell_range == 3)


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "spells_" + name, "status": status})
	print("  [%s] spells_%s" % [status, name])
