extends Control

const CONSTELLATION_ART := preload("res://assets/art/cosmic_skill_constellation_v1.png")
const UI_NAVIGATION := preload("res://src/ui/main/ui_navigation.gd")

var _detail: Label
var _selected: Dictionary = {}
var _purchase: Button

func _ready() -> void:
	UI_NAVIGATION.add_back_button(self)
	var art := TextureRect.new()
	art.texture = CONSTELLATION_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_detail = Label.new()
	_detail.visible = false
	_detail.position = Vector2(0, 0)
	_detail.size = Vector2(280, 154)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 18)
	_detail.add_theme_color_override("font_color", Color("eaf5ff"))
	_detail.add_theme_stylebox_override("normal", _star_frame())
	add_child(_detail)
	_purchase = Button.new()
	_purchase.position = Vector2(size.x * 0.73, size.y * 0.57)
	_purchase.size = Vector2(280, 45)
	_purchase.pressed.connect(_purchase_selected)
	_purchase.hide()
	add_child(_purchase)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_nearest(event.position)
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
		get_viewport().set_input_as_handled()

func _select_nearest(point: Vector2) -> void:
	var normalized := Vector2(point.x / size.x, point.y / size.y)
	var nearest: Dictionary = {}
	var distance := 0.11
	for node: Dictionary in GameEngine.skill_nodes:
		var candidate := normalized.distance_to(_node_position(node))
		if candidate < distance:
			distance = candidate
			nearest = node
	if nearest.is_empty():
		_detail.visible = false
		_purchase.hide()
		_selected = {}
		return
	_selected = nearest
	var owned := GameEngine.owns_skill_node(String(nearest.id))
	var requirements_met := true
	for requirement in nearest.get("requires", []):
		if not GameEngine.owns_skill_node(String(requirement)): requirements_met = false
	_detail.text = "%s\n\n%s\n\n%s" % [String(nearest.name), String(nearest.detail), "已共鳴" if owned else ("尚未滿足前置節點" if not requirements_met else "%s ×%s" % [_currency_name(String(nearest.currency)), NumberFormatter.format(float(nearest.cost))])]
	_detail.position = Vector2(size.x * 0.73, size.y * 0.36)
	_detail.visible = true
	_purchase.visible = not owned and requirements_met
	if _purchase.visible:
		_purchase.text = "注入星力" if GameEngine.can_purchase_skill(String(nearest.id)) else "資源不足"
		_purchase.disabled = not GameEngine.can_purchase_skill(String(nearest.id))
	queue_redraw()

func _draw() -> void:
	# 發亮圓環是互動提示，不替代生成星圖中的圖像節點。
	for node: Dictionary in GameEngine.skill_nodes:
		var pos: Vector2 = _node_position(node) * size
		var active := not _selected.is_empty() and String(node.id) == String(_selected.id)
		var owned := GameEngine.owns_skill_node(String(node.id))
		var color := _branch_color(String(node.branch))
		draw_circle(pos, 18.0, Color(color, 0.19 if owned else 0.05))
		draw_arc(pos, 17.0, 0.0, TAU, 20, Color(color, 0.95 if active or owned else 0.28), 1.6)

func _node_position(node: Dictionary) -> Vector2:
	var at: Array = node.get("at", [0.5, 0.5])
	return Vector2(float(at[0]), float(at[1]))

func _branch_color(branch: String) -> Color:
	match branch:
		"業力": return Color("f2c663")
		"靈魂": return Color("73ffe0")
		_: return Color("ab8cff")

func _currency_name(currency: String) -> String:
	match currency:
		"fragments": return "靈魂碎片"
		"seals": return "命運印記"
		_: return "業力"

func _purchase_selected() -> void:
	if _selected.is_empty(): return
	var result := GameEngine.purchase_skill_node(String(_selected.id))
	if String(result.result) == "purchased":
		_select_nearest(_node_position(_selected) * size)

func _star_frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0b1021", 0.91)
	box.border_color = Color("f2c663", 0.9)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	box.shadow_color = Color("77e2d4", 0.25)
	box.shadow_size = 12
	return box
