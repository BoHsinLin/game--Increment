class_name ConstellationSimulator
extends RefCounted

# 每一個釘位都對應 cosmic_gameplay_hud_v1 的實際金色彈珠釘。
# 路徑終點是三座門的門心，避免光球穿過背景或掉進下方卡框。
const START := Vector2(0.50, 0.155)
const GATES := [Vector2(0.390, 0.615), Vector2(0.500, 0.615), Vector2(0.610, 0.615)]
const PEG_ROWS := [
	[Vector2(0.347, 0.207), Vector2(0.441, 0.207), Vector2(0.500, 0.207), Vector2(0.558, 0.207), Vector2(0.652, 0.207)],
	[Vector2(0.407, 0.253), Vector2(0.468, 0.253), Vector2(0.530, 0.253), Vector2(0.592, 0.253)],
	[Vector2(0.367, 0.294), Vector2(0.430, 0.294), Vector2(0.500, 0.294), Vector2(0.570, 0.294), Vector2(0.633, 0.294)],
	[Vector2(0.397, 0.337), Vector2(0.458, 0.337), Vector2(0.542, 0.337), Vector2(0.603, 0.337)],
	[Vector2(0.343, 0.377), Vector2(0.420, 0.377), Vector2(0.480, 0.377), Vector2(0.520, 0.377), Vector2(0.580, 0.377), Vector2(0.657, 0.377)],
	[Vector2(0.428, 0.420), Vector2(0.475, 0.420), Vector2(0.525, 0.420), Vector2(0.572, 0.420)]
]

static func simulate(seed_value: int, card_bias: float, rune_push: float, precision: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var position := START
	var velocity_x := clampf(card_bias * 0.045 + rune_push * 0.040, -0.045, 0.045)
	var path: Array[Vector2] = [position]
	var impacts: Array[Vector2] = []
	for row: Array in PEG_ROWS:
		var peg := _nearest_peg(row, position.x + velocity_x)
		# 先碰到插畫中真正存在的金色釘位，再從釘位彈離。
		path.append(peg)
		impacts.append(peg)
		var impulse := 1.0 if rng.randf() >= 0.5 else -1.0
		var guidance := signf(card_bias + rune_push * 0.8)
		if absf(guidance) > 0.0 and rng.randf() < 0.58 + precision * 0.25:
			impulse = guidance
		velocity_x = clampf(velocity_x * 0.42 + impulse * (0.018 + (1.0 - precision) * 0.012), -0.050, 0.050)
		position = Vector2(clampf(peg.x + velocity_x, 0.335, 0.665), peg.y + 0.024)
		path.append(position)
	var lane_position := clampf(position.x + velocity_x * 1.5 + card_bias * 0.07 + rune_push * 0.06, 0.35, 0.65)
	var lane := clampi(int(round(inverse_lerp(0.35, 0.65, lane_position) * 2.0)), 0, 2)
	path.append(GATES[lane])
	return {"seed": seed_value, "lane": lane, "path": path, "impacts": impacts, "exit": GATES[lane]}

static func _nearest_peg(row: Array, x: float) -> Vector2:
	var nearest: Vector2 = row[0]
	for candidate: Vector2 in row:
		if absf(candidate.x - x) < absf(nearest.x - x): nearest = candidate
	return nearest
