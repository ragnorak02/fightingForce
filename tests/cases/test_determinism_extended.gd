class_name TestDeterminismExtended
extends RefCounted

## Extended determinism tests: weapon combat, spell combat, status application.

var _results: Array = []
var _passed: int = 0
var _failed: int = 0


func run() -> Dictionary:
	_test_weapon_combat_determinism()
	_test_spell_combat_determinism()
	_test_spell_heal_determinism()
	_test_status_from_spell_determinism()
	_test_seeded_rng_draw_count()
	_test_item_use_determinism()
	_test_effective_stats_in_preview()
	_test_weapon_changes_preview()
	return { "results": _results, "passed": _passed, "failed": _failed }


func _test_weapon_combat_determinism() -> void:
	## Same weapon + seed -> same result
	var a1 := _make_armed_unit(10, 5, 5, 5, 5, 0)
	var d1 := _make_unit(5, 3, 5)
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 99999
	var r1 := CombatCalc.resolve(a1, d1, tile, rng1)

	# Reset defender
	d1.hp = d1.max_hp
	d1.is_alive = true

	var a2 := _make_armed_unit(10, 5, 5, 5, 5, 0)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99999
	var r2 := CombatCalc.resolve(a2, d1, tile, rng2)

	_assert("weapon_det_hit", r1["hit"] == r2["hit"])
	_assert("weapon_det_dmg", r1["damage"] == r2["damage"])
	_assert("weapon_det_crit", r1["crit"] == r2["crit"])


func _test_spell_combat_determinism() -> void:
	var caster1 := _make_unit(5, 3, 5)
	caster1.mp = 10
	var target1 := _make_unit(5, 3, 5)
	var spell := _make_spell("blaze", "offense", 8, 90, 3)
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 77777
	var r1 := CombatCalc.resolve_spell(caster1, target1, spell, tile, rng1)

	var caster2 := _make_unit(5, 3, 5)
	caster2.mp = 10
	target1.hp = target1.max_hp
	target1.is_alive = true
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 77777
	var r2 := CombatCalc.resolve_spell(caster2, target1, spell, tile, rng2)

	_assert("spell_det_hit", r1["hit"] == r2["hit"])
	_assert("spell_det_dmg", r1["damage"] == r2["damage"])


func _test_spell_heal_determinism() -> void:
	var caster := _make_unit(5, 3, 5)
	caster.mp = 10
	var target := _make_unit(5, 3, 5)
	target.hp = 10
	var spell := _make_spell("heal", "support", 15, 100, 3)
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 11111
	var r := CombatCalc.resolve_spell(caster, target, spell, tile, rng1)

	_assert("heal_auto_hit", r["hit"] == true)
	_assert("heal_amount", r["heal_amount"] == 15)


func _test_status_from_spell_determinism() -> void:
	var caster := _make_unit(5, 3, 5)
	caster.mp = 10
	var target := _make_unit(5, 3, 5)
	var spell := _make_spell("poison_cloud", "offense", 5, 85, 4)
	spell.status_effect = "poison"
	spell.status_chance = 60
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 55555
	var r1 := CombatCalc.resolve_spell(caster, target, spell, tile, rng1)

	target.hp = target.max_hp
	target.is_alive = true
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 55555
	var r2 := CombatCalc.resolve_spell(caster, target, spell, tile, rng2)

	_assert("status_det_hit", r1["hit"] == r2["hit"])
	_assert("status_det_applied", r1["status_applied"] == r2["status_applied"])


func _test_seeded_rng_draw_count() -> void:
	var srng := SeededRNG.new()
	srng.setup(42)
	_assert("draw_starts_0", srng.draw_count == 0)
	srng.roll_hit(50)
	_assert("draw_after_1", srng.draw_count == 1)
	srng.roll_crit(10)
	srng.roll_status(30)
	_assert("draw_after_3", srng.draw_count == 3)


func _test_item_use_determinism() -> void:
	var user := _make_unit(5, 3, 5)
	var target := _make_unit(5, 3, 5)
	target.hp = 10
	var herb := ItemData.from_dict({ "id": "herb", "type": "consumable", "effect": "heal", "power": 15 })
	user.add_to_inventory(herb)
	var result := BattleActions.use_item(user, target, herb)
	_assert("item_success", result["success"])
	_assert("item_healed", target.hp == 25)
	_assert("item_consumed", user.inventory.size() == 0)


func _test_effective_stats_in_preview() -> void:
	var attacker := _make_armed_unit(8, 5, 5, 5, 5, 0)
	var defender := _make_unit(5, 3, 5)
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)
	var preview := CombatCalc.preview(attacker, defender, tile)
	# atk = 8 + weapon 5 = 13, def = 3, dmg = 13 - 3 = 10
	_assert("eff_preview_dmg", preview["damage"] == 10)
	# hit = 80 + weapon_hit(5) = 85
	_assert("eff_preview_hit", preview["hit_chance"] == 85)


func _test_weapon_changes_preview() -> void:
	var attacker := _make_unit(8, 5, 5)
	var defender := _make_unit(5, 3, 5)
	var tile := BattleTile.from_type(BattleTile.TileType.GRASS)

	var p1 := CombatCalc.preview(attacker, defender, tile)
	# No weapon: atk=8, dmg = 8 - 3 = 5
	_assert("no_weapon_dmg_5", p1["damage"] == 5)

	# Equip weapon
	var sword := ItemData.from_dict({ "type": "weapon", "subtype": "melee", "atk": 5, "hit": 10, "crit": 3, "range": 1 })
	attacker.equip_weapon(sword)
	var p2 := CombatCalc.preview(attacker, defender, tile)
	# With weapon: atk=8+5=13, dmg = 13 - 3 = 10
	_assert("weapon_dmg_10", p2["damage"] == 10)
	# hit = 80 + 10 = 90
	_assert("weapon_hit_90", p2["hit_chance"] == 90)


# --- Helpers ---

func _make_unit(atk: int, defense: int, spd: int) -> UnitData:
	var u := UnitData.new()
	u.unit_name = "Test"
	u.max_hp = 50
	u.hp = 50
	u.atk = atk
	u.defense = defense
	u.spd = spd
	u.mov = 4
	return u


func _make_armed_unit(atk: int, defense: int, spd: int, w_atk: int, w_hit: int, w_crit: int) -> UnitData:
	var u := _make_unit(atk, defense, spd)
	var weapon := ItemData.from_dict({ "type": "weapon", "subtype": "melee", "atk": w_atk, "hit": w_hit, "crit": w_crit, "range": 1 })
	u.equip_weapon(weapon)
	return u


func _make_spell(id: String, type: String, power: int, hit: int, mp_cost: int) -> SpellData:
	return SpellData.from_dict({ "id": id, "type": type, "power": power, "hit": hit, "mpCost": mp_cost, "range": 2 })


func _assert(name: String, condition: bool) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		_passed += 1
	else:
		_failed += 1
	_results.append({"name": "det_ext_" + name, "status": status})
	print("  [%s] det_ext_%s" % [status, name])
