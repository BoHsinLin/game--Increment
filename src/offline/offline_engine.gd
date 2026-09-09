class_name OfflineEngine
extends RefCounted

static func calculate(state: Dictionary, generators: Array, upgrades: Array, elapsed: float) -> Dictionary:
	var seconds := minf(maxf(elapsed, 0.0), GameConstants.MAX_OFFLINE_SECONDS)
	var rates := ProductionEngine.rates(state, generators, upgrades)
	var incoming := GameEngine.incoming_souls_per_second_for_state(state)
	var processable := minf(float(state.souls) + incoming * seconds, rates.processing * seconds)
	var ratio := processable / maxf(rates.processing * seconds, 1.0)
	return {
		"seconds": seconds,
		"souls_incoming": incoming * seconds,
		"souls_processed": processable * GameConstants.OFFLINE_EFFICIENCY,
		"karma": rates.karma * seconds * ratio * GameConstants.OFFLINE_EFFICIENCY
	}

