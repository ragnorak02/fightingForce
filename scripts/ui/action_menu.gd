extends PanelContainer

## Vertical popup action menu (MOVE / ATTACK / WAIT). Controller nav + A/B.

signal action_selected(action_name: String)
signal menu_cancelled()

const COLOR_SELECTED := Color(0.941, 0.784, 0.314, 1.0)
const COLOR_NORMAL := Color(0.8, 0.8, 0.8, 1.0)
const COLOR_DISABLED := Color(0.4, 0.4, 0.4, 1.0)

var _items: Array[Dictionary] = []  # { label: String, enabled: bool, action: String }
var _selected_index: int = 0
var _vbox: VBoxContainer = null
var _labels: Array[Label] = []


func _ready() -> void:
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 2)
	add_child(_vbox)
	visible = false


func show_menu(items: Array[Dictionary], screen_pos: Vector2 = Vector2.ZERO) -> void:
	_items = items
	_selected_index = 0

	# Clear old labels
	for lbl in _labels:
		lbl.queue_free()
	_labels.clear()

	# Create labels
	for item in items:
		var lbl := Label.new()
		lbl.text = "  " + item.get("label", "???") + "  "
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_vbox.add_child(lbl)
		_labels.append(lbl)

	# Skip to first enabled item
	for i in _items.size():
		if _items[i].get("enabled", true):
			_selected_index = i
			break

	_update_visuals()
	position = screen_pos
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
		menu_cancelled.emit()
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	var count := _items.size()
	if count == 0:
		return
	var next := _selected_index
	for i in count:
		next = (next + direction + count) % count
		if _items[next].get("enabled", true):
			break
	if _items[next].get("enabled", true):
		_selected_index = next
		_update_visuals()


func _confirm() -> void:
	if _selected_index < _items.size() and _items[_selected_index].get("enabled", true):
		action_selected.emit(_items[_selected_index].get("action", ""))


func _update_visuals() -> void:
	for i in _labels.size():
		var lbl := _labels[i]
		var enabled: bool = _items[i].get("enabled", true)
		if not enabled:
			lbl.add_theme_color_override("font_color", COLOR_DISABLED)
		elif i == _selected_index:
			lbl.add_theme_color_override("font_color", COLOR_SELECTED)
		else:
			lbl.add_theme_color_override("font_color", COLOR_NORMAL)
