class_name BattleActions
extends RefCounted

## Single place that mutates BattleGrid occupancy and UnitData in sync.


static func move_unit(grid: BattleGrid, unit: UnitData, target: Vector2i) -> void:
	## Move unit to target cell. Updates grid occupancy and unit position.
	grid.remove_unit_at(unit.grid_pos)
	unit.grid_pos = target
	grid.place_unit(unit, target)
	unit.has_moved = true


static func attack(attacker: UnitData, defender: UnitData, grid: BattleGrid, rng: Variant) -> Dictionary:
	## Execute attack. Returns combat result dict. Applies damage to defender.
	var defender_tile := grid.get_tile(defender.grid_pos)
	var result := CombatCalc.resolve(attacker, defender, defender_tile, rng)

	if result["hit"]:
		defender.take_damage(result["damage"])
		result["defender_alive"] = defender.is_alive
		if not defender.is_alive:
			grid.remove_unit_at(defender.grid_pos)
	else:
		result["defender_alive"] = true

	attacker.has_acted = true
	return result


static func cast_spell(caster: UnitData, target: UnitData, spell: SpellData, grid: BattleGrid, rng: Variant) -> Dictionary:
	## Cast spell on target. Deducts MP, applies damage/heal/status. Returns result dict.
	# Deduct MP
	caster.mp = maxi(0, caster.mp - spell.mp_cost)

	var target_tile := grid.get_tile(target.grid_pos)
	var result := CombatCalc.resolve_spell(caster, target, spell, target_tile, rng)

	if spell.is_support():
		# Heal spell
		target.heal(result.get("heal_amount", 0))
		result["target_alive"] = target.is_alive
	else:
		# Offensive spell
		if result["hit"]:
			target.take_damage(result["damage"])
			result["target_alive"] = target.is_alive
			if not target.is_alive:
				grid.remove_unit_at(target.grid_pos)
			# Apply status effect
			var status_name: String = result.get("status_applied", "")
			if status_name != "":
				var effect := StatusEffect.from_name(status_name)
				if effect != null and target.is_alive:
					target.add_status(effect)
		else:
			result["target_alive"] = true

	caster.has_acted = true
	return result


static func use_item(user: UnitData, target: UnitData, item: ItemData) -> Dictionary:
	## Use consumable item from user's inventory on target. Consumes the item.
	var result: Dictionary = {
		"item_name": item.item_name,
		"effect": item.effect,
		"user_name": user.unit_name,
		"target_name": target.unit_name,
		"success": false,
	}

	# Remove from inventory
	if not user.remove_from_inventory(item):
		return result

	result["success"] = true

	match item.effect:
		"heal":
			target.heal(item.power)
			result["heal_amount"] = item.power
		"cure_poison":
			target.clear_status(StatusEffect.Type.POISON)
			result["status_cured"] = "poison"
		"revive":
			if not target.is_alive:
				target.is_alive = true
				target.hp = item.power
				result["revive_hp"] = item.power
			else:
				# Already alive — just heal
				target.heal(item.power)
				result["heal_amount"] = item.power

	user.has_acted = true
	return result


static func wait(unit: UnitData) -> void:
	## End unit's turn without acting.
	unit.exhaust()
