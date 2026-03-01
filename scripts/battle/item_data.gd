class_name ItemData
extends RefCounted

## Wraps weapon/armor/consumable JSON with typed accessors.

var id: String = ""
var item_name: String = ""
var type: String = ""          # "weapon", "armor", "consumable"
var subtype: String = ""       # weapon: "melee"/"ranged"/"magic"
var description: String = ""
var price: int = 0

# Weapon stats
var atk_bonus: int = 0
var hit_bonus: int = 0
var crit_bonus: int = 0
var weapon_range: int = 1

# Armor stats
var def_bonus: int = 0
var spd_bonus: int = 0

# Consumable stats
var effect: String = ""        # "heal", "cure_poison", "revive"
var power: int = 0


static func from_dict(d: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = d.get("id", "")
	item.item_name = d.get("name", "Unknown")
	item.type = d.get("type", "consumable")
	item.subtype = d.get("subtype", "")
	item.description = d.get("description", "")
	item.price = int(d.get("price", 0))

	# Weapon fields
	item.atk_bonus = int(d.get("atk", 0))
	item.hit_bonus = int(d.get("hit", 0))
	item.crit_bonus = int(d.get("crit", 0))
	item.weapon_range = int(d.get("range", 1))

	# Armor fields
	item.def_bonus = int(d.get("def", 0))
	item.spd_bonus = int(d.get("spd", 0))

	# Consumable fields
	item.effect = d.get("effect", "")
	item.power = int(d.get("power", 0))

	return item


func is_weapon() -> bool:
	return type == "weapon"


func is_armor() -> bool:
	return type == "armor"


func is_consumable() -> bool:
	return type == "consumable"


func is_usable_in_battle() -> bool:
	return is_consumable()


func to_dict() -> Dictionary:
	var d: Dictionary = {
		"id": id,
		"name": item_name,
		"type": type,
	}
	if is_weapon():
		d["subtype"] = subtype
		d["atk"] = atk_bonus
		d["hit"] = hit_bonus
		d["crit"] = crit_bonus
		d["range"] = weapon_range
	elif is_armor():
		d["def"] = def_bonus
		d["spd"] = spd_bonus
	elif is_consumable():
		d["effect"] = effect
		d["power"] = power
	d["price"] = price
	d["description"] = description
	return d
