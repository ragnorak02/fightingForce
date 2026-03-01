class_name TestInventory
extends RefCounted

## Tests for unit inventory slots, equip/unequip, and PartyStorage.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_equip_weapon()
	_test_equip_armor()
	_test_equip_swap()
	_test_effective_atk()
	_test_effective_def()
	_test_effective_spd_armor()
	_test_effective_range_weapon()
	_test_effective_attack_type()
	_test_no_weapon_defaults()
	_test_unit_inventory_add()
	_test_unit_inventory_full()
	_test_unit_inventory_remove()
	_test_unit_inventory_remove_at()
	_test_usable_items()
	_test_party_storage_add()
	_test_party_storage_full()
	_test_party_storage_remove()
	_test_party_storage_remove_by_id()
	_test_party_storage_by_type()
	_test_party_storage_save_load()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_equip_weapon() -> void:
	var u := _make_unit()
	var sword := _make_weapon("iron_sword", 5, 5, 0, 1)
	var old: Variant = u.equip_weapon(sword)
	_assert("equip_weapon_old_null", old == null)
	_assert("equip_weapon_set", u.weapon == sword)


func _test_equip_armor() -> void:
	var u := _make_unit()
	var armor := _make_armor("leather_armor", 3, 0)
	var old: Variant = u.equip_armor(armor)
	_assert("equip_armor_old_null", old == null)
	_assert("equip_armor_set", u.armor == armor)


func _test_equip_swap() -> void:
	var u := _make_unit()
	var sword1 := _make_weapon("iron_sword", 5, 5, 0, 1)
	var sword2 := _make_weapon("bronze_sword", 3, 10, 0, 1)
	u.equip_weapon(sword1)
	var returned: Variant = u.equip_weapon(sword2)
	_assert("swap_returns_old", returned == sword1)
	_assert("swap_new_equipped", u.weapon == sword2)


func _test_effective_atk() -> void:
	var u := _make_unit()
	u.atk = 8
	_assert("eff_atk_no_weapon", u.get_effective_atk() == 8)
	u.equip_weapon(_make_weapon("sword", 5, 0, 0, 1))
	_assert("eff_atk_with_weapon", u.get_effective_atk() == 13)


func _test_effective_def() -> void:
	var u := _make_unit()
	u.defense = 4
	_assert("eff_def_no_armor", u.get_effective_def() == 4)
	u.equip_armor(_make_armor("chain", 6, 0))
	_assert("eff_def_with_armor", u.get_effective_def() == 10)


func _test_effective_spd_armor() -> void:
	var u := _make_unit()
	u.spd = 5
	u.equip_armor(_make_armor("chain", 6, -1))
	_assert("eff_spd_armor_penalty", u.get_effective_spd() == 4)


func _test_effective_range_weapon() -> void:
	var u := _make_unit()
	u.attack_range = 1
	_assert("eff_range_no_weapon", u.get_effective_range() == 1)
	u.equip_weapon(_make_weapon("bow", 3, 0, 0, 3))
	_assert("eff_range_with_bow", u.get_effective_range() == 3)


func _test_effective_attack_type() -> void:
	var u := _make_unit()
	u.attack_type = UnitData.AttackType.MELEE
	_assert("eff_type_default", u.get_effective_attack_type() == UnitData.AttackType.MELEE)
	var bow := _make_weapon("bow", 3, 0, 0, 2)
	bow.subtype = "ranged"
	u.equip_weapon(bow)
	_assert("eff_type_ranged", u.get_effective_attack_type() == UnitData.AttackType.RANGED)


func _test_no_weapon_defaults() -> void:
	var u := _make_unit()
	_assert("hit_bonus_no_weapon", u.get_effective_hit_bonus() == 0)
	_assert("crit_bonus_no_weapon", u.get_effective_crit_bonus() == 0)
	u.equip_weapon(_make_weapon("dagger", 2, 5, 10, 1))
	_assert("hit_bonus_with_weapon", u.get_effective_hit_bonus() == 5)
	_assert("crit_bonus_with_weapon", u.get_effective_crit_bonus() == 10)


func _test_unit_inventory_add() -> void:
	var u := _make_unit()
	var herb := _make_consumable("herb", "heal", 15)
	_assert("inv_add_success", u.add_to_inventory(herb))
	_assert("inv_size_1", u.inventory.size() == 1)


