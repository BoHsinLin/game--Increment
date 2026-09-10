extends Control

const TIMING_GAME_SCRIPT := preload("res://src/ui/main/judgement_timing_game.gd")
const SETTLEMENT_OVERLAY_SCRIPT := preload("res://src/ui/main/settlement_overlay.gd")
const CARD_REVEAL_OVERLAY_SCRIPT := preload("res://src/ui/main/card_reveal_overlay.gd")
const SOUL_DROP_OVERLAY_SCRIPT := preload("res://src/ui/main/soul_drop_overlay.gd")
const GAMEPLAY_HUD := preload("res://assets/art/cosmic_gameplay_hud_v1.png")
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
const CARD_MYSTERY := preload("res://assets/art/cards/card_mystery_v1.png")
const EXPANSION_SHEET_A := preload("res://assets/art/cards/card_expansion_sheet_a_v1.png")
const EXPANSION_SHEET_B := preload("res://assets/art/cards/card_expansion_sheet_b_v1.png")
const EXPANSION_SHEET_C := preload("res://assets/art/cards/card_expansion_sheet_c_v1.png")

var karma_label: Label
var fragments_label: Label
var rate_label: Label
var queue_label: Label
var timing_status: Label
var round_label: Label
var rune_unlock_button: Button
var card_bar: HBoxContainer
var rune_timing_game: Control
var _ui_elapsed := 0.0
var _drop_active := false
var _card_reveal_pending := false
var _card_signature := ""

func _ready() -> void:
	_build_interface()
	EventBus.state_changed.connect(refresh)
	EventBus.toast_requested.connect(_show_toast)
	refresh()
	if int(GameEngine.state.get("onboarding_step", 0)) == 1:
		_show_toast("第一顆靈魂正在等待。選一張命運牌。", "normal")

func _process(delta: float) -> void:
	_ui_elapsed += delta
	if _ui_elapsed >= GameConstants.UI_REFRESH_SECONDS:
		_ui_elapsed = 0.0
		refresh()

func _build_interface() -> void:
	var art := TextureRect.new()
	art.texture = GAMEPLAY_HUD
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	# 所有結構化外觀都在生成圖中；這些節點只提供資訊與透明互動命中區。
	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(hud)

	var resources := HBoxContainer.new()
	resources.position = Vector2(28, 22)
	resources.size = Vector2(610, 50)
	resources.add_theme_constant_override("separation", 30)
	hud.add_child(resources)
	karma_label = _metric(resources, "✦")
	fragments_label = _metric(resources, "◇")
	rate_label = _metric(resources, "✧")
	queue_label = _metric(resources, "◌")

	round_label = Label.new()
	round_label.position = Vector2(34, 82)
	round_label.add_theme_font_size_override("font_size", 15)
	round_label.add_theme_color_override("font_color", Color("d9e8ff"))
	hud.add_child(round_label)

	rune_unlock_button = Button.new()
	rune_unlock_button.position = Vector2(645, 22)
	rune_unlock_button.size = Vector2(180, 38)
	rune_unlock_button.flat = true
	rune_unlock_button.add_theme_font_size_override("font_size", 13)
	rune_unlock_button.add_theme_color_override("font_color", Color("f2c663"))
	rune_unlock_button.pressed.connect(_unlock_next_rune)
	hud.add_child(rune_unlock_button)

	rune_timing_game = TIMING_GAME_SCRIPT.new()
	rune_timing_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	rune_timing_game.offset_left = 150
	rune_timing_game.offset_top = 105
	rune_timing_game.offset_right = -235
	rune_timing_game.offset_bottom = -170
	rune_timing_game.hide()
	hud.add_child(rune_timing_game)
	var constellation_gate := Button.new()
	constellation_gate.flat = true
	constellation_gate.tooltip_text = "開啟宇宙星圖"
	constellation_gate.position = Vector2(0, 0)
	constellation_gate.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	constellation_gate.offset_left = -230
	constellation_gate.offset_top = 105
	constellation_gate.offset_right = -25
	constellation_gate.offset_bottom = -180
	constellation_gate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	constellation_gate.pressed.connect(_open_constellation)
	hud.add_child(constellation_gate)

	card_bar = HBoxContainer.new()
	card_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card_bar.position = Vector2(-170, -165)
	card_bar.size = Vector2(340, 142)
	card_bar.add_theme_constant_override("separation", 14)
	hud.add_child(card_bar)

	timing_status = Label.new()
	timing_status.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	timing_status.position = Vector2(-270, -27)
	timing_status.size = Vector2(540, 24)
	timing_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timing_status.add_theme_font_size_override("font_size", 15)
	timing_status.add_theme_color_override("font_color", Color("d8f9ee"))
	timing_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(timing_status)

