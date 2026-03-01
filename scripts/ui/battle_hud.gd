extends PanelContainer

## Bottom HUD panel: selected unit info + terrain info + phase indicator.

var _unit_label: Label = null
var _hp_label: Label = null
var _class_label: Label = null
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

	_class_label = Label.new()
	_class_label.text = ""
	_class_label.add_theme_font_size_override("font_size", 9)
	_class_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	unit_vbox.add_child(_class_label)

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


func update_unit_info(unit: UnitData) -> void:
	if unit == null:
		_unit_label.text = ""
		_hp_label.text = ""
		_class_label.text = ""
		return
	_unit_label.text = unit.unit_name
	_hp_label.text = "HP %d/%d" % [unit.hp, unit.max_hp]
	_class_label.text = unit.unit_class.capitalize()


func update_terrain_info(tile: BattleTile) -> void:
	if tile == null:
		_terrain_label.text = ""
		return
	var name := BattleTile.type_name(tile.tile_type)
	var info := name
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
