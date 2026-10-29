class_name VictoryScreen
extends CanvasLayer
# Pantalla de victoria: tiempo restante, estrellas y botones Siguiente nivel / Menú.
# La transición de entrada es la animación "show" de $AnimationPlayer.

var _level_id := 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var time_label: Label = %TimeLabel
@onready var record_label: Label = %RecordLabel
@onready var star_icons: Array[Node] = %Stars.get_children()
@onready var next_button: Button = %NextButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	next_button.pressed.connect(func() -> void: GameManager.go_to_level(_level_id + 1))
	menu_button.pressed.connect(GameManager.go_to_menu)
	GameManager.add_click_sound(next_button)
	GameManager.add_click_sound(menu_button)


func show_result(level_id: int, time_left: float, stars: int, new_record: bool) -> void:
	_level_id = level_id
	time_label.text = "Tiempo restante: %.1f s" % time_left
	for i in star_icons.size():
		star_icons[i].filled = i < stars
	record_label.visible = new_record
	next_button.visible = GameManager.has_next_level(level_id)
	show()
	animation_player.play("show")
	(next_button if next_button.visible else menu_button).grab_focus()
