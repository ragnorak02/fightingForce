extends Node2D

## Per-unit visual: colored rect + 2-char label + HP bar.

const TILE_SIZE := BattleGrid.TILE_SIZE
const UNIT_MARGIN := 4
const HP_BAR_HEIGHT := 3

const PLAYER_COLOR := Color(0.25, 0.40, 0.85)
const ENEMY_COLOR := Color(0.80, 0.20, 0.20)
const EXHAUSTED_ALPHA := 0.45
const LABEL_COLOR := Color.WHITE
const HP_BG_COLOR := Color(0.15, 0.15, 0.15)
const HP_GREEN := Color(0.2, 0.8, 0.2)
const HP_YELLOW := Color(0.9, 0.8, 0.1)
const HP_RED := Color(0.9, 0.2, 0.2)

var unit: UnitData = null


func setup(unit_data: UnitData) -> void:
	unit = unit_data
	_update_position()


func refresh() -> void:
	_update_position()
	queue_redraw()


func _update_position() -> void:
	if unit:
		position = Vector2(unit.grid_pos.x * TILE_SIZE, unit.grid_pos.y * TILE_SIZE)


func _draw() -> void:
	if unit == null or not unit.is_alive:
		return

	var base_color: Color = PLAYER_COLOR if unit.team == UnitData.Team.PLAYER else ENEMY_COLOR
	if unit.is_exhausted:
		base_color.a = EXHAUSTED_ALPHA

	# Unit body
	var body_rect := Rect2(UNIT_MARGIN, UNIT_MARGIN, TILE_SIZE - UNIT_MARGIN * 2, TILE_SIZE - UNIT_MARGIN * 2 - HP_BAR_HEIGHT - 2)
	draw_rect(body_rect, base_color)

	# Label
	var font := ThemeDB.fallback_font
	var font_size := 10
	var text_pos := Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0 - 2)
	var text_size := font.get_string_size(unit.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(text_pos.x - text_size.x / 2.0, text_pos.y + text_size.y / 4.0), unit.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_COLOR)

	# HP bar background
	var hp_y := TILE_SIZE - UNIT_MARGIN - HP_BAR_HEIGHT
	var hp_rect := Rect2(UNIT_MARGIN, hp_y, TILE_SIZE - UNIT_MARGIN * 2, HP_BAR_HEIGHT)
	draw_rect(hp_rect, HP_BG_COLOR)

	# HP bar fill
	var hp_ratio := float(unit.hp) / float(unit.max_hp) if unit.max_hp > 0 else 0.0
	var hp_color: Color
	if hp_ratio > 0.5:
		hp_color = HP_GREEN
	elif hp_ratio > 0.25:
		hp_color = HP_YELLOW
	else:
		hp_color = HP_RED
	var fill_rect := Rect2(UNIT_MARGIN, hp_y, (TILE_SIZE - UNIT_MARGIN * 2) * hp_ratio, HP_BAR_HEIGHT)
	draw_rect(fill_rect, hp_color)
