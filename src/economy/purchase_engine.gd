class_name PurchaseEngine
extends RefCounted

static func bulk_cost(config: Dictionary, owned: int, amount: int) -> float:
	if amount <= 0: return 0.0
	var base: float = config.base_cost
	var growth: float = config.cost_growth
	return base * pow(growth, owned) * (pow(growth, amount) - 1.0) / (growth - 1.0)

static func max_affordable(config: Dictionary, owned: int, currency: float) -> int:
	if currency < bulk_cost(config, owned, 1): return 0
	var growth: float = config.cost_growth
	var base: float = config.base_cost
	var inside := 1.0 + currency * (growth - 1.0) / (base * pow(growth, owned))
	return maxi(0, int(floor(log(inside) / log(growth))))

