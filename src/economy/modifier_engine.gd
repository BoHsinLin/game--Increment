class_name ModifierEngine
extends RefCounted

static func generator_multiplier(state: Dictionary, config: Dictionary, upgrades: Array) -> float:
	var result := 1.0
	var owned: int = state.generators.get(config.id, 0)
	for milestone: Dictionary in config.milestones:
		if owned >= int(milestone.amount): result *= float(milestone.multiplier)
	for upgrade: Dictionary in upgrades:
		if state.upgrades.get(upgrade.id, false) and upgrade.target == "generator" and upgrade.target_id == config.id:
			result *= float(upgrade.multiplier)
	return result

static func global_multiplier(state: Dictionary, upgrades: Array) -> float:
	var result := 1.0 + float(state.samsara) * 0.1
	for upgrade: Dictionary in upgrades:
		if state.upgrades.get(upgrade.id, false) and upgrade.target == "global": result *= float(upgrade.multiplier)
	return result

static func click_multiplier(state: Dictionary, upgrades: Array) -> float:
	var result := global_multiplier(state, upgrades)
	for upgrade: Dictionary in upgrades:
		if state.upgrades.get(upgrade.id, false) and upgrade.target == "click": result *= float(upgrade.multiplier)
	return result

