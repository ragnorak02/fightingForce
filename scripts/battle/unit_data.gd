class_name UnitData
extends RefCounted

## Unit stats and state. Pure data — no Node dependencies.

enum Team { PLAYER, ENEMY }
enum AttackType { MELEE, RANGED, MAGIC }

# Identity
var unit_name: String = ""
var unit_class: String = ""
var team: Team = Team.PLAYER
var label: String = ""  # 2-char display label

# Core stats
var hp: int = 10
var max_hp: int = 10
var mp: int = 0
var max_mp: int = 0
var atk: int = 5
var defense: int = 3
var spd: int = 5
var mov: int = 4
var attack_range: int = 1
var attack_type: AttackType = AttackType.MELEE

# Progression
var level: int = 1
var xp: int = 0

# Equipment (null = nothing equipped)
var weapon: Variant = null   # ItemData or null
var armor: Variant = null    # ItemData or null

# Inventory (4 slots, Shining Force style)
var inventory: Array = []    # Array[ItemData], max 4

# Spells
var known_spells: Array = []  # Array[SpellData]

# Status effects
var status_effects: Array = []  # Array[StatusEffect]

# Class growth data (set during from_data)
var _growth: Dictionary = {}
var _class_spells: Array = []

# Position
var grid_pos: Vector2i = Vector2i.ZERO

# Turn state
var has_moved: bool = false
var has_acted: bool = false
var is_exhausted: bool = false
var is_alive: bool = true

const MAX_INVENTORY: int = 4


static func from_data(unit_dict: Dictionary, class_dict: Dictionary) -> UnitData:
	var u := UnitData.new()

	# Class base stats
	u.max_hp = int(class_dict.get("hp", 10))
	u.max_mp = int(class_dict.get("mp", 0))
	u.atk = int(class_dict.get("atk", 5))
	u.defense = int(class_dict.get("def", 3))
	u.spd = int(class_dict.get("spd", 5))
	u.mov = int(class_dict.get("mov", 4))
	u.attack_range = int(class_dict.get("attackRange", 1))

	var at_str: String = class_dict.get("attackType", "melee")
	match at_str:
		"melee":
			u.attack_type = AttackType.MELEE
		"ranged":
			u.attack_type = AttackType.RANGED
		"magic":
			u.attack_type = AttackType.MAGIC

	# Per-unit overrides
	u.unit_name = unit_dict.get("name", "Unknown")
	u.unit_class = unit_dict.get("class", "Soldier")
	u.label = unit_dict.get("label", u.unit_name.left(2).to_upper())

	var team_str: String = unit_dict.get("team", "player")
	u.team = Team.PLAYER if team_str == "player" else Team.ENEMY

	# Stats override (additive on top of class base)
	var overrides: Dictionary = unit_dict.get("statsOverride", {})
	u.max_hp += int(overrides.get("hp", 0))
	u.max_mp += int(overrides.get("mp", 0))
	u.atk += int(overrides.get("atk", 0))
	u.defense += int(overrides.get("def", 0))
	u.spd += int(overrides.get("spd", 0))
	u.mov += int(overrides.get("mov", 0))

	u.hp = u.max_hp
	u.mp = u.max_mp

	# Level
	u.level = int(unit_dict.get("level", 1))

	# Growth and class spells
	u._growth = class_dict.get("growth", {})
	u._class_spells = class_dict.get("spells", [])

	# Populate known spells based on level
	u._update_known_spells()

	# Spawn position
	var spawn: Array = unit_dict.get("spawn", [0, 0])
	u.grid_pos = Vector2i(int(spawn[0]), int(spawn[1]))

	return u


func _update_known_spells() -> void:
	## Add any class spells the unit qualifies for by level.
	for spell_entry in _class_spells:
		if not (spell_entry is Dictionary):
			continue
		var required_level: int = int(spell_entry.get("level", 1))
		if level >= required_level:
			var spell_id: String = spell_entry.get("id", "")
			# Don't add duplicates
			var already_known := false
			for s in known_spells:
				if s.id == spell_id:
					already_known = true
					break
			if not already_known:
				# Create minimal SpellData from id — full data loaded elsewhere
				var sd := SpellData.new()
				sd.id = spell_id
				known_spells.append(sd)


func reset_turn() -> void:
	has_moved = false
	has_acted = false
	is_exhausted = false


func exhaust() -> void:
	is_exhausted = true
	has_moved = true
	has_acted = true


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp <= 0:
		is_alive = false


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	if hp > 0 and not is_alive:
		is_alive = true


# --- Effective stats (weapon/armor/status modifiers applied) ---

func get_effective_atk() -> int:
	var total: int = atk
	if weapon is ItemData:
		total += weapon.atk_bonus
	return total


