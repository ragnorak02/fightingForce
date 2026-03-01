extends Node2D

## Draws the tactical grid: colored rects per tile, highlight overlays.

const TILE_SIZE := BattleGrid.TILE_SIZE

const TILE_COLORS := {
	BattleTile.TileType.GRASS:  Color(0.18, 0.42, 0.18),
	BattleTile.TileType.FOREST: Color(0.12, 0.32, 0.12),
	BattleTile.TileType.HILLS:  Color(0.38, 0.35, 0.18),
	BattleTile.TileType.ROAD:   Color(0.45, 0.40, 0.28),
	BattleTile.TileType.WATER:  Color(0.15, 0.25, 0.50),
	BattleTile.TileType.WALL:   Color(0.25, 0.22, 0.22),
}

const GRID_LINE_COLOR := Color(0.15, 0.15, 0.25, 0.3)

var grid: BattleGrid = null
var move_highlights: Array[Vector2i] = []
var attack_highlights: Array[Vector2i] = []

const MOVE_HIGHLIGHT_COLOR := Color(0.2, 0.4, 0.9, 0.35)
const ATTACK_HIGHLIGHT_COLOR := Color(0.9, 0.2, 0.2, 0.35)


func setup(grid_data: BattleGrid) -> void:
	grid = grid_data
	queue_redraw()


func set_move_highlights(cells: Array[Vector2i]) -> void:
	move_highlights = cells
	queue_redraw()


func set_attack_highlights(cells: Array[Vector2i]) -> void:
	attack_highlights = cells
	queue_redraw()


func clear_highlights() -> void:
	move_highlights = []
	attack_highlights = []
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return

	# Draw tiles
	for y in grid.height:
		for x in grid.width:
			var tile: BattleTile = grid.tiles[y][x]
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var color: Color = TILE_COLORS.get(tile.tile_type, Color.DARK_GREEN)
			draw_rect(rect, color)

	# Draw grid lines
	for y in range(grid.height + 1):
		draw_line(Vector2(0, y * TILE_SIZE), Vector2(grid.width * TILE_SIZE, y * TILE_SIZE), GRID_LINE_COLOR)
	for x in range(grid.width + 1):
		draw_line(Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, grid.height * TILE_SIZE), GRID_LINE_COLOR)

	# Draw move highlights
	for pos in move_highlights:
		var rect := Rect2(pos.x * TILE_SIZE, pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		draw_rect(rect, MOVE_HIGHLIGHT_COLOR)

	# Draw attack highlights
	for pos in attack_highlights:
		var rect := Rect2(pos.x * TILE_SIZE, pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		draw_rect(rect, ATTACK_HIGHLIGHT_COLOR)
