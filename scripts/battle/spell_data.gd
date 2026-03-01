class_name SpellData
extends RefCounted

## Wraps spell JSON with typed accessors.

var id: String = ""
var spell_name: String = ""
var type: String = "offense"     # "offense" or "support"
var element: String = ""
var mp_cost: int = 0
var power: int = 0
var hit_chance: int = 90
var spell_range: int = 2
var status_effect: String = ""   # "" = none, "poison", "slow"
var status_chance: int = 0
var description: String = ""


static func from_dict(d: Dictionary) -> SpellData:
	var s := SpellData.new()
	s.id = d.get("id", "")
	s.spell_name = d.get("name", "Unknown")
	s.type = d.get("type", "offense")
	s.element = d.get("element", "")
	s.mp_cost = int(d.get("mpCost", 0))
	s.power = int(d.get("power", 0))
	s.hit_chance = int(d.get("hit", 90))
	s.spell_range = int(d.get("range", 2))

	var se = d.get("statusEffect", null)
	s.status_effect = se if se is String else ""
	s.status_chance = int(d.get("statusChance", 0))
	s.description = d.get("description", "")
	return s


func is_offensive() -> bool:
	return type == "offense"


func is_support() -> bool:
	return type == "support"


func has_status_effect() -> bool:
	return status_effect != "" and status_chance > 0
