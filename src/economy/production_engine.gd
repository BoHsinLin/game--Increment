class_name ProductionEngine
extends RefCounted

static func rates(state: Dictionary, generators: Array, upgrades: Array) -> Dictionary:
	var processing := 0.0
	var karma := 0.0
	var global := ModifierEngine.global_multiplier(state, upgrades)
	for config: Dictionary in generators:
		var owned: int = state.generators.get(config.id, 0)
		var multiplier := ModifierEngine.generator_multiplier(state, config, upgrades) * global
		processing += float(config.soul_processing) * owned * multiplier
		karma += float(config.karma_production) * owned * multiplier
	return {"processing": processing, "karma": karma}

