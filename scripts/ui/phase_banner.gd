extends CanvasLayer

## Animated "PLAYER PHASE" / "ENEMY PHASE" banner.

var _bg: ColorRect = null
var _label: Label = null
var _timer: float = -1.0
const DISPLAY_TIME := 1.2

signal banner_finished()


func _ready() -> void:
	layer = 5

	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.6)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 22)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_label)

	_bg.visible = false
	_label.visible = false


func show_phase(phase: TurnManager.Phase) -> void:
	if phase == TurnManager.Phase.PLAYER_PHASE:
		_label.text = "PLAYER PHASE"
		_label.add_theme_color_override("font_color", Color(0.941, 0.784, 0.314))
	else:
		_label.text = "ENEMY PHASE"
		_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	_bg.visible = true
	_label.visible = true
	_timer = DISPLAY_TIME


func _process(delta: float) -> void:
	if _timer <= 0:
		return
	_timer -= delta
	if _timer <= 0:
		_bg.visible = false
		_label.visible = false
		banner_finished.emit()
