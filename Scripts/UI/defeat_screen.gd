class_name DefeatScreen
extends CanvasLayer
# Pantalla de derrota (Game Over). La transición de entrada es la animación "show".

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var reason_label: Label = %ReasonLabel
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	menu_button.pressed.connect(GameManager.go_to_menu)
	GameManager.add_click_sound(menu_button)


func show_result(reason: String) -> void:
	reason_label.text = reason
	show()
	animation_player.play("show")
	menu_button.grab_focus()
