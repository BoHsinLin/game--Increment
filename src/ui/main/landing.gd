extends Control

const MAIN_ART := preload("res://assets/art/soul_fall_judgment_v2.png")

func _ready() -> void:
	var artwork := TextureRect.new()
	artwork.texture = MAIN_ART
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(artwork)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.024, 0.06, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	layout.position -= Vector2(235, 180)
	layout.size = Vector2(470, 150)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	var title := Label.new()
	title.text = "AFTERLIFE INC."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("edf4ff"))
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "靈魂正墜入命運。請啟動導向閘門。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("c8fff1"))
	layout.add_child(subtitle)
	var enter := Button.new()
	enter.text = "進入審判中樞"
	enter.custom_minimum_size = Vector2(0, 54)
	enter.add_theme_font_size_override("font_size", 18)
	enter.pressed.connect(_enter_game)
	layout.add_child(enter)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_enter_game()

func _enter_game() -> void:
	GameEngine.set_onboarding_step(1)
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
