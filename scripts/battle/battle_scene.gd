extends Node2D

## Top-level battle scene controller.
## UIState machine wires logic (grid/pathfinder/turns/AI) to rendering and input.

enum UIState {
	BROWSING,
	UNIT_SELECTED,
	CHOOSING_MOVE,
	CHOOSING_ATTACK,
	COMBAT_PREVIEW,
	ANIMATING,
	ENEMY_TURN,
	BATTLE_OVER,
	PHASE_BANNER,
}

const TILE_SIZE := BattleGrid.TILE_SIZE

# Data layer
var grid: BattleGrid = null
var turn_mgr: TurnManager = null
var rng := RandomNumberGenerator.new()

var player_units: Array = []  # Array[UnitData]
var enemy_units: Array = []   # Array[UnitData]
var all_units: Array = []

# UI state
var ui_state: UIState = UIState.BROWSING
var selected_unit: UnitData = null
var move_target: Vector2i = Vector2i.ZERO
var attack_target: UnitData = null

# Scene nodes
@onready var camera: Camera2D = $Camera2D
@onready var grid_renderer: Node2D = $GridLayer
@onready var units_layer: Node2D = $UnitsLayer
@onready var cursor: Node2D = $Cursor
@onready var battle_hud: PanelContainer = $UILayer/BattleHUD
@onready var action_menu: PanelContainer = $UILayer/ActionMenu
@onready var combat_preview: PanelContainer = $UILayer/CombatPreview
@onready var hint_bar: Label = $UILayer/HintBar
@onready var reward_screen: CanvasLayer = $RewardScreen
@onready var phase_banner: CanvasLayer = $PhaseBanner

var _unit_renderers: Dictionary = {}  # UnitData -> Node2D
var _enemy_queue: Array = []  # Queue of enemy units to process
var _enemy_timer: float = 0.0
const ENEMY_ACTION_DELAY := 0.6


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.BATTLE)
	rng.seed = 42  # Deterministic seed for replayability

	_load_battle_data()
	_setup_grid()
	_spawn_units()
	_setup_camera()
	_connect_signals()

	# Start battle
	turn_mgr = TurnManager.new()
	turn_mgr.setup(player_units, enemy_units)
	_show_phase_banner(TurnManager.Phase.PLAYER_PHASE)


func _load_battle_data() -> void:
	# Load map
	DataDB.load_single("battle_01", "res://data/maps/battle_01.json")
	var map_data: Dictionary = DataDB.get_single("battle_01")

	# Load classes catalog
	DataDB.load_catalog("classes", "res://data/classes/classes.json")
	var classes_arr: Array = DataDB.get_catalog("classes")
	var classes_by_id: Dictionary = {}
	for c in classes_arr:
		classes_by_id[c.get("id", "")] = c

	# Build grid
	grid = BattleGrid.from_map_data(map_data)

	# Load and create player units
	DataDB.load_catalog("party", "res://data/units/party.json")
	var party_arr: Array = DataDB.get_catalog("party")
	for unit_dict in party_arr:
		var class_id: String = unit_dict.get("class", "soldier")
		var class_dict: Dictionary = classes_by_id.get(class_id, {})
		var unit := UnitData.from_data(unit_dict, class_dict)
		player_units.append(unit)
		grid.place_unit(unit, unit.grid_pos)

	# Load and create enemy units
	DataDB.load_catalog("enemies", "res://data/units/enemies.json")
	var enemies_arr: Array = DataDB.get_catalog("enemies")
	for unit_dict in enemies_arr:
		var class_id: String = unit_dict.get("class", "soldier")
		var class_dict: Dictionary = classes_by_id.get(class_id, {})
		var unit := UnitData.from_data(unit_dict, class_dict)
		enemy_units.append(unit)
		grid.place_unit(unit, unit.grid_pos)

	all_units = player_units + enemy_units


func _setup_grid() -> void:
	grid_renderer.setup(grid)


