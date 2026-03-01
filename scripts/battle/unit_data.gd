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

# Position
var grid_pos: Vector2i = Vector2i.ZERO

# Turn state
var has_moved: bool = false
var has_acted: bool = false
var is_exhausted: bool = false
var is_alive: bool = true


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

	# Spawn position
	var spawn: Array = unit_dict.get("spawn", [0, 0])
	u.grid_pos = Vector2i(int(spawn[0]), int(spawn[1]))

	return u


func reset_turn() -> void:
	has_moved = false
	has_acted = false
	is_exhausted = false


func exhaust() -> void:
	is_exhausted = true
	has_moved = true
	has_acted = true


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp <= 0:
		is_alive = false


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
