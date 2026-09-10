extends Control

const BACKDROP := preload("res://assets/art/soul_fall_judgment_v2.png")
const UI_NAVIGATION := preload("res://src/ui/main/ui_navigation.gd")
const SOUL_SHEET := preload("res://assets/art/souls/soul_codex_sheet_v1.png")

var _list: VBoxContainer
var _detail: Label
var _release: Button
var _selected_inventory_index := -1
var _portrait: TextureRect

func _ready() -> void:
	UI_NAVIGATION.add_back_button(self)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.44, 0.49, 0.76, 0.50)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var title := Label.new()
	title.text = "靈魂圖鑑"
	title.position = Vector2(60, 40)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("d8fff3"))
	add_child(title)
	var capacity := Label.new()
	capacity.text = "容器  %d / %d" % [GameEngine.state.soul_inventory.size(), int(GameEngine.state.soul_storage_capacity)]
	capacity.position = Vector2(62, 88)
	capacity.add_theme_font_size_override("font_size", 17)
	capacity.add_theme_color_override("font_color", Color("f2c663"))
	add_child(capacity)
	_list = VBoxContainer.new()
	_list.position = Vector2(60, 130)
	_list.size = Vector2(570, 590)
	_list.add_theme_constant_override("separation", 10)
	add_child(_list)
	_detail = Label.new()
	_detail.position = Vector2(730, 195)
	_detail.size = Vector2(450, 240)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 21)
	_detail.add_theme_color_override("font_color", Color("edf8ff"))
	_detail.add_theme_stylebox_override("normal", _frame())
	_detail.text = "靈魂在第一次取得時揭示特質。\n\n選擇一個已發現的靈魂。"
	add_child(_detail)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(1030, 520)
	_portrait.size = Vector2(190, 190)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_release = Button.new()
	_release.position = Vector2(730, 465)
	_release.size = Vector2(240, 48)
	_release.text = "釋放為少量業力"
	_release.pressed.connect(_release_selected)
	_release.hide()
	add_child(_release)
	_build_list()

func _build_list() -> void:
	for child in _list.get_children(): child.queue_free()
	for soul_id in GameEngine.state.soul_codex:
		var soul := GameEngine.get_soul(String(soul_id))
		if soul.is_empty(): continue
		var count: int = GameEngine.state.soul_inventory.count(String(soul_id))
		var button := Button.new()
		button.flat = true
		button.custom_minimum_size.y = 62
		button.text = "✦  %s    ·    %s    ·    %s%s" % [String(soul.name), String(soul.rarity), String(soul.aspect), "    背包 ×%d" % count if count > 0 else ""]
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color(String(soul.color)))
		button.pressed.connect(_select_soul.bind(soul))
		_list.add_child(button)

func _select_soul(soul: Dictionary) -> void:
	_selected_inventory_index = GameEngine.state.soul_inventory.find(String(soul.id))
	_portrait.texture = _soul_texture(String(soul.id))
	_detail.text = "%s\n\n%s靈魂 · %s傾向\n\n基礎回響：×%.1f\n\n%s" % [String(soul.name), String(soul.rarity), String(soul.aspect), float(soul.base_karma), "此靈魂正存放於容器中。" if _selected_inventory_index >= 0 else "已收入圖鑑，尚未存放。"]
	_release.visible = _selected_inventory_index >= 0

func _release_selected() -> void:
	var result := GameEngine.release_stored_soul(_selected_inventory_index)
	if String(result.result) == "released":
		_detail.text = "%s 已離開容器，留下 %s 業力。" % [String(result.soul.name), NumberFormatter.format(float(result.karma))]
		_release.hide()
		_selected_inventory_index = -1
		_build_list()

func _soul_texture(soul_id: String) -> Texture2D:
	var ids := ["ember_memory", "waking_star", "mist_wanderer", "golden_vow", "mirror_oracle", "void_crown"]
	var index := ids.find(soul_id)
	if index < 0: return null
	var texture := AtlasTexture.new()
	var sheet_size := SOUL_SHEET.get_size()
	texture.atlas = SOUL_SHEET
	texture.region = Rect2(float(index % 3) * sheet_size.x / 3.0, float(index / 3) * sheet_size.y / 2.0, sheet_size.x / 3.0, sheet_size.y / 2.0)
	return texture

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_I):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.90)
	box.border_color = Color("73ffe0", 0.75)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 22
	box.content_margin_bottom = 22
	return box
