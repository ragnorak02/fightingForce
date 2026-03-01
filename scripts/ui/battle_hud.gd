extends PanelContainer

## Bottom HUD panel: selected unit info + terrain info + phase indicator.

var _unit_label: Label = null
var _hp_label: Label = null
var _mp_label: Label = null
var _class_label: Label = null
var _status_label: Label = null
var _terrain_label: Label = null
var _phase_label: Label = null


func _ready() -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	add_child(hbox)

	# Unit info section
	var unit_vbox := VBoxContainer.new()
	unit_vbox.add_theme_constant_override("separation", 0)
	hbox.add_child(unit_vbox)

	_unit_label = Label.new()
	_unit_label.text = ""
	_unit_label.add_theme_font_size_override("font_size", 11)
	unit_vbox.add_child(_unit_label)

	_hp_label = Label.new()
	_hp_label.text = ""
	_hp_label.add_theme_font_size_override("font_size", 10)
	unit_vbox.add_child(_hp_label)

	_mp_label = Label.new()
	_mp_label.text = ""
	_mp_label.add_theme_font_size_override("font_size", 10)
	_mp_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	unit_vbox.add_child(_mp_label)

	_class_label = Label.new()
	_class_label.text = ""
	_class_label.add_theme_font_size_override("font_size", 9)
	_class_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	unit_vbox.add_child(_class_label)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 9)
	_status_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	unit_vbox.add_child(_status_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Terrain info
	_terrain_label = Label.new()
	_terrain_label.text = ""
	_terrain_label.add_theme_font_size_override("font_size", 10)
	_terrain_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	hbox.add_child(_terrain_label)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	# Phase indicator
	_phase_label = Label.new()
	_phase_label.text = "PLAYER PHASE"
	_phase_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	hbox.add_child(_phase_label)


func update_unit_info(unit: Variant) -> void:
	if unit == null or not (unit is UnitData):
		_unit_label.text = ""
		_hp_label.text = ""
		_mp_label.text = ""
		_class_label.text = ""
		_status_label.text = ""
		return
	_unit_label.text = "%s  Lv%d" % [unit.unit_name, unit.level]
	_hp_label.text = "HP %d/%d" % [unit.hp, unit.max_hp]
	if unit.max_mp > 0:
		_mp_label.text = "MP %d/%d" % [unit.mp, unit.max_mp]
	else:
		_mp_label.text = ""
	_class_label.text = unit.unit_class.capitalize()

	# Status effects
	var status_texts: Array = []
	for effect in unit.status_effects:
		status_texts.append(effect.get_type_name())
	if status_texts.size() > 0:
		_status_label.text = " ".join(status_texts)
	else:
		_status_label.text = ""


func update_terrain_info(tile: BattleTile) -> void:
	if tile == null:
		_terrain_label.text = ""
		return
	var tile_name: String = BattleTile.type_name(tile.tile_type)
	var info := tile_name
	if tile.def_bonus > 0:
		info += " DEF+%d" % tile.def_bonus
	if tile.eva_bonus > 0:
		info += " EVA+%d" % tile.eva_bonus
	_terrain_label.text = info


func update_phase(phase: TurnManager.Phase) -> void:
	if phase == TurnManager.Phase.PLAYER_PHASE:
		_phase_label.text = "PLAYER PHASE"
		_phase_label.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	else:
		_phase_label.text = "ENEMY PHASE"
		_phase_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
