class_name TestItems
extends RefCounted

## Tests for ItemData — creation from dict, type helpers, prices, weapon/armor/consumable fields.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_weapon_from_dict()
	_test_armor_from_dict()
	_test_consumable_from_dict()
	_test_type_helpers()
	_test_weapon_stats()
	_test_armor_stats()
	_test_consumable_effects()
	_test_to_dict_roundtrip()
	_test_default_values()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_weapon_from_dict() -> void:
	var d := { "id": "iron_sword", "name": "Iron Sword", "type": "weapon", "subtype": "melee", "atk": 5, "hit": 5, "crit": 0, "range": 1, "price": 120 }
	var item := ItemData.from_dict(d)
	_assert("weapon_id", item.id == "iron_sword")
	_assert("weapon_name", item.item_name == "Iron Sword")
	_assert("weapon_type", item.type == "weapon")
	_assert("weapon_subtype", item.subtype == "melee")
	_assert("weapon_price", item.price == 120)


func _test_armor_from_dict() -> void:
	var d := { "id": "chain_mail", "name": "Chain Mail", "type": "armor", "def": 6, "spd": -1, "price": 200 }
	var item := ItemData.from_dict(d)
	_assert("armor_id", item.id == "chain_mail")
	_assert("armor_type", item.type == "armor")
	_assert("armor_def", item.def_bonus == 6)
	_assert("armor_spd", item.spd_bonus == -1)
	_assert("armor_price", item.price == 200)


func _test_consumable_from_dict() -> void:
	var d := { "id": "herb", "name": "Herb", "type": "consumable", "effect": "heal", "power": 15, "price": 10 }
	var item := ItemData.from_dict(d)
	_assert("consumable_id", item.id == "herb")
	_assert("consumable_type", item.type == "consumable")
	_assert("consumable_effect", item.effect == "heal")
	_assert("consumable_power", item.power == 15)


func _test_type_helpers() -> void:
	var weapon := ItemData.from_dict({ "type": "weapon" })
	_assert("is_weapon_true", weapon.is_weapon())
	_assert("is_weapon_not_armor", not weapon.is_armor())
	_assert("is_weapon_not_consumable", not weapon.is_consumable())

	var armor := ItemData.from_dict({ "type": "armor" })
	_assert("is_armor_true", armor.is_armor())
	_assert("is_armor_not_weapon", not armor.is_weapon())

	var consumable := ItemData.from_dict({ "type": "consumable" })
	_assert("is_consumable_true", consumable.is_consumable())
	_assert("is_usable_in_battle", consumable.is_usable_in_battle())
	_assert("weapon_not_usable", not weapon.is_usable_in_battle())


func _test_weapon_stats() -> void:
	var d := { "type": "weapon", "atk": 5, "hit": 10, "crit": 3, "range": 2 }
	var item := ItemData.from_dict(d)
	_assert("weapon_atk", item.atk_bonus == 5)
	_assert("weapon_hit", item.hit_bonus == 10)
	_assert("weapon_crit", item.crit_bonus == 3)
	_assert("weapon_range", item.weapon_range == 2)


func _test_armor_stats() -> void:
	var d := { "type": "armor", "def": 4, "spd": -2 }
	var item := ItemData.from_dict(d)
	_assert("armor_def_bonus", item.def_bonus == 4)
	_assert("armor_spd_bonus", item.spd_bonus == -2)


func _test_consumable_effects() -> void:
	var heal := ItemData.from_dict({ "type": "consumable", "effect": "heal", "power": 15 })
	_assert("heal_effect", heal.effect == "heal")
	_assert("heal_power", heal.power == 15)

	var cure := ItemData.from_dict({ "type": "consumable", "effect": "cure_poison", "power": 0 })
	_assert("cure_effect", cure.effect == "cure_poison")

	var revive := ItemData.from_dict({ "type": "consumable", "effect": "revive", "power": 10 })
	_assert("revive_effect", revive.effect == "revive")
	_assert("revive_power", revive.power == 10)


func _test_to_dict_roundtrip() -> void:
	var original := { "id": "iron_sword", "name": "Iron Sword", "type": "weapon", "subtype": "melee", "atk": 5, "hit": 5, "crit": 0, "range": 1, "price": 120, "description": "A sturdy iron blade." }
	var item := ItemData.from_dict(original)
	var exported := item.to_dict()
	_assert("roundtrip_id", exported["id"] == "iron_sword")
	_assert("roundtrip_type", exported["type"] == "weapon")
	_assert("roundtrip_atk", exported["atk"] == 5)


func _test_default_values() -> void:
	var item := ItemData.from_dict({})
	_assert("default_id", item.id == "")
	_assert("default_name", item.item_name == "Unknown")
	_assert("default_type", item.type == "consumable")
	_assert("default_price", item.price == 0)


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "items_" + name, "status": status})
	print("  [%s] items_%s" % [status, name])