func _spawn_units() -> void:
	for unit in all_units:
		var renderer := preload("res://scripts/battle/unit_renderer.gd").new()
		renderer.setup(unit)
		units_layer.add_child(renderer)
		_unit_renderers[unit] = renderer


func _setup_camera() -> void:
	# Center camera on grid
	var grid_center := Vector2(grid.width * TILE_SIZE / 2.0, grid.height * TILE_SIZE / 2.0)
	camera.position = grid_center
	camera.zoom = Vector2(2.0, 2.0)

	# Start cursor at first player unit
	if player_units.size() > 0:
		cursor.setup(grid, player_units[0].grid_pos)
	else:
		cursor.setup(grid, Vector2i.ZERO)


func _connect_signals() -> void:
	cursor.cell_confirmed.connect(_on_cell_confirmed)
	cursor.cell_cancelled.connect(_on_cell_cancelled)
	action_menu.action_selected.connect(_on_action_selected)
	action_menu.menu_cancelled.connect(_on_action_menu_cancelled)
	combat_preview.attack_confirmed.connect(_on_attack_confirmed)
	combat_preview.attack_cancelled.connect(_on_attack_cancelled)
	reward_screen.continue_pressed.connect(_on_continue_pressed)
	phase_banner.banner_finished.connect(_on_banner_finished)


func _process(delta: float) -> void:
	# Update HUD based on cursor position
	if ui_state == UIState.BROWSING or ui_state == UIState.CHOOSING_MOVE or ui_state == UIState.CHOOSING_ATTACK:
		var unit_at_cursor = grid.get_unit_at(cursor.grid_pos)
		battle_hud.update_unit_info(unit_at_cursor)
		battle_hud.update_terrain_info(grid.get_tile(cursor.grid_pos))

	# Camera follow cursor
	if cursor.active:
		var target_pos := Vector2(cursor.grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, cursor.grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
		camera.position = camera.position.lerp(target_pos, 5.0 * delta)

	# Enemy turn processing
	if ui_state == UIState.ENEMY_TURN:
		_process_enemy_turn(delta)

	_update_hint_bar()


func _on_cell_confirmed(pos: Vector2i) -> void:
	match ui_state:
		UIState.BROWSING:
			_handle_browse_confirm(pos)
		UIState.CHOOSING_MOVE:
			_handle_move_confirm(pos)
		UIState.CHOOSING_ATTACK:
			_handle_attack_confirm(pos)


func _on_cell_cancelled() -> void:
	match ui_state:
		UIState.BROWSING:
			pass  # Nothing to cancel at top level
		UIState.UNIT_SELECTED:
			_cancel_unit_selection()
		UIState.CHOOSING_MOVE:
			_cancel_move_selection()
		UIState.CHOOSING_ATTACK:
			_cancel_attack_selection()


func _handle_browse_confirm(pos: Vector2i) -> void:
	var unit = grid.get_unit_at(pos)
	if unit == null or not (unit is UnitData):
		return
	if unit.team != UnitData.Team.PLAYER:
		return
	if unit.is_exhausted:
		return

	selected_unit = unit
	_show_action_menu()


func _show_action_menu() -> void:
	ui_state = UIState.UNIT_SELECTED
	cursor.active = false
	var items: Array[Dictionary] = []
	items.append({ "label": "MOVE", "action": "move", "enabled": not selected_unit.has_moved })
	items.append({ "label": "ATTACK", "action": "attack", "enabled": not selected_unit.has_acted })
	items.append({ "label": "WAIT", "action": "wait", "enabled": true })

	var screen_pos := Vector2(10, 10)
	action_menu.show_menu(items, screen_pos)


func _on_action_selected(action_name: String) -> void:
	action_menu.hide_menu()

	match action_name:
		"move":
			_enter_move_selection()
		"attack":
			_enter_attack_selection()
		"wait":
			_do_wait()


func _on_action_menu_cancelled() -> void:
	action_menu.hide_menu()
	_cancel_unit_selection()


func _enter_move_selection() -> void:
	ui_state = UIState.CHOOSING_MOVE
	cursor.active = true
	var move_cells := Pathfinder.get_movement_range(grid, selected_unit.grid_pos, selected_unit.mov, selected_unit.team)
	grid_renderer.set_move_highlights(move_cells)


func _handle_move_confirm(pos: Vector2i) -> void:
	var move_cells := Pathfinder.get_movement_range(grid, selected_unit.grid_pos, selected_unit.mov, selected_unit.team)
	if pos not in move_cells:
		return  # Invalid move target

	# Move the unit
	BattleActions.move_unit(grid, selected_unit, pos)
	_refresh_unit_renderer(selected_unit)
	grid_renderer.clear_highlights()

	# Show action menu again (attack/wait)
	_show_action_menu()


func _cancel_move_selection() -> void:
	grid_renderer.clear_highlights()
	_show_action_menu()


func _enter_attack_selection() -> void:
	ui_state = UIState.CHOOSING_ATTACK
	cursor.active = true
	var attack_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_unit.attack_range)
	grid_renderer.set_attack_highlights(attack_cells)


