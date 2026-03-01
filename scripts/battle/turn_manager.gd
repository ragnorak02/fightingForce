class_name TurnManager
extends RefCounted

## Phase-based turn manager (Shining Force style: player phase ↔ enemy phase).

enum Phase { PLAYER_PHASE, ENEMY_PHASE }
enum BattleResult { NONE, VICTORY, DEFEAT }

var current_phase: Phase = Phase.PLAYER_PHASE
var battle_result: BattleResult = BattleResult.NONE

var _player_units: Array = []  # Array[UnitData]
var _enemy_units: Array = []   # Array[UnitData]

# Signals emulated via callbacks (RefCounted can't use signals)
var on_phase_changed: Callable = Callable()
var on_battle_ended: Callable = Callable()


func setup(player_units: Array, enemy_units: Array) -> void:
	_player_units = player_units
	_enemy_units = enemy_units
	current_phase = Phase.PLAYER_PHASE
	battle_result = BattleResult.NONE
	_reset_units(_player_units)


func start_player_phase() -> void:
	current_phase = Phase.PLAYER_PHASE
	_reset_units(_player_units)
	if on_phase_changed.is_valid():
		on_phase_changed.call(current_phase)


func start_enemy_phase() -> void:
	current_phase = Phase.ENEMY_PHASE
	_reset_units(_enemy_units)
	if on_phase_changed.is_valid():
		on_phase_changed.call(current_phase)


func is_phase_done() -> bool:
	var units: Array = _player_units if current_phase == Phase.PLAYER_PHASE else _enemy_units
	for unit in units:
		if unit is UnitData and unit.is_alive and not unit.is_exhausted:
			return false
	return true


func get_active_units() -> Array:
	var units: Array = _player_units if current_phase == Phase.PLAYER_PHASE else _enemy_units
	var result: Array = []
	for unit in units:
		if unit is UnitData and unit.is_alive and not unit.is_exhausted:
			result.append(unit)
	return result


func check_battle_end() -> BattleResult:
	var players_alive := false
	for unit in _player_units:
		if unit is UnitData and unit.is_alive:
			players_alive = true
			break

	var enemies_alive := false
	for unit in _enemy_units:
		if unit is UnitData and unit.is_alive:
			enemies_alive = true
			break

	if not enemies_alive:
		battle_result = BattleResult.VICTORY
	elif not players_alive:
		battle_result = BattleResult.DEFEAT
	else:
		battle_result = BattleResult.NONE

	if battle_result != BattleResult.NONE and on_battle_ended.is_valid():
		on_battle_ended.call(battle_result)

	return battle_result


func end_current_phase() -> void:
	## Called when all units in current phase are done. Starts the next phase.
	if current_phase == Phase.PLAYER_PHASE:
		start_enemy_phase()
	else:
		start_player_phase()


func _reset_units(units: Array) -> void:
	for unit in units:
		if unit is UnitData and unit.is_alive:
			unit.reset_turn()