func get_effective_def() -> int:
	var total: int = defense
	if armor is ItemData:
		total += armor.def_bonus
	return total


func get_effective_spd() -> int:
	var total: int = spd
	if armor is ItemData:
		total += armor.spd_bonus
	for effect in status_effects:
		total += effect.spd_modifier
	return maxi(0, total)


func get_effective_mov() -> int:
	var total: int = mov
	for effect in status_effects:
		total += effect.mov_modifier
	return maxi(1, total)


func get_effective_range() -> int:
	if weapon is ItemData and weapon.is_weapon():
		return weapon.weapon_range
	return attack_range


func get_effective_hit_bonus() -> int:
	if weapon is ItemData:
		return weapon.hit_bonus
	return 0


func get_effective_crit_bonus() -> int:
	if weapon is ItemData:
		return weapon.crit_bonus
	return 0


func get_effective_attack_type() -> AttackType:
	if weapon is ItemData and weapon.is_weapon():
		match weapon.subtype:
			"melee":
				return AttackType.MELEE
			"ranged":
				return AttackType.RANGED
			"magic":
				return AttackType.MAGIC
	return attack_type


# --- Equipment ---

func equip_weapon(item: ItemData) -> Variant:
	## Equip weapon, return previously equipped weapon (or null).
	var old: Variant = weapon
	weapon = item
	return old


func equip_armor(item: ItemData) -> Variant:
	## Equip armor, return previously equipped armor (or null).
	var old: Variant = armor
	armor = item
	return old


# --- Inventory (4 slots) ---

func add_to_inventory(item: ItemData) -> bool:
	## Add item to unit inventory. Returns false if full.
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(item)
	return true


func remove_from_inventory(item: ItemData) -> bool:
	## Remove item from unit inventory. Returns false if not found.
	var idx: int = inventory.find(item)
	if idx < 0:
		return false
	inventory.remove_at(idx)
	return true


func remove_inventory_at(index: int) -> Variant:
	## Remove and return item at index. Returns null if out of bounds.
	if index < 0 or index >= inventory.size():
		return null
	var item: ItemData = inventory[index]
	inventory.remove_at(index)
	return item


func get_usable_items() -> Array:
	## Return inventory items usable in battle (consumables).
	var result: Array = []
	for item in inventory:
		if item.is_usable_in_battle():
			result.append(item)
	return result


func inventory_full() -> bool:
	return inventory.size() >= MAX_INVENTORY


# --- Status Effects ---

func add_status(effect: StatusEffect) -> void:
	## Add status effect. Doesn't stack same type — refreshes instead.
	for i in status_effects.size():
		if status_effects[i].effect_type == effect.effect_type:
			status_effects[i] = effect
			return
	status_effects.append(effect)


func has_status(effect_type: StatusEffect.Type) -> bool:
	for e in status_effects:
		if e.effect_type == effect_type:
			return true
	return false


func tick_status_effects() -> Array:
	## Tick all status effects. Returns array of { "type": String, "damage": int, "expired": bool }.
	var results: Array = []
	var to_remove: Array = []
	for i in status_effects.size():
		var effect: StatusEffect = status_effects[i]
		var tick_result := effect.tick()
		results.append({
			"type": effect.get_type_name(),
			"damage": tick_result["damage"],
			"expired": tick_result["expired"],
		})
		if tick_result["damage"] > 0:
			take_damage(tick_result["damage"])
		if tick_result["expired"]:
			to_remove.append(i)

	# Remove expired (reverse order)
	to_remove.reverse()
	for idx in to_remove:
		status_effects.remove_at(idx)

	return results


func clear_status(effect_type: StatusEffect.Type) -> void:
	for i in range(status_effects.size() - 1, -1, -1):
		if status_effects[i].effect_type == effect_type:
			status_effects.remove_at(i)


func clear_all_status() -> void:
	status_effects.clear()


# --- XP & Leveling ---

func add_xp(amount: int) -> void:
	xp += amount


func can_level_up() -> bool:
	return xp >= 100


func level_up() -> Dictionary:
	## Perform level up. Returns stat gains dict. Deducts 100 XP.
	if not can_level_up():
		return {}

	xp -= 100
	level += 1

	var gains: Dictionary = {
		"hp": int(_growth.get("hp", 2)),
		"mp": int(_growth.get("mp", 0)),
		"atk": int(_growth.get("atk", 1)),
		"def": int(_growth.get("def", 1)),
		"spd": int(_growth.get("spd", 1)),
	}

	max_hp += gains["hp"]
	hp += gains["hp"]
	max_mp += gains["mp"]
	mp += gains["mp"]
	atk += gains["atk"]
	defense += gains["def"]
	spd += gains["spd"]

	# Check for new spells
	_update_known_spells()

	return gains