func _handle_attack_confirm(pos: Vector2i) -> void:
	var attack_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_unit.attack_range)
	if pos not in attack_cells:
		return

	var target = grid.get_unit_at(pos)
	if target == null or not (target is UnitData):
		return
	if target.team == selected_unit.team:
		return  # Can't attack allies

	attack_target = target
	grid_renderer.clear_highlights()

	# Show combat preview
	ui_state = UIState.COMBAT_PREVIEW
	cursor.active = false
	var defender_tile := grid.get_tile(target.grid_pos)
	var preview := CombatCalc.preview(selected_unit, target, defender_tile)
	combat_preview.show_preview(preview)


func _cancel_attack_selection() -> void:
	grid_renderer.clear_highlights()
	_show_action_menu()


func _on_attack_confirmed() -> void:
	combat_preview.hide_preview()
	_execute_attack(selected_unit, attack_target)

	# Check battle end
	var result := turn_mgr.check_battle_end()
	if result != TurnManager.BattleResult.NONE:
		_end_battle(result)
		return

	# Unit turn done
	selected_unit.exhaust()
	_refresh_unit_renderer(selected_unit)
	selected_unit = null
	attack_target = null

	_check_phase_end()


func _on_attack_cancelled() -> void:
	combat_preview.hide_preview()
	attack_target = null
	_enter_attack_selection()


func _execute_attack(attacker: UnitData, defender: UnitData) -> void:
	var result := BattleActions.attack(attacker, defender, grid, rng)
	GameManager.log_debug(GameManager.DEBUG_BATTLE,
		"Attack: %s -> %s | hit=%s crit=%s dmg=%d" % [
			result["attacker_name"], result["defender_name"],
			str(result["hit"]), str(result["crit"]), result["damage"]])

	# Update visual
	_refresh_unit_renderer(defender)
	if not defender.is_alive:
		_remove_unit_renderer(defender)


func _do_wait() -> void:
	BattleActions.wait(selected_unit)
	_refresh_unit_renderer(selected_unit)
	selected_unit = null

	_check_phase_end()


func _check_phase_end() -> void:
	if turn_mgr.is_phase_done():
		if turn_mgr.current_phase == TurnManager.Phase.PLAYER_PHASE:
			_show_phase_banner(TurnManager.Phase.ENEMY_PHASE)
		else:
			_show_phase_banner(TurnManager.Phase.PLAYER_PHASE)
	else:
		ui_state = UIState.BROWSING
		cursor.active = true


func _show_phase_banner(phase: TurnManager.Phase) -> void:
	ui_state = UIState.PHASE_BANNER
	cursor.active = false
	phase_banner.show_phase(phase)
	battle_hud.update_phase(phase)


