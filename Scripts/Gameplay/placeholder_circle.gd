@tool
class_name PlaceholderCircle
extends Node2D
# Círculo de relleno mientras no haya arte. Ocúltalo o bórralo cuando haya un sprite.

@export var radius := 6.0:
	set(value):
		radius = value
		queue_redraw()
@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()
@export var outline_color := Color(0, 0, 0, 0.5):
	set(value):
		outline_color = value
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 1.0, outline_color)
	draw_circle(Vector2.ZERO, radius, color)
