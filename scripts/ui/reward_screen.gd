extends CanvasLayer

## Reward/result screen: VICTORY or DEFEAT overlay. Shows XP awards + level-ups. A=continue.

signal continue_pressed()

var _bg: ColorRect = null
var _result_label: Label = null
var _sub_label: Label = null
var _xp_label: Label = null
var _hint_label: Label = null
var _active: bool = false


func _ready() -> void:
	layer = 10

	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	center.add_child(vbox)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 28)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 12)
	_sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_sub_label)

	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 10)
	_xp_label.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_xp_label)

	_hint_label = Label.new()
	_hint_label.text = "[A] Continue"
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)

	_bg.visible = false
	_result_label.visible = false
	_sub_label.visible = false
	_xp_label.visible = false
	_hint_label.visible = false


func show_result(result: TurnManager.BattleResult, xp_awards: Dictionary = {}, level_ups: Array = []) -> void:
	_active = true
	_bg.visible = true
	_result_label.visible = true
	_sub_label.visible = true
	_xp_label.visible = true
	_hint_label.visible = true

	if result == TurnManager.BattleResult.VICTORY:
		_result_label.text = "VICTORY"
		_result_label.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
		_sub_label.text = "All enemies defeated!"

		# Build XP summary
		var xp_text := ""
		for unit in xp_awards:
			if unit is UnitData:
				xp_text += "%s +%d XP\n" % [unit.unit_name, xp_awards[unit]]

		for lu in level_ups:
			xp_text += "%s reached Level %d!\n" % [lu.get("unit_name", "?"), lu.get("level", 0)]

		_xp_label.text = xp_text.strip_edges()
	else:
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		_sub_label.text = "Your forces have fallen..."
		_xp_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("confirm"):
		continue_pressed.emit()
		get_viewport().set_input_as_handled()
