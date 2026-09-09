class_name PrestigeEngine
extends RefCounted

static func reward(lifetime_karma: float) -> int:
	return int(floor(sqrt(maxf(lifetime_karma, 0.0) / GameConstants.PRESTIGE_KARMA_REQUIREMENT)))

