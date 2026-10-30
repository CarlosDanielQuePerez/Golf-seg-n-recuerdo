class_name PauseMenu
extends CanvasLayer
# Menú de pausa (Esc). Funciona con el juego pausado (process_mode = Always).

@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var mute_button: Button = %MuteButton


func _ready() -> void:
	hide()
	continue_button.pressed.connect(close)
	restart_button.pressed.connect(GameManager.restart_level)
	menu_button.pressed.connect(GameManager.go_to_menu)
	for button in [continue_button, restart_button, menu_button, mute_button]:
		GameManager.add_click_sound(button)
	
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_button.pressed.connect(_on_mute_pressed)


func open() -> void:
	show()
	get_tree().paused = true
	_update_audio_ui()
	continue_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_volume_changed(value: float) -> void:
	GameManager.set_music_volume(value)
	if GameManager.music_muted and value > 0:
		GameManager.set_music_muted(false)
	_update_audio_ui()


func _on_mute_pressed() -> void:
	GameManager.set_music_muted(not GameManager.music_muted)
	_update_audio_ui()


func _update_audio_ui() -> void:
	volume_slider.value = GameManager.music_volume
	volume_value.text = "%d%%" % int(GameManager.music_volume)
	mute_button.text = "Activar" if GameManager.music_muted else "Silenciar"


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