func _on_banner_finished() -> void:
	if ui_state != UIState.PHASE_BANNER:
		return

	# Determine which phase to start based on what we just showed
	if turn_mgr.current_phase == TurnManager.Phase.PLAYER_PHASE and battle_hud._phase_label.text == "ENEMY PHASE":
		turn_mgr.start_enemy_phase()
		_start_enemy_turn()
	elif turn_mgr.current_phase == TurnManager.Phase.ENEMY_PHASE and battle_hud._phase_label.text == "PLAYER PHASE":
		turn_mgr.start_player_phase()
		ui_state = UIState.BROWSING
		cursor.active = true
	else:
		# First banner at battle start
		if turn_mgr.current_phase == TurnManager.Phase.PLAYER_PHASE:
			ui_state = UIState.BROWSING
			cursor.active = true
		else:
			_start_enemy_turn()


func _start_enemy_turn() -> void:
	ui_state = UIState.ENEMY_TURN
	cursor.active = false
	_enemy_queue = turn_mgr.get_active_units().duplicate()
	_enemy_timer = ENEMY_ACTION_DELAY


func _process_enemy_turn(delta: float) -> void:
	_enemy_timer -= delta
	if _enemy_timer > 0:
		return

	if _enemy_queue.is_empty():
		# All enemies done
		var result := turn_mgr.check_battle_end()
		if result != TurnManager.BattleResult.NONE:
			_end_battle(result)
			return
		_show_phase_banner(TurnManager.Phase.PLAYER_PHASE)
		return

	var enemy: UnitData = _enemy_queue.pop_front()
	if not enemy.is_alive or enemy.is_exhausted:
		return  # Skip dead/exhausted, process next immediately

	# AI decision
	var decision := AIBrain.decide(enemy, grid, player_units)

	match decision["type"]:
		"move_attack":
			var move_to: Vector2i = decision["move_to"]
			if move_to != enemy.grid_pos:
				BattleActions.move_unit(grid, enemy, move_to)
				_refresh_unit_renderer(enemy)
			var target: UnitData = decision["target"]
			if target != null and target.is_alive:
				_execute_attack(enemy, target)
				var br := turn_mgr.check_battle_end()
				if br != TurnManager.BattleResult.NONE:
					_end_battle(br)
					return
		"move":
			var move_to: Vector2i = decision["move_to"]
			if move_to != enemy.grid_pos:
				BattleActions.move_unit(grid, enemy, move_to)
				_refresh_unit_renderer(enemy)
		"wait":
			pass

	enemy.exhaust()
	_refresh_unit_renderer(enemy)
	_enemy_timer = ENEMY_ACTION_DELAY


func _end_battle(result: TurnManager.BattleResult) -> void:
	ui_state = UIState.BATTLE_OVER
	cursor.active = false
	grid_renderer.clear_highlights()
	reward_screen.show_result(result)


func _on_continue_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/main_menu.tscn")


func _refresh_unit_renderer(unit: UnitData) -> void:
	if _unit_renderers.has(unit):
		_unit_renderers[unit].refresh()


func _remove_unit_renderer(unit: UnitData) -> void:
	if _unit_renderers.has(unit):
		_unit_renderers[unit].queue_free()
		_unit_renderers.erase(unit)


func _cancel_unit_selection() -> void:
	selected_unit = null
	ui_state = UIState.BROWSING
	cursor.active = true
	grid_renderer.clear_highlights()


func _update_hint_bar() -> void:
	match ui_state:
		UIState.BROWSING:
			hint_bar.text = "[D-pad] Move  [A] Select unit"
		UIState.UNIT_SELECTED:
			hint_bar.text = "[D-pad] Choose  [A] Confirm  [B] Cancel"
		UIState.CHOOSING_MOVE:
			hint_bar.text = "[D-pad] Move cursor  [A] Move here  [B] Back"
		UIState.CHOOSING_ATTACK:
			hint_bar.text = "[D-pad] Choose target  [A] Attack  [B] Back"
		UIState.COMBAT_PREVIEW:
			hint_bar.text = "[A] Confirm attack  [B] Cancel"
		UIState.ENEMY_TURN:
			hint_bar.text = "Enemy turn..."
		UIState.BATTLE_OVER:
			hint_bar.text = "[A] Continue"
		_:
			hint_bar.text = ""
