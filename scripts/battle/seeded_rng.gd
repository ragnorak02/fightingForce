class_name SeededRNG
extends RefCounted

## Wraps RandomNumberGenerator with draw counting for determinism auditing.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var draw_count: int = 0


func setup(seed_value: int) -> void:
	_rng.seed = seed_value
	draw_count = 0


func roll_hit(hit_chance: int) -> bool:
	## Roll 1-100 against hit_chance%. Returns true on hit.
	draw_count += 1
	var roll: int = _rng.randi_range(1, 100)
	return roll <= hit_chance


func roll_crit(crit_chance: int) -> bool:
	## Roll 1-100 against crit_chance%. Returns true on crit.
	draw_count += 1
	var roll: int = _rng.randi_range(1, 100)
	return roll <= crit_chance


func roll_status(status_chance: int) -> bool:
	## Roll 1-100 against status_chance%. Returns true if status applied.
	draw_count += 1
	var roll: int = _rng.randi_range(1, 100)
	return roll <= status_chance


func randi_range(low: int, high: int) -> int:
	## General-purpose roll. Increments draw count.
	draw_count += 1
	return _rng.randi_range(low, high)


func get_raw_rng() -> RandomNumberGenerator:
	return _rng