func _metric(parent: Container, glyph: String) -> Label:
	var value := Label.new()
	value.text = glyph + " 0"
	value.custom_minimum_size.x = 110
	value.add_theme_font_size_override("font_size", 19)
	value.add_theme_color_override("font_color", Color("eef6ff"))
	parent.add_child(value)
	return value

func refresh() -> void:
	if not is_instance_valid(karma_label): return
	var state := GameEngine.state
	var rates := GameEngine.get_rates()
	karma_label.text = "✦  " + NumberFormatter.format(state.karma)
	fragments_label.text = "◇  " + str(int(state.soul_fragments))
	rate_label.text = "✧  +%s/s" % NumberFormatter.format(rates.karma)
	queue_label.text = "◌  " + NumberFormatter.format(state.souls)
	var round := GameEngine.get_constellation_round()
	# 首局不需要節印，不能讓尚未解鎖的舊判定視覺遮住生成主畫面。
	if is_instance_valid(rune_timing_game):
		rune_timing_game.visible = GameEngine.requires_fate_alignment() and not round.selected.is_empty() and not bool(round.card_revealed)
	round_label.text = "命運窗 %.0f 秒    節印 %d / %d" % [float(round.seconds), int(round.active_rune), int(round.max_runes)] if GameEngine.requires_fate_alignment() else "初次引魂：翻牌後靈魂將直接落下"
	var next_unlock: Dictionary = round.next_rune_unlock
	rune_unlock_button.visible = GameEngine.requires_fate_alignment() and not next_unlock.is_empty()
	if rune_unlock_button.visible:
		rune_unlock_button.text = "解鎖浮文 +1  ◇%d" % int(next_unlock.cost_destiny_seals)
		rune_unlock_button.disabled = int(state.destiny_seals) < int(next_unlock.cost_destiny_seals)
	# UI 每 0.1 秒刷新資源；翻牌期間不能重建卡片，否則 Tween 會被 queue_free 中斷。
	if _card_reveal_pending:
		timing_status.text = "命運牌正在揭示…"
		return
	var card_signature := _card_signature_for(round)
	if card_signature != _card_signature:
		_card_signature = card_signature
		_rebuild_card_bar(round)
	var status := "選擇一張命運牌" if round.selected.is_empty() else ("確認本局規則" if bool(round.card_revealed) else ("SPACE — 鎖定浮文／推送靈魂" if GameEngine.requires_fate_alignment() else "命運牌已確認，靈魂等待掉落"))
	if GameEngine.can_use_auto_ritual(): status += "  ·  A 自動儀式：%s" % ("開" if bool(state.settings.get("auto_ritual", false)) else "關")
	timing_status.text = status

func _card_signature_for(round: Dictionary) -> String:
	var ids: Array[String] = []
	for card: Dictionary in round.cards:
		ids.append(String(card.get("id", "")))
	return "%s|%s|%s" % [",".join(ids), String(round.selected.get("id", "")), str(bool(round.card_revealed))]

func _rebuild_card_bar(round: Dictionary) -> void:
	for child in card_bar.get_children(): child.queue_free()
	for index in round.cards.size():
		var card: Dictionary = round.cards[index]
		var button := TextureButton.new()
		var face := _card_texture(String(card.id))
		var is_selected: bool = not round.selected.is_empty() and round.selected.id == card.id
		button.texture_normal = face if is_selected else CARD_MYSTERY
		button.texture_hover = face if is_selected else CARD_MYSTERY
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(104, 138)
		button.pivot_offset = Vector2(52, 69)
		button.tooltip_text = "%s\n%s" % [card.name, card.detail]
		button.disabled = not round.selected.is_empty()
		if not round.selected.is_empty() and round.selected.id == card.id:
			button.modulate = Color("fff0a5")
		button.pressed.connect(_choose_fate_card.bind(index, button))
		card_bar.add_child(button)

func _card_texture(card_id: String) -> Texture2D:
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
		_: return CARD_MYSTERY

