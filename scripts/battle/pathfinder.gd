class_name Pathfinder
extends RefCounted

## Grid pathfinding: Dijkstra flood fill for movement range, A* for paths.
## Pure logic — no Node dependencies.


static func get_movement_range(grid: BattleGrid, origin: Vector2i, move_points: int, team: UnitData.Team) -> Array[Vector2i]:
	## Dijkstra flood fill. Returns all reachable cells within move_points.
	## Units pass through allies but can't stop on occupied cells.
	## Enemy units block movement.
	var result: Array[Vector2i] = []
	var costs: Dictionary = {}  # Vector2i -> int (lowest cost to reach)
	var frontier: Array = []  # [cost, Vector2i]

	costs[origin] = 0
	frontier.append([0, origin])

	while frontier.size() > 0:
		# Find lowest cost in frontier (simple priority queue)
		var best_idx := 0
		for i in range(1, frontier.size()):
			if frontier[i][0] < frontier[best_idx][0]:
				best_idx = i
		var current: Array = frontier[best_idx]
		frontier.remove_at(best_idx)

		var cost: int = current[0]
		var pos: Vector2i = current[1]

		if cost > costs.get(pos, 999):
			continue

		for neighbor in grid.get_neighbors(pos):
			var tile := grid.get_tile(neighbor)
			if tile == null or tile.impassable:
				continue

			# Check if enemy blocks this cell
			var occupant = grid.get_unit_at(neighbor)
			if occupant != null and occupant is UnitData:
				if occupant.team != team:
					continue  # Enemy blocks

			var new_cost: int = cost + tile.move_cost
			if new_cost > move_points:
				continue

			if new_cost < costs.get(neighbor, 999):
				costs[neighbor] = new_cost
				frontier.append([new_cost, neighbor])

	# Build result: all reachable cells (excluding origin and occupied cells)
	for pos in costs:
		if pos == origin:
			continue
		# Can't stop on an occupied cell (even ally)
		if grid.get_unit_at(pos) != null:
			continue
		result.append(pos)

	return result


static func find_path(grid: BattleGrid, start: Vector2i, goal: Vector2i, move_points: int, team: UnitData.Team) -> Array[Vector2i]:
	## A* pathfinding from start to goal. Returns path (excluding start, including goal).
	## Returns empty array if no path found within move_points.
	if start == goal:
		return []

	var open_set: Array = []  # [f_score, g_score, Vector2i]
	var came_from: Dictionary = {}
	var g_scores: Dictionary = {}

	g_scores[start] = 0
	var h := _heuristic(start, goal)
	open_set.append([h, 0, start])

	while open_set.size() > 0:
		# Find lowest f_score
		var best_idx := 0
		for i in range(1, open_set.size()):
			if open_set[i][0] < open_set[best_idx][0]:
				best_idx = i
		var current_entry: Array = open_set[best_idx]
		open_set.remove_at(best_idx)

		var g: int = current_entry[1]
		var pos: Vector2i = current_entry[2]

		if pos == goal:
			return _reconstruct_path(came_from, goal)

		if g > g_scores.get(pos, 999):
			continue

		for neighbor in grid.get_neighbors(pos):
			var tile := grid.get_tile(neighbor)
			if tile == null or tile.impassable:
				continue

			# Enemy blocks (unless neighbor is the goal and we're attacking)
			var occupant = grid.get_unit_at(neighbor)
			if occupant != null and occupant is UnitData:
				if occupant.team != team and neighbor != goal:
					continue

			var new_g: int = g + tile.move_cost
			if new_g > move_points:
				continue

			if new_g < g_scores.get(neighbor, 999):
				g_scores[neighbor] = new_g
				came_from[neighbor] = pos
				var f: int = new_g + _heuristic(neighbor, goal)
				open_set.append([f, new_g, neighbor])

	return []  # No path found


static func get_attack_range(grid: BattleGrid, origin: Vector2i, attack_range: int) -> Array[Vector2i]:
	## Manhattan distance-based attack range. Returns all cells in range.
	var result: Array[Vector2i] = []
	for dx in range(-attack_range, attack_range + 1):
		for dy in range(-attack_range, attack_range + 1):
			var dist := absi(dx) + absi(dy)
			if dist == 0 or dist > attack_range:
				continue
			var pos := origin + Vector2i(dx, dy)
			if grid.is_in_bounds(pos):
				result.append(pos)
	return result


static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	# Remove start position
	if path.size() > 0:
		path.remove_at(0)
	return path
