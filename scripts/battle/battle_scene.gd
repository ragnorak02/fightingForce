extends Node2D

## Top-level battle scene controller.
## UIState machine wires logic (grid/pathfinder/turns/AI) to rendering and input.

enum UIState {
	BROWSING,
	UNIT_SELECTED,
	CHOOSING_MOVE,
	CHOOSING_ATTACK,
	COMBAT_PREVIEW,
	CHOOSING_SPELL,
	SPELL_TARGET,
	SPELL_PREVIEW,
	CHOOSING_ITEM,
	ITEM_TARGET,
	ANIMATING,
	ENEMY_TURN,
	BATTLE_OVER,
	PHASE_BANNER,
}

const TILE_SIZE := BattleGrid.TILE_SIZE

# Data layer
var grid: BattleGrid = null
var turn_mgr: TurnManager = null
var rng := SeededRNG.new()

var player_units: Array = []  # Array[UnitData]
var enemy_units: Array = []   # Array[UnitData]
var all_units: Array = []

# Spell catalog (loaded from JSON for full data)
var _spell_catalog: Dictionary = {}  # id -> SpellData
var _item_catalog: Dictionary = {}   # id -> Dictionary (raw JSON)

# UI state
var ui_state: UIState = UIState.BROWSING
var selected_unit: UnitData = null
var move_target: Vector2i = Vector2i.ZERO
var attack_target: UnitData = null
var selected_spell: SpellData = null
var selected_item: ItemData = null

# Scene nodes
@onready var camera: Camera2D = $Camera2D
@onready var grid_renderer: Node2D = $GridLayer
@onready var units_layer: Node2D = $UnitsLayer
@onready var cursor: Node2D = $Cursor
@onready var battle_hud: PanelContainer = $UILayer/BattleHUD
@onready var action_menu: PanelContainer = $UILayer/ActionMenu
@onready var combat_preview: PanelContainer = $UILayer/CombatPreview
@onready var spell_menu: PanelContainer = $UILayer/SpellMenu
@onready var item_menu: PanelContainer = $UILayer/ItemMenu
@onready var hint_bar: Label = $UILayer/HintBar
@onready var reward_screen: CanvasLayer = $RewardScreen
@onready var phase_banner: CanvasLayer = $PhaseBanner

var _unit_renderers: Dictionary = {}  # UnitData -> Node2D
var _enemy_queue: Array = []  # Queue of enemy units to process
var _enemy_timer: float = 0.0
const ENEMY_ACTION_DELAY := 0.6

# XP tracking for reward screen
var _battle_xp: Dictionary = {}  # UnitData -> total XP earned
var _level_ups: Array = []       # Array of { "unit": UnitData, "gains": Dictionary }


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.BATTLE)
	rng.setup(42)  # Deterministic seed for replayability

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

	# Load spell catalog
	DataDB.load_catalog("spells", "res://data/skills/spells.json")
	var spells_arr: Array = DataDB.get_catalog("spells")
	for s in spells_arr:
		var spell := SpellData.from_dict(s)
		_spell_catalog[spell.id] = spell

	# Load weapon/consumable catalogs for item lookup
	DataDB.load_catalog("weapons", "res://data/items/weapons.json")
	var weapons_arr: Array = DataDB.get_catalog("weapons")
	for w in weapons_arr:
		_item_catalog[w.get("id", "")] = w

	DataDB.load_catalog("consumables", "res://data/items/consumables.json")
	var cons_arr: Array = DataDB.get_catalog("consumables")
	for c in cons_arr:
		_item_catalog[c.get("id", "")] = c

	DataDB.load_catalog("armor_catalog", "res://data/items/armor.json")
	var armor_arr: Array = DataDB.get_catalog("armor_catalog")
	for a in armor_arr:
		_item_catalog[a.get("id", "")] = a

	# Build grid
	grid = BattleGrid.from_map_data(map_data)

	# Load and create player units
	DataDB.load_catalog("party", "res://data/units/party.json")
	var party_arr: Array = DataDB.get_catalog("party")
	for unit_dict in party_arr:
		var class_id: String = unit_dict.get("class", "soldier")
		var class_dict: Dictionary = classes_by_id.get(class_id, {})
		var unit := UnitData.from_data(unit_dict, class_dict)
		_equip_defaults(unit, class_dict)
		_resolve_unit_spells(unit)
		player_units.append(unit)
		grid.place_unit(unit, unit.grid_pos)

	# Load and create enemy units
	DataDB.load_catalog("enemies", "res://data/units/enemies.json")
	var enemies_arr: Array = DataDB.get_catalog("enemies")
	for unit_dict in enemies_arr:
		var class_id: String = unit_dict.get("class", "soldier")
		var class_dict: Dictionary = classes_by_id.get(class_id, {})
		var unit := UnitData.from_data(unit_dict, class_dict)
		_equip_defaults(unit, class_dict)
		enemy_units.append(unit)
		grid.place_unit(unit, unit.grid_pos)

	all_units = player_units + enemy_units


