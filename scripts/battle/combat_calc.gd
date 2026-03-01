class_name CombatCalc
extends RefCounted

## Deterministic combat formulas. Pure static methods — no Node dependencies.


static func preview(attacker: UnitData, defender: UnitData, terrain_tile: BattleTile) -> Dictionary:
	## Pure preview — no RNG. Returns predicted damage/hit%/crit%.
	var eff_atk: int = attacker.get_effective_atk()
	var eff_def: int = defender.get_effective_def()
	var eff_spd_a: int = attacker.get_effective_spd()
	var eff_spd_d: int = defender.get_effective_spd()

	var damage: int = maxi(1, eff_atk - (eff_def + terrain_tile.def_bonus))
	var hit_chance: int = clampi(80 + attacker.get_effective_hit_bonus() - terrain_tile.eva_bonus, 5, 99)
	var spd_diff: int = eff_spd_a - eff_spd_d
	var crit_chance: int = clampi(5 + spd_diff + attacker.get_effective_crit_bonus(), 1, 25)

	return {
		"damage": damage,
		"hit_chance": hit_chance,
		"crit_chance": crit_chance,
		"attacker_name": attacker.unit_name,
		"defender_name": defender.unit_name,
	}


static func resolve(attacker: UnitData, defender: UnitData, terrain_tile: BattleTile, rng: Variant) -> Dictionary:
	## Resolves combat with RNG. rng can be RandomNumberGenerator or SeededRNG.
	var prev := preview(attacker, defender, terrain_tile)

	var hit: bool
	var crit: bool = false
	var final_damage: int = 0

	if rng is SeededRNG:
		hit = rng.roll_hit(int(prev["hit_chance"]))
		if hit:
			crit = rng.roll_crit(int(prev["crit_chance"]))
			final_damage = int(prev["damage"])
			if crit:
				final_damage = int(final_damage * 1.5)
	else:
		# Legacy RandomNumberGenerator support
		var hit_roll: int = rng.randi_range(1, 100)
		hit = hit_roll <= int(prev["hit_chance"])
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
		"hit_chance": prev["hit_chance"],
		"crit_chance": prev["crit_chance"],
		"predicted_damage": prev["damage"],
		"attacker_name": attacker.unit_name,
		"defender_name": defender.unit_name,
	}


static func preview_spell(caster: UnitData, target: UnitData, spell: SpellData, terrain_tile: BattleTile) -> Dictionary:
	## Preview spell effect. Offensive spells deal damage; support spells heal.
	if spell.is_support():
		return {
			"type": "support",
			"heal_amount": spell.power,
			"hit_chance": 100,
			"crit_chance": 0,
			"status_effect": "",
			"status_chance": 0,
			"mp_cost": spell.mp_cost,
			"spell_name": spell.spell_name,
			"caster_name": caster.unit_name,
			"target_name": target.unit_name,
		}

	# Offensive spell
	var damage: int = maxi(1, spell.power - (target.get_effective_def() / 2 + terrain_tile.def_bonus))
	var hit_chance: int = clampi(spell.hit_chance - terrain_tile.eva_bonus, 5, 99)

	return {
		"type": "offense",
		"damage": damage,
		"hit_chance": hit_chance,
		"crit_chance": 0,
		"status_effect": spell.status_effect,
		"status_chance": spell.status_chance,
		"mp_cost": spell.mp_cost,
		"spell_name": spell.spell_name,
		"caster_name": caster.unit_name,
		"target_name": target.unit_name,
	}


static func resolve_spell(caster: UnitData, target: UnitData, spell: SpellData, terrain_tile: BattleTile, rng: Variant) -> Dictionary:
	## Resolve spell with RNG. Deducts MP.
	var prev := preview_spell(caster, target, spell, terrain_tile)

	if spell.is_support():
		# Support spells auto-hit
		return {
			"type": "support",
			"hit": true,
			"heal_amount": spell.power,
			"status_applied": "",
			"spell_name": spell.spell_name,
			"caster_name": caster.unit_name,
			"target_name": target.unit_name,
		}

	# Offensive spell
	var hit: bool
	if rng is SeededRNG:
		hit = rng.roll_hit(int(prev["hit_chance"]))
	else:
		var roll: int = rng.randi_range(1, 100)
		hit = roll <= int(prev["hit_chance"])

	var final_damage: int = 0
	var status_applied: String = ""

	if hit:
		final_damage = int(prev["damage"])
		# Status effect roll
		if spell.has_status_effect():
			var applied: bool
			if rng is SeededRNG:
				applied = rng.roll_status(spell.status_chance)
			else:
				var sroll: int = rng.randi_range(1, 100)
				applied = sroll <= spell.status_chance
			if applied:
				status_applied = spell.status_effect

	return {
		"type": "offense",
		"hit": hit,
		"damage": final_damage,
		"hit_chance": prev["hit_chance"],
		"status_applied": status_applied,
		"spell_name": spell.spell_name,
		"caster_name": caster.unit_name,
		"target_name": target.unit_name,
	}
