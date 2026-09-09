class_name SoulDropOverlay
extends Control

signal finished

const DROP_DURATION := 1.55

var _elapsed := 0.0
var _route: Array[Vector2] = []
var _active := false
var _impacts: Array[Vector2] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func start(result: Dictionary) -> void:
	_route.clear()
	for point: Variant in result.get("peg_path", []): _route.append(point)
	_impacts.clear()
	for point: Variant in result.get("peg_impacts", []): _impacts.append(point)
	if _route.is_empty(): return
	_elapsed = 0.0
	_active = true
	queue_redraw()

func _process(delta: float) -> void:
	if not _active: return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= DROP_DURATION:
		_active = false
		finished.emit()
		queue_free()

func _draw() -> void:
	if not _active or _route.is_empty(): return
	# 光點與衝擊波疊在生成彈盤上，讓路徑的結果可讀。
	for point in _impacts:
		var impact := point * size
		draw_circle(impact, 9.0, Color("f2c663", 0.16))
		draw_circle(impact, 3.0, Color("f2c663", 0.75))
	var normalized := _position_at(clampf(_elapsed / DROP_DURATION, 0.0, 1.0))
	var orb := normalized * size
	for trail in 5:
		draw_circle(orb - Vector2(0, float(trail + 1) * 11.0), 10.0 - float(trail) * 1.5, Color(0.31, 0.92, 0.76, 0.08 + float(trail) * 0.035))
	draw_circle(orb, 15.0, Color("73ffe0", 0.25))
	draw_circle(orb, 9.0, Color("e6fff7"))
	if _elapsed > DROP_DURATION * 0.84:
		draw_circle(_route.back() * size, 38.0, Color("f2c663", 0.16))

func _position_at(progress: float) -> Vector2:
	var scaled := progress * float(_route.size() - 1)
	var segment := mini(int(floor(scaled)), _route.size() - 2)
	var local := scaled - float(segment)
	# 快入慢出保留碰撞的重量感。
	local = ease(local, 0.72)
	return _route[segment].lerp(_route[segment + 1], local)
