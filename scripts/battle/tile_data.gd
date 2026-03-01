class_name BattleTile
extends RefCounted

## Tile type and property data. Pure data — no Node dependencies.

enum TileType { GRASS, FOREST, HILLS, ROAD, WATER, WALL }

# Static property tables per tile type
# Format: { move_cost, def_bonus, eva_bonus, impassable }
const TILE_PROPERTIES := {
	TileType.GRASS:  { "move_cost": 1, "def_bonus": 0, "eva_bonus": 0, "impassable": false },
	TileType.FOREST: { "move_cost": 2, "def_bonus": 2, "eva_bonus": 10, "impassable": false },
	TileType.HILLS:  { "move_cost": 3, "def_bonus": 3, "eva_bonus": 5, "impassable": false },
	TileType.ROAD:   { "move_cost": 1, "def_bonus": 0, "eva_bonus": 0, "impassable": false },
	TileType.WATER:  { "move_cost": 99, "def_bonus": 0, "eva_bonus": 0, "impassable": true },
	TileType.WALL:   { "move_cost": 99, "def_bonus": 0, "eva_bonus": 0, "impassable": true },
}

# Tile key mapping for JSON map parsing
const TILE_KEY_MAP := {
	".": TileType.GRASS,
	"F": TileType.FOREST,
	"H": TileType.HILLS,
	"R": TileType.ROAD,
	"W": TileType.WATER,
	"X": TileType.WALL,
}

var tile_type: TileType = TileType.GRASS
var move_cost: int = 1
var def_bonus: int = 0
var eva_bonus: int = 0
var impassable: bool = false


static func from_type(type: TileType) -> BattleTile:
	var td := BattleTile.new()
	td.tile_type = type
	var props: Dictionary = TILE_PROPERTIES[type]
	td.move_cost = props["move_cost"]
	td.def_bonus = props["def_bonus"]
	td.eva_bonus = props["eva_bonus"]
	td.impassable = props["impassable"]
	return td


static func from_key(key: String) -> BattleTile:
	var type: TileType = TILE_KEY_MAP.get(key, TileType.GRASS)
	return from_type(type)


static func type_name(type: TileType) -> String:
	return TileType.keys()[type]
