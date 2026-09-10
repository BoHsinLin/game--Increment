extends Control

const BACKDROP := preload("res://assets/art/cosmic_pachinko_observatory_v1.png")
const UI_NAVIGATION := preload("res://src/ui/main/ui_navigation.gd")

var _offers: VBoxContainer
var _clock: Label
var _detail: Label
var _selected: Dictionary = {}
var _buy: Button

func _ready() -> void:
	UI_NAVIGATION.add_back_button(self)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.48, 0.46, 0.76, 0.58)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var title := Label.new()
	title.text = "星界特殊商店"
	title.position = Vector2(55, 42)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("f2c663"))
	add_child(title)
	_clock = Label.new()
	_clock.position = Vector2(57, 94)
	_clock.add_theme_font_size_override("font_size", 17)
	_clock.add_theme_color_override("font_color", Color("c8fff1"))
	add_child(_clock)
	_offers = VBoxContainer.new()
	_offers.position = Vector2(55, 145)
	_offers.size = Vector2(565, 490)
	_offers.add_theme_constant_override("separation", 15)
	add_child(_offers)
	_detail = Label.new()
	_detail.position = Vector2(750, 225)
	_detail.size = Vector2(420, 230)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 21)
	_detail.add_theme_color_override("font_color", Color("eaf5ff"))
	_detail.add_theme_stylebox_override("normal", _frame())
	_detail.text = "每二十分鐘，星界會帶來三件新遺物。"
	add_child(_detail)
	_buy = Button.new()
	_buy.position = Vector2(750, 485)
	_buy.size = Vector2(310, 48)
	_buy.pressed.connect(_buy_selected)
	_buy.hide()
	add_child(_buy)
	_build_offers()

func _process(_delta: float) -> void:
	var shop := GameEngine.get_special_shop_offers()
	_clock.text = "距離下一次輪替：%02d:%02d" % [int(shop.seconds_remaining) / 60, int(shop.seconds_remaining) % 60]

func _build_offers() -> void:
	for child in _offers.get_children(): child.queue_free()
	var shop := GameEngine.get_special_shop_offers()
	for item: Dictionary in shop.offers:
		var button := Button.new()
		button.flat = true
		button.custom_minimum_size.y = 112
		button.text = "✦  %s\n%s" % [String(item.name), _cost_text(item)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", Color("f2c663"))
		button.pressed.connect(_select.bind(item))
		_offers.add_child(button)

func _select(item: Dictionary) -> void:
	_selected = item
	_detail.text = "%s\n\n%s\n\n%s" % [String(item.name), String(item.detail), _cost_text(item)]
	_buy.text = "取得此物"
	var sold_out := String(item.get("type", "")) == "limited" and not GameEngine.is_limited_shop_item_available(String(item.id))
	_buy.disabled = not _can_afford(item) or sold_out
	if sold_out: _buy.text = "本輪已售罄"
	_buy.show()

func _buy_selected() -> void:
	if _selected.is_empty(): return
	var result := GameEngine.buy_special_shop_item(String(_selected.id))
	if String(result.result) == "purchased":
		_detail.text = "%s 已納入星界收藏。" % String(_selected.name)
		_buy.hide()
		_build_offers()
	elif String(result.result) == "owned":
		_detail.text = "這件物品已在你的收藏中。"
		_buy.hide()
	elif String(result.result) == "sold_out":
		_detail.text = "這份限定諭令已在本輪售罄。"
		_buy.hide()

func _can_afford(item: Dictionary) -> bool:
	return GameEngine.state.karma >= float(item.karma) and int(GameEngine.state.soul_fragments) >= int(item.fragments) and int(GameEngine.state.destiny_seals) >= int(item.seals)

func _cost_text(item: Dictionary) -> String:
	var costs: Array[String] = []
	if float(item.karma) > 0: costs.append("✦ " + NumberFormatter.format(float(item.karma)))
	if int(item.fragments) > 0: costs.append("◇ " + str(int(item.fragments)))
	if int(item.seals) > 0: costs.append("✧ " + str(int(item.seals)))
	return " + ".join(costs)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_B):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.90)
	box.border_color = Color("f2c663", 0.82)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	return box
