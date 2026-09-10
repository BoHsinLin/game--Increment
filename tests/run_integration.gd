extends Node

const MAIN_GAME_SCRIPT := preload("res://src/ui/main/main_game.gd")
const CARD_REVEAL_SCRIPT := preload("res://src/ui/main/card_reveal_overlay.gd")
const SETTLEMENT_SCRIPT := preload("res://src/ui/main/settlement_overlay.gd")

var failures := 0
var _original_state: Dictionary
var _original_shop_items: Array

func _ready() -> void:
	await get_tree().process_frame
	_original_state = GameEngine.state.duplicate(true)
	_original_shop_items = GameEngine.special_shop_items.duplicate(true)
	_test_first_soul_round()
	await _test_rune_overlay_visibility()
	await _test_card_reveal_survives_ui_refresh()
	await _test_three_complete_visible_rounds()
	await _test_interface_scene_smoke()
	_test_reincarnated_alignment_round()
	_test_limited_shop_cycle()
	GameEngine.state = _original_state
	GameEngine.special_shop_items = _original_shop_items
	if failures == 0: print("All AFTERLIFE INC. integration tests passed.")
	get_tree().quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _fresh_round() -> void:
	GameEngine.state = GameEngine._initial_state()
	GameEngine._begin_constellation_round()

func _test_first_soul_round() -> void:
	_fresh_round()
	var before_karma := float(GameEngine.state.karma)
	GameEngine.select_fate_card(0)
	var result := GameEngine.confirm_revealed_card()
	_check(String(result.result) == "launched", "First-soul flow must launch immediately after card confirmation")
	_check(float(GameEngine.state.karma) > before_karma, "First-soul flow must grant karma")
	_check(result.get("peg_path", []).size() == 14 and result.get("peg_impacts", []).size() == ConstellationSimulator.PEG_ROWS.size(), "A launched soul must contain a complete peg replay")

func _test_rune_overlay_visibility() -> void:
	_fresh_round()
	var screen: Control = MAIN_GAME_SCRIPT.new()
	add_child(screen)
	await get_tree().process_frame
	_check(not screen.rune_timing_game.visible, "The rune overlay must not distract from the first-soul screen")
	GameEngine.state.prestige_count = 1
	GameEngine._begin_constellation_round()
	GameEngine.select_fate_card(0)
	GameEngine.confirm_revealed_card()
	screen.refresh()
	_check(screen.rune_timing_game.visible, "The rune overlay must appear only when a reincarnated player can use it")
	screen.queue_free()
	await get_tree().process_frame

func _test_card_reveal_survives_ui_refresh() -> void:
	_fresh_round()
	var screen: Control = MAIN_GAME_SCRIPT.new()
	add_child(screen)
	await get_tree().process_frame
	var card := screen.card_bar.get_child(0) as TextureButton
	screen.refresh()
	_check(screen.card_bar.get_child(0) == card, "A stable round must not recreate its card controls on a resource refresh")
	screen._choose_fate_card(0, card)
	await get_tree().create_timer(0.12).timeout
	screen.refresh()
	await get_tree().create_timer(0.42).timeout
	_check(not GameEngine.selected_fate_card.is_empty(), "A card reveal must survive a UI refresh and select its rule")
	screen.queue_free()

func _test_three_complete_visible_rounds() -> void:
	_fresh_round()
	var screen: Control = MAIN_GAME_SCRIPT.new()
	add_child(screen)
	await get_tree().process_frame
	var starting_processed := float(GameEngine.state.total_souls_processed)
	for round_index in 3:
		var card := screen.card_bar.get_child(0) as TextureButton
		screen._choose_fate_card(0, card)
		await get_tree().create_timer(0.45).timeout
		var reveal := _child_of_type(screen, CARD_REVEAL_SCRIPT)
		_check(is_instance_valid(reveal), "Round %d must show the card-rule reveal" % (round_index + 1))
		if is_instance_valid(reveal):
			reveal.confirmed.emit()
			reveal.queue_free()
		await get_tree().create_timer(1.72).timeout
		var settlement := _child_of_type(screen, SETTLEMENT_SCRIPT)
		_check(is_instance_valid(settlement), "Round %d must finish its soul drop with a settlement" % (round_index + 1))
		if is_instance_valid(settlement): settlement._dismiss()
		await get_tree().process_frame
		_check(screen.card_bar.get_child_count() == 3, "Round %d must prepare the next three-card choice" % (round_index + 1))
	_check(is_equal_approx(float(GameEngine.state.total_souls_processed) - starting_processed, 3.0), "Three complete visible rounds must process exactly three souls")
	screen.queue_free()
	await get_tree().process_frame

func _child_of_type(parent: Node, script: Script) -> Node:
	for child in parent.get_children():
		if child.get_script() == script: return child
	return null

func _test_interface_scene_smoke() -> void:
	for scene_path in [
		"res://scenes/landing.tscn", "res://scenes/main_game.tscn", "res://scenes/fate_collection.tscn",
		"res://scenes/soul_codex.tscn", "res://scenes/skill_constellation.tscn", "res://scenes/deity_wardrobe.tscn",
		"res://scenes/special_shop.tscn", "res://scenes/weekly_challenge.tscn", "res://scenes/settings_screen.tscn"
	]:
		_fresh_round()
		var packed := load(scene_path) as PackedScene
		var screen := packed.instantiate()
		add_child(screen)
		await get_tree().process_frame
		_check(screen.is_inside_tree(), "Interface scene must load: %s" % scene_path)
		screen.queue_free()
		await get_tree().process_frame

func _test_reincarnated_alignment_round() -> void:
	_fresh_round()
	GameEngine.state.prestige_count = 1
	GameEngine._begin_constellation_round()
	GameEngine.select_fate_card(0)
	_check(String(GameEngine.confirm_revealed_card().result) == "fate_ready", "Reincarnated flow must require rune alignment")
	for _index in GameEngine.get_rune_capacity():
		GameEngine.judgement_phase = 0.5
		GameEngine.lock_active_rune()
	var result := GameEngine.lock_active_rune()
	_check(String(result.result) == "launched", "A complete rune seal must launch the soul on the next input")
	_check(float(result.precision) >= 0.99, "Centered rune seals must retain their precision")

func _test_limited_shop_cycle() -> void:
	_fresh_round()
	GameEngine.special_shop_items = [{"id":"test_oracle", "type":"limited", "name":"測試諭令", "detail":"", "karma":0, "fragments":0, "seals":0, "value":0.5}]
	_check(String(GameEngine.buy_special_shop_item("hidden_item").result) == "missing", "Unknown shop entries must be rejected")
	var first := GameEngine.buy_special_shop_item("test_oracle")
	_check(String(first.result) == "purchased", "The displayed limited oracle must be purchasable once")
	_check(is_equal_approx(float(GameEngine.state.next_round_karma_bonus), 0.5), "A limited oracle must prepare its next-round bonus")
	_check(String(GameEngine.buy_special_shop_item("test_oracle").result) == "sold_out", "A limited oracle must sell out for its current shop cycle")
