class_name CombatCalc
extends RefCounted

## Deterministic combat formulas. Pure static methods — no Node dependencies.


static func preview(attacker: UnitData, defender: UnitData, terrain_tile: BattleTile) -> Dictionary:
	## Pure preview — no RNG. Returns predicted damage/hit%/crit%.
	var damage: int = maxi(1, attacker.atk - (defender.defense + terrain_tile.def_bonus))
	var hit_chance: int = clampi(80 - terrain_tile.eva_bonus, 5, 99)
	var spd_diff: int = attacker.spd - defender.spd
	var crit_chance: int = clampi(5 + spd_diff, 1, 25)

	return {
		"damage": damage,
		"hit_chance": hit_chance,
		"crit_chance": crit_chance,
		"attacker_name": attacker.unit_name,
		"defender_name": defender.unit_name,
	}


static func resolve(attacker: UnitData, defender: UnitData, terrain_tile: BattleTile, rng: RandomNumberGenerator) -> Dictionary:
	## Resolves combat with RNG. Returns full result dict.
	var prev := preview(attacker, defender, terrain_tile)

	var hit_roll: int = rng.randi_range(1, 100)
	var hit: bool = hit_roll <= int(prev["hit_chance"])

	var crit: bool = false
	var final_damage: int = 0

	if hit:
		var crit_roll: int = rng.randi_range(1, 100)
		crit = crit_roll <= int(prev["crit_chance"])
		final_damage = int(prev["damage"])
		if crit:
			final_damage = int(final_damage * 1.5)

	return {
		"hit": hit,
		"crit": crit,
		"damage": final_damage,
		"hit_roll": hit_roll,
		"hit_chance": prev["hit_chance"],
		"crit_chance": prev["crit_chance"],
		"predicted_damage": prev["damage"],
		"attacker_name": attacker.unit_name,
		"defender_name": defender.unit_name,
	}
