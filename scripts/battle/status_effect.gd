class_name StatusEffect
extends RefCounted

## Active status effect on a unit. tick() returns damage + expired flag.

enum Type { POISON, SLOW }

var effect_type: Type = Type.POISON
var turns_remaining: int = 3
var damage_per_turn: int = 0
var spd_modifier: int = 0
var mov_modifier: int = 0


static func create_poison() -> StatusEffect:
	var e := StatusEffect.new()
	e.effect_type = Type.POISON
	e.turns_remaining = 3
	e.damage_per_turn = 3
	return e


static func create_slow() -> StatusEffect:
	var e := StatusEffect.new()
	e.effect_type = Type.SLOW
	e.turns_remaining = 2
	e.spd_modifier = -3
	e.mov_modifier = -1
	return e


static func from_name(effect_name: String) -> StatusEffect:
	match effect_name:
		"poison":
			return create_poison()
		"slow":
			return create_slow()
	return null


func tick() -> Dictionary:
	## Called at phase start. Returns { "damage": int, "expired": bool }.
	turns_remaining -= 1
	var result: Dictionary = {
		"damage": damage_per_turn,
		"expired": turns_remaining <= 0,
	}
	return result


func get_type_name() -> String:
	match effect_type:
		Type.POISON:
			return "Poison"
		Type.SLOW:
			return "Slow"
	return "Unknown"
