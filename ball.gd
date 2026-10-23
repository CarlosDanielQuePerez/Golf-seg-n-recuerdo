@tool
extends CharacterBody2D
# Solo dibuja la bola (la lógica está en level.gd)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.2, 0.2, 0.5))
	draw_circle(Vector2.ZERO, 5.0, Color.WHITE)
