class_name CardRevealOverlay
extends Control

signal confirmed

var _title: Label
var _detail: Label
var _card_art: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.02, 0.07, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	_card_art = TextureRect.new()
	_card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_art.set_anchors_preset(Control.PRESET_CENTER)
	_card_art.position = Vector2(-165, -255)
	_card_art.size = Vector2(330, 440)
	_card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_art)
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.position = Vector2(-260, 175)
	_title.size = Vector2(520, 35)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color("ffe39a"))
	add_child(_title)
	_detail = Label.new()
	_detail.set_anchors_preset(Control.PRESET_CENTER)
	_detail.position = Vector2(-310, 218)
	_detail.size = Vector2(620, 54)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 18)
	_detail.add_theme_color_override("font_color", Color("d8fff3"))
	add_child(_detail)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.22)

func present(card: Dictionary, texture: Texture2D) -> void:
	_card_art.texture = texture
	_title.text = String(card.name)
	_detail.text = String(card.detail)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		confirmed.emit()
		queue_free()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		confirmed.emit()
		queue_free()
		get_viewport().set_input_as_handled()