func _equip_defaults(unit: UnitData, class_dict: Dictionary) -> void:
	## Equip default weapon/armor from class definition.
	var weapon_id: String = class_dict.get("defaultWeapon", "")
	if weapon_id != "" and _item_catalog.has(weapon_id):
		unit.equip_weapon(ItemData.from_dict(_item_catalog[weapon_id]))

	var armor_id: String = class_dict.get("defaultArmor", "")
	if armor_id != "" and _item_catalog.has(armor_id):
		unit.equip_armor(ItemData.from_dict(_item_catalog[armor_id]))


func _resolve_unit_spells(unit: UnitData) -> void:
	## Replace stub SpellData with full catalog entries.
	for i in unit.known_spells.size():
		var stub: SpellData = unit.known_spells[i]
		if _spell_catalog.has(stub.id):
			unit.known_spells[i] = _spell_catalog[stub.id]


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
	spell_menu.spell_selected.connect(_on_spell_selected)
	spell_menu.spell_cancelled.connect(_on_spell_cancelled)
	item_menu.item_selected.connect(_on_item_selected)
	item_menu.item_cancelled.connect(_on_item_cancelled)
	reward_screen.continue_pressed.connect(_on_continue_pressed)
	phase_banner.banner_finished.connect(_on_banner_finished)


func _process(delta: float) -> void:
	# Update HUD based on cursor position
	if ui_state == UIState.BROWSING or ui_state == UIState.CHOOSING_MOVE or ui_state == UIState.CHOOSING_ATTACK or ui_state == UIState.SPELL_TARGET or ui_state == UIState.ITEM_TARGET:
		var unit_at_cursor: Variant = grid.get_unit_at(cursor.grid_pos)
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
		UIState.SPELL_TARGET:
			_handle_spell_target_confirm(pos)
		UIState.ITEM_TARGET:
			_handle_item_target_confirm(pos)


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
		UIState.SPELL_TARGET:
			_cancel_spell_target()
		UIState.ITEM_TARGET:
			_cancel_item_target()


func _handle_browse_confirm(pos: Vector2i) -> void:
	var unit: Variant = grid.get_unit_at(pos)
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

	# CAST enabled if unit has spells and MP
	var has_spells: bool = selected_unit.known_spells.size() > 0
	var has_mp: bool = selected_unit.mp > 0
	items.append({ "label": "CAST", "action": "cast", "enabled": not selected_unit.has_acted and has_spells and has_mp })

	# ITEM enabled if unit has usable items
	var usable: Array = selected_unit.get_usable_items()
	items.append({ "label": "ITEM", "action": "item", "enabled": not selected_unit.has_acted and usable.size() > 0 })

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
		"cast":
			_enter_spell_selection()
		"item":
			_enter_item_selection()
		"wait":
			_do_wait()


func _on_action_menu_cancelled() -> void:
	action_menu.hide_menu()
	_cancel_unit_selection()


func _enter_move_selection() -> void:
	ui_state = UIState.CHOOSING_MOVE
	cursor.active = true
	var move_cells := Pathfinder.get_movement_range(grid, selected_unit.grid_pos, selected_unit.get_effective_mov(), selected_unit.team)
	grid_renderer.set_move_highlights(move_cells)


func _handle_move_confirm(pos: Vector2i) -> void:
	var move_cells := Pathfinder.get_movement_range(grid, selected_unit.grid_pos, selected_unit.get_effective_mov(), selected_unit.team)
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
	var attack_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_unit.get_effective_range())
	grid_renderer.set_attack_highlights(attack_cells)


