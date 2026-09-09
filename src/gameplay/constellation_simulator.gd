class_name ConstellationSimulator
extends RefCounted

# Deterministic, replayable peg simulation. It owns only path data; GameEngine owns rewards.
const ROWS := 12
const LEFT_EDGE := 0.23
const RIGHT_EDGE := 0.77
const START := Vector2(0.50, 0.18)
const EXIT_Y := 0.75

static func simulate(seed_value: int, card_bias: float, rune_push: float, precision: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var position := START
	var velocity_x := clampf(card_bias * 0.46 + rune_push * 0.42 + (precision - 0.5) * 0.12, -0.19, 0.19)
	var path: Array[Vector2] = [position]
	var impacts: Array[Vector2] = []
	for row in ROWS:
		var y := lerpf(0.25, 0.65, float(row) / float(ROWS - 1))
		var spacing := (RIGHT_EDGE - LEFT_EDGE) / float(5 + row % 2)
		var peg_index := clampi(int(round((position.x - LEFT_EDGE) / spacing)), 0, 5 + row % 2)
		var peg := Vector2(LEFT_EDGE + float(peg_index) * spacing, y)
		position.y = y
		# A peg sends the soul left/right. The random impulse is seeded so the same round can replay exactly.
		var impulse := 1.0 if rng.randf() >= 0.5 else -1.0
		var guidance := signf(card_bias + rune_push * 0.8)
		if absf(guidance) > 0.0 and rng.randf() < 0.62 + precision * 0.22:
			impulse = guidance
		velocity_x = clampf(velocity_x * 0.48 + impulse * (0.026 + (1.0 - precision) * 0.012), -0.075, 0.075)
		position.x = clampf(position.x + velocity_x, LEFT_EDGE, RIGHT_EDGE)
		impacts.append(peg)
		path.append(position)
	position.y = EXIT_Y
	position.x = clampf(position.x + velocity_x * 1.4, LEFT_EDGE, RIGHT_EDGE)
	path.append(position)
	var normalized_exit := inverse_lerp(LEFT_EDGE, RIGHT_EDGE, position.x)
	var lane := 0 if normalized_exit < 0.333 else (1 if normalized_exit < 0.666 else 2)
	return {"seed": seed_value, "lane": lane, "path": path, "impacts": impacts, "exit": normalized_exit}
