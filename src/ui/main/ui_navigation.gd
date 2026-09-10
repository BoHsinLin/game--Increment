class_name UiNavigation
extends RefCounted

static func add_back_button(parent: Control) -> void:
	var button := Button.new()
	button.name = "BackToMainButton"
	button.text = "← 返回主控台"
	button.tooltip_text = "返回彈珠檯主畫面"
	button.position = Vector2(1460, 28)
	button.size = Vector2(165, 48)
	button.z_index = 20
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("fff0b1"))
	button.add_theme_stylebox_override("normal", _frame(Color("101a3b", 0.92), Color("d8ae55", 0.9)))
	button.add_theme_stylebox_override("hover", _frame(Color("233465", 0.97), Color("fff0b1", 1.0)))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: parent.get_tree().change_scene_to_file("res://scenes/main_game.tscn"))
	parent.add_child(button)

static func _frame(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	return box
