extends PanelContainer

## Battle sub-menu for selecting inventory items. Shows item name.

signal item_selected(item: ItemData)
signal item_cancelled()

const COLOR_SELECTED := Color(0.941, 0.784, 0.314, 1.0)
const COLOR_NORMAL := Color(0.8, 0.8, 0.8, 1.0)

var _items: Array = []  # Array[ItemData]
var _selected_index: int = 0
var _vbox: VBoxContainer = null
var _labels: Array[Label] = []


func _ready() -> void:
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 2)
	add_child(_vbox)

	var title := Label.new()
	title.text = "  ITEMS  "
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)

	visible = false


func show_items(items: Array) -> void:
	_items = items
	_selected_index = 0

	# Clear old labels
	for lbl in _labels:
		lbl.queue_free()
	_labels.clear()

	if items.is_empty():
		var lbl := Label.new()
		lbl.text = "  No items  "
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_vbox.add_child(lbl)
		_labels.append(lbl)
	else:
		for item in items:
			var lbl := Label.new()
			lbl.text = "  %s  " % item.item_name
			lbl.add_theme_font_size_override("font_size", 10)
			_vbox.add_child(lbl)
			_labels.append(lbl)

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
		item_cancelled.emit()
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	var count := _items.size()
	if count == 0:
		return
	_selected_index = (_selected_index + direction + count) % count
	_update_visuals()


func _confirm() -> void:
	if _items.is_empty():
		return
	if _selected_index < _items.size():
		item_selected.emit(_items[_selected_index])


func _update_visuals() -> void:
	for i in _labels.size():
		var lbl := _labels[i]
		if _items.is_empty():
			continue
		if i == _selected_index:
			lbl.add_theme_color_override("font_color", COLOR_SELECTED)
		else:
			lbl.add_theme_color_override("font_color", COLOR_NORMAL)
