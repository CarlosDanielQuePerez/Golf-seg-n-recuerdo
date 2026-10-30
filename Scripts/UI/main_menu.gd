extends Control
# Menú principal: selección de niveles (desbloqueo progresivo), sensibilidad y volumen de música.

const LEVEL_BUTTON := preload("res://UI/level_button.tscn")

@onready var levels: VBoxContainer = %Levels
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var mute_button: Button = %MuteButton
@onready var quit_button: Button = %QuitButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	for level_id in range(1, GameManager.level_count() + 1):
		var row := LEVEL_BUTTON.instantiate()
		levels.add_child(row)
		row.setup(level_id)
	
	# Sensibilidad del ratón
	sensitivity_slider.min_value = GameManager.MIN_SENSITIVITY
	sensitivity_slider.max_value = GameManager.MAX_SENSITIVITY
	sensitivity_slider.value = GameManager.mouse_sensitivity
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_update_sensitivity_label()

	# Controles de música
	volume_slider.value = GameManager.music_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_button.pressed.connect(_on_mute_pressed)
	GameManager.add_click_sound(mute_button)
	GameManager.add_click_sound(quit_button)
	_apply_audio_settings()

	quit_button.pressed.connect(get_tree().quit)
	levels.get_child(GameManager.unlocked_level - 1).get_node("Button").grab_focus()


func _on_sensitivity_changed(value: float) -> void:
	GameManager.set_mouse_sensitivity(value)
	_update_sensitivity_label()


func _update_sensitivity_label() -> void:
	sensitivity_value.text = "%.1fx" % GameManager.mouse_sensitivity


func _on_volume_changed(value: float) -> void:
	GameManager.set_music_volume(value)
	if GameManager.music_muted and value > 0:
		GameManager.set_music_muted(false)
	_apply_audio_settings()


func _on_mute_pressed() -> void:
	GameManager.set_music_muted(not GameManager.music_muted)
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	volume_value.text = "%d%%" % int(GameManager.music_volume)
	if GameManager.music_muted or GameManager.music_volume <= 0.0:
		music_player.volume_db = -80.0
		mute_button.text = "Activar"
	else:
		# Convertimos volumen porcentual (0 a 100) a decibelios con margen de -6 dB
		var linear: float = (GameManager.music_volume / 100.0) * 0.5
		music_player.volume_db = linear_to_db(linear)
		mute_button.text = "Silenciar"
