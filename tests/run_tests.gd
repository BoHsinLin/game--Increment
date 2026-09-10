extends SceneTree

var failures := 0

func _init() -> void:
	_test_bulk_cost()
	_test_buy_max()
	_test_prestige_reward()
	_test_number_formatter()
	_test_deity_content()
	_test_replayable_peg_simulation()
	if failures == 0:
		print("All AFTERLIFE INC. core tests passed.")
	quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_bulk_cost() -> void:
	var config := {"base_cost": 10.0, "cost_growth": 1.15}
	_check(is_equal_approx(PurchaseEngine.bulk_cost(config, 0, 1), 10.0), "First generator must cost base cost")
	_check(is_equal_approx(PurchaseEngine.bulk_cost(config, 0, 2), 21.5), "Bulk cost must use geometric sum")

func _test_buy_max() -> void:
	var config := {"base_cost": 10.0, "cost_growth": 1.15}
	_check(PurchaseEngine.max_affordable(config, 0, 9.99) == 0, "Buy Max must reject insufficient funds")
	_check(PurchaseEngine.max_affordable(config, 0, 21.5) == 2, "Buy Max must solve amount without iteration")

func _test_prestige_reward() -> void:
	_check(PrestigeEngine.reward(999999.0) == 0, "Prestige must remain locked below threshold")
	_check(PrestigeEngine.reward(4000000.0) == 2, "Prestige reward must follow square-root curve")

func _test_number_formatter() -> void:
	_check(NumberFormatter.format(1250000.0) == "1.25M", "Formatter must abbreviate millions")

func _test_deity_content() -> void:
	var deities: Variant = ConfigLoader.load_json("res://src/config/deity/deities.json")
	_check(deities is Array and deities.size() == 3, "Three selectable deities must be configured")
	for config_path in ["res://src/config/deity/astraea_cosmetics.json", "res://src/config/deity/selene_cosmetics.json", "res://src/config/deity/orpheon_cosmetics.json"]:
		var cosmetics: Variant = ConfigLoader.load_json(config_path)
		_check(cosmetics is Array and cosmetics.size() == 9, "Each deity must have three complete cosmetic slots")
	var migrated := SaveManager.migrate({"version": 1, "equipped_cosmetics": {"頭飾": "star_crystal"}})
	_check(String(migrated.get("active_deity_id", "")) == "astraea", "Legacy saves must default to Astraea")
	var migrated_equipment: Dictionary = migrated.get("equipped_cosmetics_by_deity", {})
	var migrated_astraea: Dictionary = migrated_equipment.get("astraea", {})
	_check(String(migrated_astraea.get("頭飾", "")) == "star_crystal", "Legacy Astraea equipment must migrate")
	var fate_cards: Variant = ConfigLoader.load_json("res://src/config/fate_cards/fate_cards.json")
	_check(fate_cards is Array and fate_cards.size() == 30, "v1.0 must provide thirty fate cards")
	var souls: Variant = ConfigLoader.load_json("res://src/config/souls/souls.json")
	_check(souls is Array and souls.size() == 6, "Soul codex must provide all six rarity entries")

func _test_replayable_peg_simulation() -> void:
	var first := ConstellationSimulator.simulate(42, 0.12, -0.08, 0.81)
	var replay := ConstellationSimulator.simulate(42, 0.12, -0.08, 0.81)
	_check(int(first.lane) == int(replay.lane), "A peg simulation seed must replay to the same gate")
	_check(first.path == replay.path and first.impacts.size() == ConstellationSimulator.PEG_ROWS.size(), "A peg simulation must preserve its complete impact path")
	_check(int(first.lane) >= 0 and int(first.lane) <= 2, "A peg simulation must resolve to one of three gates")
