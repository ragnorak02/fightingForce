class_name BattleActions
extends RefCounted

## Single place that mutates BattleGrid occupancy and UnitData in sync.


static func move_unit(grid: BattleGrid, unit: UnitData, target: Vector2i) -> void:
	## Move unit to target cell. Updates grid occupancy and unit position.
	grid.remove_unit_at(unit.grid_pos)
	unit.grid_pos = target
	grid.place_unit(unit, target)
	unit.has_moved = true


static func attack(attacker: UnitData, defender: UnitData, grid: BattleGrid, rng: RandomNumberGenerator) -> Dictionary:
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


static func wait(unit: UnitData) -> void:
	## End unit's turn without acting.
	unit.exhaust()
