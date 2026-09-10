extends Control

const UI_NAVIGATION := preload("res://src/ui/main/ui_navigation.gd")

const BACKDROP := preload("res://assets/art/cosmic_gameplay_hud_v1.png")

func _ready() -> void:
	UI_NAVIGATION.add_back_button(self)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.35, 0.37, 0.62, 0.65)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -210)
	panel.size = Vector2(520, 420)
	panel.add_theme_constant_override("separation", 18)
	panel.add_theme_stylebox_override("panel", _frame())
	add_child(panel)
	var title := Label.new()
	title.text = "設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("f2c663"))
	panel.add_child(title)
	var flashes := CheckButton.new()
	flashes.text = "減少強烈閃光與衝擊效果"
	flashes.button_pressed = bool(GameEngine.state.settings.get("reduce_flashes", false))
	flashes.toggled.connect(func(value: bool) -> void: GameEngine.update_setting("reduce_flashes", value))
	panel.add_child(flashes)
	var scale_row := HBoxContainer.new()
	var scale_label := Label.new()
	scale_label.text = "介面縮放"
	scale_label.custom_minimum_size.x = 190
	scale_row.add_child(scale_label)
	var scale := OptionButton.new()
	for option in ["90%", "100%", "110%", "120%"]: scale.add_item(option)
	var current := float(GameEngine.state.settings.get("ui_scale", 1.0))
	scale.select(clampi(int(round((current - 0.9) * 10.0)), 0, 3))
	scale.item_selected.connect(func(index: int) -> void: GameEngine.update_setting("ui_scale", 0.9 + float(index) * 0.1))
	scale_row.add_child(scale)
	panel.add_child(scale_row)
	var tutorial := Button.new()
	tutorial.text = "重播第一顆靈魂引導"
	tutorial.pressed.connect(_replay_tutorial)
	panel.add_child(tutorial)
	var controls := Label.new()
	controls.text = "快捷鍵：T 星圖 · C 卡牌 · I 靈魂 · G 神祉 · B 商店 · W 每週挑戰"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color("c8fff1"))
	panel.add_child(controls)

func _replay_tutorial() -> void:
	GameEngine.replay_first_soul_tutorial()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_O):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.92)
	box.border_color = Color("73ffe0", 0.75)
	box.set_border_width_all(2)
	box.set_corner_radius_all(20)
	box.content_margin_left = 34
	box.content_margin_right = 34
	box.content_margin_top = 30
	box.content_margin_bottom = 30
	return box
