class_name AIBrain
extends RefCounted

## Simple enemy AI: find nearest enemy, attack if possible, else move closer.


static func decide(unit: UnitData, grid: BattleGrid, targets: Array) -> Dictionary:
	## Returns { "type": "move_attack"|"move"|"wait", "move_to": Vector2i, "target": UnitData|null }
	if targets.is_empty():
		return { "type": "wait", "move_to": unit.grid_pos, "target": null }

	# Get movement range
	var move_cells := Pathfinder.get_movement_range(grid, unit.grid_pos, unit.mov, unit.team)
	move_cells.append(unit.grid_pos)  # Can stay in place

	# Find best move+attack combination
	var best_move: Vector2i = unit.grid_pos
	var best_target: UnitData = null
	var best_distance: int = 999

	for cell in move_cells:
		var attack_cells := Pathfinder.get_attack_range(grid, cell, unit.attack_range)
		for target in targets:
			if not (target is UnitData) or not target.is_alive:
				continue
			if target.grid_pos in attack_cells:
				var dist := _manhattan(cell, target.grid_pos)
				if best_target == null or dist < best_distance:
					best_move = cell
					best_target = target
					best_distance = dist

	if best_target != null:
		return { "type": "move_attack", "move_to": best_move, "target": best_target }

	# No attack possible — move toward nearest target
	var nearest_target: UnitData = null
	var nearest_dist: int = 999
	for target in targets:
		if not (target is UnitData) or not target.is_alive:
			continue
		var dist := _manhattan(unit.grid_pos, target.grid_pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_target = target

	if nearest_target == null:
		return { "type": "wait", "move_to": unit.grid_pos, "target": null }

	# Find the move cell closest to the target
	var closest_cell: Vector2i = unit.grid_pos
	var closest_dist: int = nearest_dist
	for cell in move_cells:
		if cell == unit.grid_pos:
			continue
		var dist := _manhattan(cell, nearest_target.grid_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_cell = cell

	return { "type": "move", "move_to": closest_cell, "target": null }


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
