class_name PauseMenu
extends CanvasLayer
# Menú de pausa (Esc). Funciona con el juego pausado (process_mode = Always).

@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	continue_button.pressed.connect(close)
	restart_button.pressed.connect(GameManager.restart_level)
	menu_button.pressed.connect(GameManager.go_to_menu)
	for button in [continue_button, restart_button, menu_button]:
		GameManager.add_click_sound(button)


func open() -> void:
	show()
	get_tree().paused = true
	continue_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
