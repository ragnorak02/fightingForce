extends PanelContainer

## Combat preview panel: attacker vs defender stats + hit%/damage. A=confirm B=cancel.

signal attack_confirmed()
signal attack_cancelled()

var _content_label: Label = null


func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title := Label.new()
	title.text = "COMBAT PREVIEW"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_content_label = Label.new()
	_content_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_content_label)

	var hint := Label.new()
	hint.text = "[A] Attack  [B] Cancel"
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	visible = false


func show_preview(preview_data: Dictionary) -> void:
	var text := ""
	text += "%s  vs  %s\n" % [preview_data.get("attacker_name", "?"), preview_data.get("defender_name", "?")]
	text += "Damage: %d\n" % preview_data.get("damage", 0)
	text += "Hit: %d%%\n" % preview_data.get("hit_chance", 0)
	text += "Crit: %d%%" % preview_data.get("crit_chance", 0)
	_content_label.text = text
	visible = true


func hide_preview() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("confirm"):
		attack_confirmed.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back"):
		attack_cancelled.emit()
		get_viewport().set_input_as_handled()