func _handle_attack_confirm(pos: Vector2i) -> void:
	var attack_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_unit.get_effective_range())
	if pos not in attack_cells:
		return

	var target: Variant = grid.get_unit_at(pos)
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
	if ui_state == UIState.SPELL_PREVIEW:
		_on_spell_preview_confirmed()
		return

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
	if ui_state == UIState.SPELL_PREVIEW:
		combat_preview.hide_preview()
		attack_target = null
		_enter_spell_target_selection()
		return

	combat_preview.hide_preview()
	attack_target = null
	_enter_attack_selection()


# --- Spell flow ---

func _enter_spell_selection() -> void:
	ui_state = UIState.CHOOSING_SPELL
	spell_menu.show_spells(selected_unit.known_spells, selected_unit.mp)


func _on_spell_selected(spell: SpellData) -> void:
	selected_spell = spell
	spell_menu.hide_menu()
	_enter_spell_target_selection()


func _on_spell_cancelled() -> void:
	spell_menu.hide_menu()
	selected_spell = null
	_show_action_menu()


func _enter_spell_target_selection() -> void:
	ui_state = UIState.SPELL_TARGET
	cursor.active = true
	var range_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_spell.spell_range)
	grid_renderer.set_attack_highlights(range_cells)


func _handle_spell_target_confirm(pos: Vector2i) -> void:
	var range_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, selected_spell.spell_range)
	if pos not in range_cells:
		return

	var target: Variant = grid.get_unit_at(pos)
	if target == null or not (target is UnitData):
		return

	# Support spells target allies; offense targets enemies
	if selected_spell.is_support() and target.team != selected_unit.team:
		return
	if selected_spell.is_offensive() and target.team == selected_unit.team:
		return

	attack_target = target
	grid_renderer.clear_highlights()

	# Show spell preview
	ui_state = UIState.SPELL_PREVIEW
	cursor.active = false
	var target_tile := grid.get_tile(target.grid_pos)
	var preview := CombatCalc.preview_spell(selected_unit, target, selected_spell, target_tile)
	combat_preview.show_spell_preview(preview)


func _cancel_spell_target() -> void:
	grid_renderer.clear_highlights()
	selected_spell = null
	_show_action_menu()


# Spell preview reuses combat_preview confirm/cancel via a flag
func _on_spell_preview_confirmed() -> void:
	combat_preview.hide_preview()
	_execute_spell(selected_unit, attack_target, selected_spell)

	var result := turn_mgr.check_battle_end()
	if result != TurnManager.BattleResult.NONE:
		_end_battle(result)
		return

	selected_unit.exhaust()
	_refresh_unit_renderer(selected_unit)
	selected_unit = null
	attack_target = null
	selected_spell = null

	_check_phase_end()


# --- Item flow ---

func _enter_item_selection() -> void:
	ui_state = UIState.CHOOSING_ITEM
	item_menu.show_items(selected_unit.get_usable_items())


func _on_item_selected(item: ItemData) -> void:
	selected_item = item
	item_menu.hide_menu()
	_enter_item_target_selection()


func _on_item_cancelled() -> void:
	item_menu.hide_menu()
	selected_item = null
	_show_action_menu()


func _enter_item_target_selection() -> void:
	ui_state = UIState.ITEM_TARGET
	cursor.active = true
	# Items target self or adjacent allies (range 1)
	var range_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, 1)
	range_cells.append(selected_unit.grid_pos)
	grid_renderer.set_move_highlights(range_cells)


func _handle_item_target_confirm(pos: Vector2i) -> void:
	var range_cells := Pathfinder.get_attack_range(grid, selected_unit.grid_pos, 1)
	range_cells.append(selected_unit.grid_pos)
	if pos not in range_cells:
		return

	var target: Variant = grid.get_unit_at(pos)
	if target == null or not (target is UnitData):
		return
	if target.team != selected_unit.team:
		return  # Items only on allies

	grid_renderer.clear_highlights()
	_execute_item(selected_unit, target, selected_item)

	selected_unit.exhaust()
	_refresh_unit_renderer(selected_unit)
	_refresh_unit_renderer(target)
	selected_unit = null
	selected_item = null

	_check_phase_end()


func _cancel_item_target() -> void:
	grid_renderer.clear_highlights()
	selected_item = null
	_show_action_menu()


# --- Execution ---

