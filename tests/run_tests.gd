extends SceneTree

var failures := 0

func _init() -> void:
	_test_bulk_cost()
	_test_buy_max()
	_test_prestige_reward()
	_test_number_formatter()
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
