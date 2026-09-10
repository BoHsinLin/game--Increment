extends Control

const UI_NAVIGATION := preload("res://src/ui/main/ui_navigation.gd")

const BACKDROP := preload("res://assets/art/soul_judgement_settlement_v1.png")

func _ready() -> void:
	UI_NAVIGATION.add_back_button(self)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.48, 0.44, 0.78, 0.62)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var challenge := GameEngine.get_weekly_challenge()
	var record: Dictionary = GameEngine.state.weekly_records.get(String(challenge.week_id), {})
	var panel := Label.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -205)
	panel.size = Vector2(600, 410)
	panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_theme_font_size_override("font_size", 24)
	panel.add_theme_color_override("font_color", Color("edf8ff"))
	panel.add_theme_stylebox_override("normal", _frame())
	panel.text = "本週星象：%s\n\n%s\n\n本週加成 ×%.2f\n\n單局最佳業力：%s\n最佳精準：%.0f%%\n\n榮譽：%d\n稱號：%s\n\n排行榜將在 Steamworks 階段同步。" % [String(challenge.name), String(challenge.detail), float(challenge.multiplier), NumberFormatter.format(float(record.get("best_reward", 0.0))), float(record.get("best_precision", 0.0)) * 100.0, int(GameEngine.state.honor), ", ".join(GameEngine.state.unlocked_titles)]
	add_child(panel)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_W):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.90)
	box.border_color = Color("ab8cff", 0.9)
	box.set_border_width_all(2)
	box.set_corner_radius_all(20)
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 26
	box.content_margin_bottom = 26
	return box