func _execute_attack(attacker: UnitData, defender: UnitData) -> void:
	var result := BattleActions.attack(attacker, defender, grid, rng.get_raw_rng())
	GameManager.log_debug(GameManager.DEBUG_BATTLE,
		"Attack: %s -> %s | hit=%s crit=%s dmg=%d" % [
			result["attacker_name"], result["defender_name"],
			str(result["hit"]), str(result["crit"]), result["damage"]])

	# XP on kill
	if result["hit"] and not defender.is_alive and attacker.team == UnitData.Team.PLAYER:
		var xp: int = XPSystem.award_kill_xp(attacker, defender)
		_battle_xp[attacker] = _battle_xp.get(attacker, 0) + xp

	# Update visual
	_refresh_unit_renderer(defender)
	if not defender.is_alive:
		_remove_unit_renderer(defender)


func _execute_spell(caster: UnitData, target: UnitData, spell: SpellData) -> void:
	var result := BattleActions.cast_spell(caster, target, spell, grid, rng.get_raw_rng())
	GameManager.log_debug(GameManager.DEBUG_BATTLE,
		"Spell: %s casts %s on %s | hit=%s dmg/heal=%s" % [
			result.get("caster_name", ""),
			result.get("spell_name", ""),
			result.get("target_name", ""),
			str(result.get("hit", true)),
			str(result.get("damage", result.get("heal_amount", 0)))])

	# XP on kill (offense spells)
	if result.get("hit", false) and not target.is_alive and caster.team == UnitData.Team.PLAYER:
		var xp: int = XPSystem.award_kill_xp(caster, target)
		_battle_xp[caster] = _battle_xp.get(caster, 0) + xp

	_refresh_unit_renderer(target)
	if not target.is_alive:
		_remove_unit_renderer(target)


func _execute_item(user: UnitData, target: UnitData, item: ItemData) -> void:
	var result := BattleActions.use_item(user, target, item)
	GameManager.log_debug(GameManager.DEBUG_BATTLE,
		"Item: %s uses %s on %s" % [
			result.get("user_name", ""),
			result.get("item_name", ""),
			result.get("target_name", "")])


func _do_wait() -> void:
	BattleActions.wait(selected_unit)
	_refresh_unit_renderer(selected_unit)
	selected_unit = null

	_check_phase_end()


func _tick_phase_status_effects() -> void:
	## Tick status effects for all units at phase start.
	for unit in all_units:
		if not unit.is_alive:
			continue
		if unit.status_effects.size() == 0:
			continue
		var results: Array = unit.tick_status_effects()
		for r in results:
			if r["damage"] > 0:
				GameManager.log_debug(GameManager.DEBUG_BATTLE,
					"%s takes %d %s damage" % [unit.unit_name, r["damage"], r["type"]])
		_refresh_unit_renderer(unit)
		if not unit.is_alive:
			_remove_unit_renderer(unit)
			grid.remove_unit_at(unit.grid_pos)


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
		_tick_phase_status_effects()
		_start_enemy_turn()
	elif turn_mgr.current_phase == TurnManager.Phase.ENEMY_PHASE and battle_hud._phase_label.text == "PLAYER PHASE":
		turn_mgr.start_player_phase()
		_tick_phase_status_effects()
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

	# Process level-ups
	if result == TurnManager.BattleResult.VICTORY:
		for unit in player_units:
			if unit.is_alive:
				while unit.can_level_up():
					var gains: Dictionary = unit.level_up()
					if gains.size() > 0:
						_level_ups.append({ "unit_name": unit.unit_name, "level": unit.level, "gains": gains })

	reward_screen.show_result(result, _battle_xp, _level_ups)


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
		UIState.COMBAT_PREVIEW, UIState.SPELL_PREVIEW:
			hint_bar.text = "[A] Confirm  [B] Cancel"
		UIState.CHOOSING_SPELL:
			hint_bar.text = "[D-pad] Choose spell  [A] Select  [B] Back"
		UIState.SPELL_TARGET:
			hint_bar.text = "[D-pad] Choose target  [A] Cast  [B] Back"
		UIState.CHOOSING_ITEM:
			hint_bar.text = "[D-pad] Choose item  [A] Select  [B] Back"
		UIState.ITEM_TARGET:
			hint_bar.text = "[D-pad] Choose target  [A] Use  [B] Back"
		UIState.ENEMY_TURN:
			hint_bar.text = "Enemy turn..."
		UIState.BATTLE_OVER:
			hint_bar.text = "[A] Continue"
		_:
			hint_bar.text = ""
