extends Node2D

## Grid cursor — gold outline rect, controller/keyboard driven with repeat timing.

const TILE_SIZE := BattleGrid.TILE_SIZE
const CURSOR_COLOR := Color(0.941, 0.784, 0.314, 1.0)
const CURSOR_WIDTH := 2.0

const INITIAL_DELAY := 0.25
const REPEAT_RATE := 0.08

signal cell_confirmed(pos: Vector2i)
signal cell_cancelled()

var grid_pos: Vector2i = Vector2i.ZERO
var grid: BattleGrid = null
var active: bool = true

var _move_timers: Dictionary = {}  # action_name -> float
var _move_held: Dictionary = {}    # action_name -> bool


func setup(grid_data: BattleGrid, start_pos: Vector2i) -> void:
	grid = grid_data
	grid_pos = start_pos
	_update_position()


func _update_position() -> void:
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)


func _process(delta: float) -> void:
	if not active or grid == null:
		return

	_handle_direction("move_up", Vector2i.UP, delta)
	_handle_direction("move_down", Vector2i.DOWN, delta)
	_handle_direction("move_left", Vector2i.LEFT, delta)
	_handle_direction("move_right", Vector2i.RIGHT, delta)


func _unhandled_input(event: InputEvent) -> void:
	if not active or grid == null:
		return

	if event.is_action_pressed("confirm"):
		cell_confirmed.emit(grid_pos)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back"):
		cell_cancelled.emit()
		get_viewport().set_input_as_handled()


func _handle_direction(action: String, dir: Vector2i, delta: float) -> void:
	if Input.is_action_pressed(action):
		if not _move_held.get(action, false):
			# First press
			_move_held[action] = true
			_move_timers[action] = INITIAL_DELAY
			_try_move(dir)
		else:
			_move_timers[action] -= delta
			if _move_timers[action] <= 0:
				_move_timers[action] = REPEAT_RATE
				_try_move(dir)
	else:
		_move_held[action] = false
		_move_timers[action] = 0.0


func _try_move(dir: Vector2i) -> void:
	var new_pos := grid_pos + dir
	if grid.is_in_bounds(new_pos):
		grid_pos = new_pos
		_update_position()
		queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	# Gold outline
	var rect := Rect2(0, 0, TILE_SIZE, TILE_SIZE)
	draw_rect(rect, CURSOR_COLOR, false, CURSOR_WIDTH)
