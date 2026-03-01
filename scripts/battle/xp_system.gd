class_name XPSystem
extends RefCounted

## Static XP/level-up methods. Deterministic — no RNG in stat growth.

const BASE_XP: int = 30
const LEVEL_DIFF_BONUS: int = 5
const MIN_XP: int = 10
const XP_TO_LEVEL: int = 100


static func calc_xp(attacker_level: int, defender_level: int) -> int:
	## Calculate XP earned for defeating an enemy.
	## +/- 5 XP per level difference, min 10.
	var diff: int = defender_level - attacker_level
	var xp: int = BASE_XP + diff * LEVEL_DIFF_BONUS
	return maxi(MIN_XP, xp)


static func check_level_up(unit: UnitData) -> bool:
	## Returns true if unit has enough XP to level up.
	return unit.xp >= XP_TO_LEVEL


static func apply_level_up(unit: UnitData) -> Dictionary:
	## Apply level up to unit. Returns stat gains dict. Empty if can't level up.
	return unit.level_up()


static func award_kill_xp(attacker: UnitData, defeated: UnitData) -> int:
	## Award XP for killing an enemy. Returns XP amount.
	var xp: int = calc_xp(attacker.level, defeated.level)
	attacker.add_xp(xp)
	return xp


static func get_level_progress(unit: UnitData) -> float:
	## Returns 0.0 - 1.0 progress toward next level.
	return minf(float(unit.xp) / float(XP_TO_LEVEL), 1.0)
