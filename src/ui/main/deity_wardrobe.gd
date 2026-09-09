extends Control

const ASTRAEA_ART := preload("res://assets/art/characters/deity_astraea_v1.png")

var _list: VBoxContainer
var _oracle: Label
var _selected: Dictionary = {}
var _action: Button

func _ready() -> void:
	var art := TextureRect.new()
	art.texture = ASTRAEA_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var title := Label.new()
	title.text = "阿斯特萊雅的星室"
	title.position = Vector2(68, 42)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("f4d879"))
	add_child(title)
	_list = VBoxContainer.new()
	_list.position = Vector2(68, 112)
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
	_oracle.text = "「每一道偏移，都曾是某人的選擇。」"
	add_child(_oracle)
	_action = Button.new()
	_action.position = Vector2(850, 755)
	_action.size = Vector2(260, 44)
	_action.pressed.connect(_unlock_or_equip)
	_action.hide()
	add_child(_action)
	_build_list()

func _build_list() -> void:
	for child in _list.get_children(): child.queue_free()
	for cosmetic: Dictionary in GameEngine.deity_cosmetics:
		var owned := GameEngine.owns_deity_cosmetic(String(cosmetic.id))
		var equipped := String(GameEngine.state.equipped_cosmetics.get(String(cosmetic.slot), "")) == String(cosmetic.id)
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
	_oracle.text = "「%s」" % String(cosmetic.oracle) if GameEngine.owns_deity_cosmetic(String(cosmetic.id)) else "尚未解鎖這件外觀。\n\n解鎖後，阿斯特萊雅會記住它的預言。"
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
