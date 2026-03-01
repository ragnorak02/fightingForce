extends Control

## Main menu — NEW GAME / CONTINUE / SETTINGS.
## Controller-first navigation with disabled item skipping.

@onready var menu_items: VBoxContainer = %MenuItems
@onready var status_message: Label = %StatusMessage

const COLOR_SELECTED := Color(0.941, 0.784, 0.314, 1)
const COLOR_NORMAL := Color(0.6, 0.55, 0.45, 1)
const COLOR_DISABLED := Color(0.35, 0.33, 0.3, 1)

var _selected_index: int = 0
var _item_labels: Array[Label] = []
var _item_enabled: Array[bool] = []
var _status_timer: float = -1.0
const STATUS_DISPLAY_TIME: float = 2.0


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MENU)
	GameManager.log_info("Main menu ready")

	for child in menu_items.get_children():
		if child is Label:
			_item_labels.append(child)

	_item_enabled = [true, false, false]

	_selected_index = 0
	_update_visuals()
	status_message.text = ""
	%HintBar.text = "[A] Select    [B] Back"


func _process(delta: float) -> void:
	if _status_timer >= 0.0:
		_status_timer -= delta
		if _status_timer < 0.0:
			status_message.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_headless:
		return

	if event.is_action_pressed("move_up"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_select_current()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back"):
		SceneManager.change_scene("res://scenes/boot/boot.tscn")
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	var count := _item_labels.size()
	if count == 0:
		return

	var next := _selected_index
	for i in count:
		next = (next + direction + count) % count
		if _item_enabled[next]:
			break

	if _item_enabled[next]:
		_selected_index = next
		_update_visuals()


func _select_current() -> void:
	if not _item_enabled[_selected_index]:
		return

	var label := _item_labels[_selected_index]
	GameManager.log_info("Menu selected: %s" % label.text)

	match _selected_index:
		0:
			SceneManager.change_scene("res://scenes/battle/battle.tscn")
		1:
			_show_status("No save data found.")
		2:
			_show_status("Settings coming soon...")


func _show_status(msg: String) -> void:
	status_message.text = msg
	_status_timer = STATUS_DISPLAY_TIME


func _update_visuals() -> void:
	for i in _item_labels.size():
		var label := _item_labels[i]
		if not _item_enabled[i]:
			label.add_theme_color_override("font_color", COLOR_DISABLED)
		elif i == _selected_index:
			label.add_theme_color_override("font_color", COLOR_SELECTED)
		else:
			label.add_theme_color_override("font_color", COLOR_NORMAL)
