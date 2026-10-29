class_name LevelHUD
extends CanvasLayer
# HUD de la partida: nombre del nivel, indicación inicial y el cronómetro que sigue a la bomba.

@export var timer_offset := Vector2(0, -44)   # posición del cronómetro respecto a la bomba (en pantalla)

var _bomb: Node2D

@onready var level_label: Label = $LevelLabel
@onready var hint_label: Label = $HintLabel
@onready var bomb_timer: Label = $BombTimer


func setup(bomb: Node2D, title: String) -> void:
	_bomb = bomb
	level_label.text = title


func set_time(seconds: float) -> void:
	bomb_timer.text = "%.1f" % seconds


func show_hint(value: bool) -> void:
	hint_label.visible = value


func _process(_delta: float) -> void:
	if _bomb:
		var screen_pos := _bomb.get_global_transform_with_canvas().origin
		bomb_timer.position = screen_pos + timer_offset - bomb_timer.size / 2.0
