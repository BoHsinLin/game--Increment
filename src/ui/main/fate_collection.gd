extends Control

const BACKDROP := preload("res://assets/art/cosmic_skill_constellation_v1.png")
const CARD_BACK := preload("res://assets/art/cards/card_mystery_v1.png")
const CARD_STARFALL := preload("res://assets/art/cards/card_starfall_v1.png")
const CARD_TIDE := preload("res://assets/art/cards/card_tide_v1.png")
const CARD_COMET := preload("res://assets/art/cards/card_comet_v1.png")
const CARD_MERCY := preload("res://assets/art/cards/card_mercy_v1.png")
const CARD_ECHO := preload("res://assets/art/cards/card_echo_v1.png")
const CARD_AURORA := preload("res://assets/art/cards/card_aurora_v1.png")
const CARD_ECLIPSE := preload("res://assets/art/cards/card_eclipse_v1.png")
const CARD_ORBIT := preload("res://assets/art/cards/card_orbit_v1.png")
const CARD_PRISM := preload("res://assets/art/cards/card_prism_v1.png")
const CARD_NOVA := preload("res://assets/art/cards/card_nova_v1.png")
const CARD_WEAVER := preload("res://assets/art/cards/card_weaver_v1.png")
const CARD_VOID_BLOOM := preload("res://assets/art/cards/card_void_bloom_v1.png")
const EXPANSION_SHEET_A := preload("res://assets/art/cards/card_expansion_sheet_a_v1.png")
const EXPANSION_SHEET_B := preload("res://assets/art/cards/card_expansion_sheet_b_v1.png")
const EXPANSION_SHEET_C := preload("res://assets/art/cards/card_expansion_sheet_c_v1.png")

var _grid: GridContainer
var _detail: Label
var _purchase: Button
var _selected: Dictionary = {}

func _ready() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.modulate = Color(0.54, 0.58, 0.80, 0.54)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var title := Label.new()
	title.text = "命運藏庫"
	title.position = Vector2(54, 34)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("f5d882"))
	add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.position = Vector2(54, 105)
	_grid.size = Vector2(820, 650)
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 16)
	add_child(_grid)
	_detail = Label.new()
	_detail.position = Vector2(925, 178)
	_detail.size = Vector2(390, 280)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 20)
	_detail.add_theme_color_override("font_color", Color("eaf5ff"))
	_detail.add_theme_stylebox_override("normal", _frame())
	_detail.text = "點選一張命運牌，查看它的星象規則。"
	add_child(_detail)
	_purchase = Button.new()
	_purchase.position = Vector2(925, 485)
	_purchase.size = Vector2(250, 48)
	_purchase.add_theme_font_size_override("font_size", 17)
	_purchase.pressed.connect(_purchase_selected)
	add_child(_purchase)
	_purchase.hide()
	_build_cards()

func _build_cards() -> void:
	for child in _grid.get_children(): child.queue_free()
	for card: Dictionary in GameEngine.fate_cards:
		var button := TextureButton.new()
		var owned := GameEngine.owns_fate_card(String(card.id))
		button.texture_normal = _texture_for(String(card.id)) if owned else CARD_BACK
		button.texture_hover = button.texture_normal
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(120, 168)
		button.modulate = Color.WHITE if owned else Color(0.45, 0.47, 0.60, 0.76)
		button.tooltip_text = "已收藏" if owned else "未解鎖的命運"
		button.pressed.connect(_select_card.bind(card))
		_grid.add_child(button)

func _select_card(card: Dictionary) -> void:
	_selected = card
	var owned := GameEngine.owns_fate_card(String(card.id))
	if owned:
		_detail.text = "%s\n\n%s\n\n已永久收藏" % [card.name, card.detail]
		_purchase.hide()
	else:
		_detail.text = "未揭示的命運\n\n購買後才會讀取此卡的星象規則。"
		_purchase.text = "以 %s 業力取得" % NumberFormatter.format(float(card.cost))
		_purchase.disabled = GameEngine.state.karma < float(card.cost)
		_purchase.show()

func _purchase_selected() -> void:
	if _selected.is_empty(): return
	var result := GameEngine.purchase_fate_card(String(_selected.id))
	if String(result.result) == "purchased":
		_select_card(_selected)
		_build_cards()
	elif String(result.result) == "insufficient":
		_detail.text = "還需要 %s 業力。" % NumberFormatter.format(float(result.cost))

func _texture_for(card_id: String) -> Texture2D:
	match card_id:
		"starfall": return CARD_STARFALL
		"tide": return CARD_TIDE
		"comet": return CARD_COMET
		"mercy": return CARD_MERCY
		"echo": return CARD_ECHO
		"aurora": return CARD_AURORA
		"eclipse": return CARD_ECLIPSE
		"orbit": return CARD_ORBIT
		"prism": return CARD_PRISM
		"nova": return CARD_NOVA
		"weaver": return CARD_WEAVER
		"void_bloom": return CARD_VOID_BLOOM
		"shattered_hour", "aurora_moth", "astral_compass", "mirror_moon", "eclipse_rose", "solar_reliquary": return _expansion_texture(EXPANSION_SHEET_A, ["shattered_hour", "aurora_moth", "astral_compass", "mirror_moon", "eclipse_rose", "solar_reliquary"].find(card_id))
		"star_whale", "twin_masks", "galaxy_lantern", "jade_key", "comet_hand", "obsidian_crown": return _expansion_texture(EXPANSION_SHEET_B, ["star_whale", "twin_masks", "galaxy_lantern", "jade_key", "comet_hand", "obsidian_crown"].find(card_id))
		"radiant_arch", "teal_flame", "stardust_fox", "constellation_bell", "crescent_wave", "galaxy_seed": return _expansion_texture(EXPANSION_SHEET_C, ["radiant_arch", "teal_flame", "stardust_fox", "constellation_bell", "crescent_wave", "galaxy_seed"].find(card_id))
		_: return CARD_BACK

func _expansion_texture(sheet: Texture2D, index: int) -> Texture2D:
	var texture := AtlasTexture.new()
	var sheet_size := sheet.get_size()
	texture.atlas = sheet
	texture.region = Rect2(float(index % 3) * sheet_size.x / 3.0, float(index / 3) * sheet_size.y / 2.0, sheet_size.x / 3.0, sheet_size.y / 2.0)
	return texture

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_C):
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.90)
	box.border_color = Color("f2c663", 0.85)
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 22
	box.content_margin_bottom = 22
	return box