func _expansion_texture(sheet: Texture2D, index: int) -> Texture2D:
	var texture := AtlasTexture.new()
	var sheet_size := sheet.get_size()
	texture.atlas = sheet
	texture.region = Rect2(float(index % 3) * sheet_size.x / 3.0, float(index / 3) * sheet_size.y / 2.0, sheet_size.x / 3.0, sheet_size.y / 2.0)
	return texture

func _choose_fate_card(index: int, card_button: TextureButton) -> void:
	if _card_reveal_pending: return
	_card_reveal_pending = true
	for card_control in card_bar.get_children(): card_control.disabled = true
	var choice: Dictionary = GameEngine.get_constellation_round().cards[index]
	var flip := create_tween()
	flip.tween_property(card_button, "scale:x", 0.03, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flip.tween_callback(func() -> void:
		card_button.texture_normal = _card_texture(String(choice.id))
		card_button.texture_hover = _card_texture(String(choice.id))
	)
	flip.tween_property(card_button, "scale:x", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await flip.finished
	_card_reveal_pending = false
	GameEngine.select_fate_card(index)
	GameEngine.set_onboarding_step(2)
	_show_card_reveal(choice)

func _lock_or_launch() -> void:
	if _drop_active: return
	var result := GameEngine.lock_active_rune()
	match String(result.result):
		"choose_card": _show_toast("選擇一張命運牌。", "minor")
		"locked": _show_toast("浮文已鎖定。", "normal")
		"ready": _show_toast("節印完成，再次按 SPACE 推送靈魂。", "major")
		"launched": _play_drop_then_settle(result)

func _unlock_next_rune() -> void:
	var result := GameEngine.unlock_next_rune()
	if String(result.result) == "unlocked":
		_show_toast("節印環已擴展至 %d 枚。" % int(result.capacity), "major")
	elif String(result.result) == "insufficient":
		_show_toast("需要 %d 枚命運印記。" % int(result.cost), "minor")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		_open_constellation()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		get_tree().change_scene_to_file("res://scenes/fate_collection.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		get_tree().change_scene_to_file("res://scenes/soul_codex.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		get_tree().change_scene_to_file("res://scenes/deity_wardrobe.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		get_tree().change_scene_to_file("res://scenes/special_shop.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_W:
		get_tree().change_scene_to_file("res://scenes/weekly_challenge.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O:
		get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_A:
		var auto_result := GameEngine.toggle_auto_ritual()
		if String(auto_result.result) == "locked": _show_toast("需要解鎖「後世重啟」星圖節點。", "minor")
		else: _show_toast("自動命運儀式：%s（收益較低）" % ("開啟" if String(auto_result.result) == "enabled" else "關閉"), "normal")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_lock_or_launch()
		get_viewport().set_input_as_handled()

func _show_toast(message: String, _tier: String) -> void:
	if is_instance_valid(timing_status): timing_status.text = message

func _show_settlement(result: Dictionary) -> void:
	var overlay: SettlementOverlay = SETTLEMENT_OVERLAY_SCRIPT.new()
	add_child(overlay)
	overlay.show_result(result)
	if int(GameEngine.state.get("onboarding_step", 0)) < 4:
		overlay.dismissed.connect(func() -> void: GameEngine.set_onboarding_step(4))

func _show_card_reveal(card: Dictionary) -> void:
	var overlay: CardRevealOverlay = CARD_REVEAL_OVERLAY_SCRIPT.new()
	add_child(overlay)
	overlay.present(card, _card_texture(String(card.id)))
	overlay.confirmed.connect(_confirm_card_rule)

func _confirm_card_rule() -> void:
	var result := GameEngine.confirm_revealed_card()
	if String(result.result) == "fate_ready":
		_show_toast("命運已顯現。現在鎖定浮文，改變落點。", "normal")
		return
	if String(result.result) == "launched":
		_play_drop_then_settle(result)

func _play_drop_then_settle(result: Dictionary) -> void:
	_drop_active = true
	_show_toast("靈魂正在掉落…", "normal")
	var drop: SoulDropOverlay = SOUL_DROP_OVERLAY_SCRIPT.new()
	add_child(drop)
	drop.start(result)
	await drop.finished
	_show_settlement(result)
	_drop_active = false

func _open_constellation() -> void:
	get_tree().change_scene_to_file("res://scenes/skill_constellation.tscn")
