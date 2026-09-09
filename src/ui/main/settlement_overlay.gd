class_name SettlementOverlay
extends Control

signal dismissed

const SETTLEMENT_ART := preload("res://assets/art/soul_judgement_settlement_v1.png")

var _reward_label: Label
var _detail_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var art := TextureRect.new()
	art.texture = SETTLEMENT_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_reward_label = Label.new()
	_reward_label.set_anchors_preset(Control.PRESET_CENTER)
	_reward_label.position = Vector2(-180, -58)
	_reward_label.size = Vector2(360, 76)
	_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_label.add_theme_font_size_override("font_size", 44)
	_reward_label.add_theme_color_override("font_color", Color("ffe59a"))
	add_child(_reward_label)
	_detail_label = Label.new()
	_detail_label.set_anchors_preset(Control.PRESET_CENTER)
	_detail_label.position = Vector2(-220, 26)
	_detail_label.size = Vector2(440, 72)
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.add_theme_font_size_override("font_size", 18)
	_detail_label.add_theme_color_override("font_color", Color("d8fff3"))
	add_child(_detail_label)
	var continue_area := Button.new()
	continue_area.flat = true
	continue_area.tooltip_text = "點擊繼續"
	continue_area.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	continue_area.position = Vector2(-180, -100)
	continue_area.size = Vector2(360, 76)
	continue_area.pressed.connect(_dismiss)
	add_child(continue_area)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.32)

func show_result(result: Dictionary) -> void:
	var reward := NumberFormatter.format(float(result.reward))
	_reward_label.text = "✦  +%s" % reward
	var fragment := "    ◇ +%d" % int(result.fragments) if int(result.fragments) > 0 else ""
	var lanes := ["碎片閘門", "業力閘門", "命運閘門"]
	var lane := String(lanes[int(result.lane)])
	var soul_text := ""
	var soul: Dictionary = result.get("soul", {})
	if not soul.is_empty():
		soul_text = "\n%s：%s" % ["已存入背包" if bool(result.get("soul_stored", false)) else "靈魂圖鑑新增", String(soul.name)]
	_detail_label.text = "%s  ·  %s\n軌跡 %.0f%%  ·  牌面倍率 ×%.2f%s%s" % [String(result.card), lane, float(result.precision) * 100.0, float(result.multiplier), fragment, soul_text]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dismiss()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE):
		_dismiss()
		get_viewport().set_input_as_handled()

func _dismiss() -> void:
	dismissed.emit()
	queue_free()
