extends PanelContainer

## Battle sub-menu for selecting spells. Shows spell name + MP cost.

signal spell_selected(spell: SpellData)
signal spell_cancelled()

const COLOR_SELECTED := Color(0.941, 0.784, 0.314, 1.0)
const COLOR_NORMAL := Color(0.8, 0.8, 0.8, 1.0)
const COLOR_DISABLED := Color(0.4, 0.4, 0.4, 1.0)

var _spells: Array = []  # Array[SpellData]
var _mp_available: int = 0
var _selected_index: int = 0
var _vbox: VBoxContainer = null
var _labels: Array[Label] = []


func _ready() -> void:
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 2)
	add_child(_vbox)

	var title := Label.new()
	title.text = "  SPELLS  "
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)

	visible = false


func show_spells(spells: Array, current_mp: int) -> void:
	_spells = spells
	_mp_available = current_mp
	_selected_index = 0

	# Clear old labels
	for lbl in _labels:
		lbl.queue_free()
	_labels.clear()

	for spell in spells:
		var lbl := Label.new()
		lbl.text = "  %s  %dMP  " % [spell.spell_name, spell.mp_cost]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_vbox.add_child(lbl)
		_labels.append(lbl)

	# Find first castable spell
	for i in _spells.size():
		if _spells[i].mp_cost <= _mp_available:
			_selected_index = i
			break

	_update_visuals()
	visible = true


func hide_menu() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("move_up"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back"):
		spell_cancelled.emit()
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	var count := _spells.size()
	if count == 0:
		return
	var next := _selected_index
	for i in count:
		next = (next + direction + count) % count
		if _spells[next].mp_cost <= _mp_available:
			break
	if _spells[next].mp_cost <= _mp_available:
		_selected_index = next
		_update_visuals()


func _confirm() -> void:
	if _selected_index < _spells.size() and _spells[_selected_index].mp_cost <= _mp_available:
		spell_selected.emit(_spells[_selected_index])


func _update_visuals() -> void:
	for i in _labels.size():
		var lbl := _labels[i]
		var can_cast: bool = _spells[i].mp_cost <= _mp_available
		if not can_cast:
			lbl.add_theme_color_override("font_color", COLOR_DISABLED)
		elif i == _selected_index:
			lbl.add_theme_color_override("font_color", COLOR_SELECTED)
		else:
			lbl.add_theme_color_override("font_color", COLOR_NORMAL)
