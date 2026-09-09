class_name JudgementTimingGame
extends Control

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "選擇命運牌後，按 SPACE 逐一鎖定正在發亮的浮文。"

func _process(_delta: float) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 點擊主盤與 Space 的意義相同，讓插畫本體就是操作介面。
		if GameEngine.requires_fate_alignment(): GameEngine.lock_active_rune()
		accept_event()

func _draw() -> void:
	var judgement := GameEngine.get_judgement_state()
	var round := GameEngine.get_constellation_round()
	var center := Vector2(size.x * 0.48, size.y * 0.36)
	var orbit_size := Vector2(size.x * 0.17, size.y * 0.13)
	var route_type := String(round.selected.get("rune_route", "circle"))
	_draw_rune_route(center, orbit_size, route_type)
	for index in int(round.max_runes):
		var locked: bool = index < round.locks.size()
		var angle := float(judgement.phase) * TAU + float(index) * 1.73
		var rune_pos := _rune_position(center, orbit_size, angle, route_type)
		var color := Color("f4c968") if locked else (Color("c8fff1") if index == int(round.active_rune) else Color("8b94b9"))
		draw_circle(rune_pos, 17.0, Color(color, 0.16))
		draw_circle(rune_pos, 7.0, color)

	var orb := Vector2(size.x * 0.48, size.y * (0.22 + float(judgement.phase) * 0.24))
	for trail in 4:
		draw_circle(orb - Vector2(0, (trail + 1) * 11), 10.0 - trail * 1.7, Color(0.32, 0.9, 0.74, 0.12 + trail * 0.04))
	draw_circle(orb, 11.0, Color("d8fff3"))

	# 唯一刻意保留的程式視覺：鎖定造成的半透明預測軌跡。
	var target := Vector2(lerpf(size.x * 0.27, size.x * 0.69, float(round.prediction)), size.y * 0.76)
	draw_dashed_line(orb, target, Color("c8fff1", 0.76), 3.0, 8.0)
	draw_circle(target, 14.0, Color("f2b63f", 0.55))

func _rune_position(center: Vector2, orbit_size: Vector2, angle: float, route_type: String) -> Vector2:
	match route_type:
		"figure_eight": return center + Vector2(sin(angle) * orbit_size.x, sin(angle * 2.0) * orbit_size.y)
		"star":
			var radius := orbit_size.x * (0.70 + 0.30 * cos(angle * 5.0))
			return center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.72)
		_: return center + Vector2(cos(angle) * orbit_size.x, sin(angle) * orbit_size.y)

func _draw_rune_route(center: Vector2, orbit_size: Vector2, route_type: String) -> void:
	var route_color := Color("8d7bff", 0.24)
	if route_type == "circle":
		draw_arc(center, orbit_size.x, 0.0, TAU, 64, route_color, 1.3)
		return
	var points := PackedVector2Array()
	for index in 65:
		var angle := TAU * float(index) / 64.0
		points.append(_rune_position(center, orbit_size, angle, route_type))
	draw_polyline(points, route_color, 1.3, true)