func _test_unit_inventory_full() -> void:
	var u := _make_unit()
	for i in 4:
		u.add_to_inventory(_make_consumable("herb_%d" % i, "heal", 15))
	_assert("inv_full", u.inventory_full())
	_assert("inv_add_fails", not u.add_to_inventory(_make_consumable("extra", "heal", 5)))


func _test_unit_inventory_remove() -> void:
	var u := _make_unit()
	var herb := _make_consumable("herb", "heal", 15)
	u.add_to_inventory(herb)
	_assert("inv_remove_success", u.remove_from_inventory(herb))
	_assert("inv_empty_after", u.inventory.size() == 0)
	_assert("inv_remove_missing", not u.remove_from_inventory(herb))


func _test_unit_inventory_remove_at() -> void:
	var u := _make_unit()
	var herb := _make_consumable("herb", "heal", 15)
	var antidote := _make_consumable("antidote", "cure_poison", 0)
	u.add_to_inventory(herb)
	u.add_to_inventory(antidote)
	var removed: Variant = u.remove_inventory_at(0)
	_assert("inv_remove_at_returns", removed == herb)
	_assert("inv_size_after_remove_at", u.inventory.size() == 1)
	_assert("inv_remove_at_oob", u.remove_inventory_at(5) == null)


func _test_usable_items() -> void:
	var u := _make_unit()
	u.add_to_inventory(_make_consumable("herb", "heal", 15))
	u.add_to_inventory(_make_weapon("sword", 5, 0, 0, 1))
	var usable := u.get_usable_items()
	_assert("usable_count", usable.size() == 1)
	_assert("usable_is_herb", usable[0].id == "herb")


func _test_party_storage_add() -> void:
	var storage := PartyStorage.new()
	var herb := _make_consumable("herb", "heal", 15)
	_assert("storage_add", storage.add_item(herb))
	_assert("storage_count_1", storage.count() == 1)


func _test_party_storage_full() -> void:
	var storage := PartyStorage.new()
	for i in PartyStorage.MAX_ITEMS:
		storage.add_item(_make_consumable("item_%d" % i, "heal", 1))
	_assert("storage_full", storage.is_full())
	_assert("storage_add_fails", not storage.add_item(_make_consumable("extra", "heal", 1)))


func _test_party_storage_remove() -> void:
	var storage := PartyStorage.new()
	var herb := _make_consumable("herb", "heal", 15)
	storage.add_item(herb)
	_assert("storage_remove", storage.remove_item(herb))
	_assert("storage_empty", storage.count() == 0)


func _test_party_storage_remove_by_id() -> void:
	var storage := PartyStorage.new()
	storage.add_item(_make_consumable("herb", "heal", 15))
	storage.add_item(_make_consumable("herb", "heal", 15))
	_assert("storage_remove_by_id", storage.remove_item_by_id("herb"))
	_assert("storage_one_left", storage.count() == 1)


func _test_party_storage_by_type() -> void:
	var storage := PartyStorage.new()
	storage.add_item(_make_consumable("herb", "heal", 15))
	storage.add_item(_make_weapon("sword", 5, 0, 0, 1))
	storage.add_item(_make_consumable("antidote", "cure_poison", 0))
	var consumables := storage.get_items_by_type("consumable")
	_assert("by_type_count", consumables.size() == 2)
	var weapons := storage.get_items_by_type("weapon")
	_assert("by_type_weapons", weapons.size() == 1)


func _test_party_storage_save_load() -> void:
	var storage := PartyStorage.new()
	storage.add_item(_make_consumable("herb", "heal", 15))
	storage.add_item(_make_weapon("sword", 5, 0, 0, 1))
	var saved := storage.to_save_data()
	var loaded := PartyStorage.from_save_data(saved)
	_assert("save_load_count", loaded.count() == 2)
	_assert("save_load_first_id", loaded.items[0].id == "herb")
	_assert("save_load_second_id", loaded.items[1].id == "sword")


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
	u.attack_range = 1
	return u


func _make_weapon(id: String, atk: int, hit: int, crit: int, rng: int) -> ItemData:
	return ItemData.from_dict({ "id": id, "type": "weapon", "subtype": "melee", "atk": atk, "hit": hit, "crit": crit, "range": rng })


func _make_armor(id: String, def: int, spd: int) -> ItemData:
	return ItemData.from_dict({ "id": id, "type": "armor", "def": def, "spd": spd })


func _make_consumable(id: String, effect: String, power: int) -> ItemData:
	return ItemData.from_dict({ "id": id, "type": "consumable", "effect": effect, "power": power })


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "inventory_" + name, "status": status})
	print("  [%s] inventory_%s" % [status, name])
