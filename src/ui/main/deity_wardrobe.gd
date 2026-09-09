extends Control

const ASTRAEA_ART := preload("res://assets/art/characters/deity_astraea_v1.png")
const SELENE_ART := preload("res://assets/art/characters/deity_selene_v1.png")
const ORPHEON_ART := preload("res://assets/art/characters/deity_orpheon_v1.png")

var _list: VBoxContainer
var _oracle: Label
var _selected: Dictionary = {}
var _action: Button
var _title: Label
var _art: TextureRect
var _deity_row: HBoxContainer

func _ready() -> void:
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_title = Label.new()
	_title.position = Vector2(68, 42)
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color("f4d879"))
	add_child(_title)
	_deity_row = HBoxContainer.new()
	_deity_row.position = Vector2(68, 88)
	_deity_row.size = Vector2(500, 38)
	_deity_row.add_theme_constant_override("separation", 10)
	add_child(_deity_row)
	_list = VBoxContainer.new()
	_list.position = Vector2(68, 142)
	_list.size = Vector2(360, 610)
	_list.add_theme_constant_override("separation", 8)
	add_child(_list)
	_oracle = Label.new()
	_oracle.position = Vector2(850, 585)
	_oracle.size = Vector2(415, 150)
	_oracle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_oracle.add_theme_font_size_override("font_size", 20)
	_oracle.add_theme_color_override("font_color", Color("eaf5ff"))
	_oracle.add_theme_stylebox_override("normal", _frame())
	add_child(_oracle)
	_action = Button.new()
	_action.position = Vector2(850, 755)
	_action.size = Vector2(260, 44)
	_action.pressed.connect(_unlock_or_equip)
	_action.hide()
	add_child(_action)
	_build_deity_switcher()
	_refresh_deity_view()

func _build_deity_switcher() -> void:
	for child in _deity_row.get_children(): child.queue_free()
	var active_id := String(GameEngine.state.get("active_deity_id", "astraea"))
	for deity: Dictionary in GameEngine.deities:
		var button := Button.new()
		button.text = String(deity.name)
		button.flat = deity.id != active_id
		button.custom_minimum_size = Vector2(112, 36)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("f4d879") if deity.id == active_id else Color("d3def6"))
		button.pressed.connect(_select_deity.bind(String(deity.id)))
		_deity_row.add_child(button)

func _select_deity(deity_id: String) -> void:
	if GameEngine.select_deity(deity_id):
		_selected = {}
		_action.hide()
		_build_deity_switcher()
		_refresh_deity_view()

func _refresh_deity_view() -> void:
	var deity := GameEngine.get_active_deity()
	var deity_id := String(deity.get("id", "astraea"))
	_art.texture = _deity_art(deity_id)
	_title.text = "%s的星室" % String(deity.get("name", "阿斯特萊雅"))
	_oracle.text = "「%s」\n\n%s" % [String(deity.get("oracle", "")), String(deity.get("title", ""))]
	_build_list()

func _build_list() -> void:
	for child in _list.get_children(): child.queue_free()
	var deity_id := String(GameEngine.state.get("active_deity_id", "astraea"))
	for cosmetic: Dictionary in GameEngine.deity_cosmetics:
		if String(cosmetic.get("deity_id", "astraea")) != deity_id: continue
		var owned := GameEngine.owns_deity_cosmetic(String(cosmetic.id))
		var equipped := GameEngine.get_equipped_cosmetic(deity_id, String(cosmetic.slot)) == String(cosmetic.id)
		var item := Button.new()
		item.flat = true
		item.custom_minimum_size.y = 52
		item.text = "%s  ·  %s%s" % [String(cosmetic.slot), String(cosmetic.name) if owned else "未解鎖", "  ✓" if equipped else ""]
		item.add_theme_font_size_override("font_size", 17)
		item.add_theme_color_override("font_color", Color("f2c663") if owned else Color("a4aac8"))
		item.pressed.connect(_select.bind(cosmetic))
		_list.add_child(item)

func _select(cosmetic: Dictionary) -> void:
	_selected = cosmetic
	var deity := GameEngine.get_active_deity()
	_oracle.text = "「%s」" % String(cosmetic.oracle) if GameEngine.owns_deity_cosmetic(String(cosmetic.id)) else "尚未解鎖這件外觀。\n\n解鎖後，%s會記住它的預言。" % String(deity.get("name", "這位神祉"))
	_action.show()
	if GameEngine.owns_deity_cosmetic(String(cosmetic.id)):
		_action.text = "裝備此%s" % String(cosmetic.slot)
		_action.disabled = false
	else:
		_action.text = "以 %s %s 解鎖" % [NumberFormatter.format(float(cosmetic.cost)), _currency_name(String(cosmetic.currency))]
		_action.disabled = not _can_afford(cosmetic)

func _unlock_or_equip() -> void:
	if _selected.is_empty(): return
	var result := GameEngine.unlock_or_equip_cosmetic(String(_selected.id))
	if String(result.result) == "equipped":
		_oracle.text = "「%s」" % String(_selected.oracle)
		_build_list()
		_select(_selected)

func _deity_art(deity_id: String) -> Texture2D:
	match deity_id:
		"selene": return SELENE_ART
		"orpheon": return ORPHEON_ART
		_: return ASTRAEA_ART

func _can_afford(cosmetic: Dictionary) -> bool:
	match String(cosmetic.currency):
		"fragments": return int(GameEngine.state.soul_fragments) >= int(cosmetic.cost)
		"seals": return int(GameEngine.state.destiny_seals) >= int(cosmetic.cost)
		_: return float(GameEngine.state.karma) >= float(cosmetic.cost)

func _currency_name(currency: String) -> String:
	match currency:
		"fragments": return "靈魂碎片"
		"seals": return "命運印記"
		_: return "業力"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_G):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.88)
	box.border_color = Color("f2c663", 0.86)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box
