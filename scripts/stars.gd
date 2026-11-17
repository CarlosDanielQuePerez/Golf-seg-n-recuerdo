extends Control
## Fila de estrellas dibujadas a mano (la fuente no trae el símbolo ★).

var count := 3
var filled := 0
var star_size := 40.0
var _shown: Array = []   # escala animada de cada estrella


func setup(filled_: int, size_ := 40.0, animate := false) -> void:
	filled = filled_
	star_size = size_
	custom_minimum_size = Vector2(count * size_ * 1.15, size_ * 1.1)
	_shown = []
	for i in count:
		_shown.append(0.0 if animate else 1.0)
	queue_redraw()
	if animate:
		_pop()


func _pop() -> void:
	for i in count:
		await get_tree().create_timer(0.35, true, false, true).timeout
		if not is_inside_tree():
			return
		if i < filled:
			Sfx.play("pickup", 0.0, -4.0, 1.0 + i * 0.15)
		var tw := create_tween()
		tw.tween_method(func(v: float):
			_shown[i] = v
			queue_redraw(), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _star_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * PI / 5
		var rr := r if k % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


func _draw() -> void:
	for i in count:
		var s: float = _shown[i] if i < _shown.size() else 1.0
		if s <= 0.01:
			continue
		var c := Vector2(star_size * 0.575 + i * star_size * 1.15, size.y * 0.5)
		var r := star_size * 0.5 * s
		var on := i < filled
		var pts := _star_points(c + Vector2(0, 3), r)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
		pts = _star_points(c, r)
		draw_colored_polygon(pts, Color(1, 0.82, 0.15) if on else Color(0.3, 0.28, 0.38))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(0.25, 0.12, 0.05) if on else Color(0.15, 0.12, 0.2), maxf(2.0, star_size * 0.07), true)
		if on:
			draw_colored_polygon(_star_points(c + Vector2(-r * 0.12, -r * 0.12), r * 0.35), Color(1, 1, 0.75, 0.6))
