@tool
class_name StarIcon
extends Control
# Estrella de placeholder. Para usar arte, asigna texture_filled y texture_empty.

@export var filled := true:
	set(value):
		filled = value
		queue_redraw()
@export var texture_filled: Texture2D:
	set(value):
		texture_filled = value
		queue_redraw()
@export var texture_empty: Texture2D:
	set(value):
		texture_empty = value
		queue_redraw()
@export var color_filled := Color(1, 0.85, 0.2)
@export var color_empty := Color(0.3, 0.3, 0.35)


func _draw() -> void:
	var texture := texture_filled if filled else texture_empty
	if texture:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color_filled if filled else color_empty)
