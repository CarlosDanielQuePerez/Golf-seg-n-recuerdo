extends Control
# Menú principal: selección de niveles (desbloqueo progresivo) y sensibilidad del ratón.

const LEVEL_BUTTON := preload("res://UI/level_button.tscn")

@onready var levels: VBoxContainer = %Levels
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	for level_id in range(1, GameManager.level_count() + 1):
		var row := LEVEL_BUTTON.instantiate()
		levels.add_child(row)
		row.setup(level_id)
	sensitivity_slider.min_value = GameManager.MIN_SENSITIVITY
	sensitivity_slider.max_value = GameManager.MAX_SENSITIVITY
	sensitivity_slider.value = GameManager.mouse_sensitivity
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_update_sensitivity_label()
	quit_button.pressed.connect(get_tree().quit)
	levels.get_child(GameManager.unlocked_level - 1).get_node("Button").grab_focus()


func _on_sensitivity_changed(value: float) -> void:
	GameManager.set_mouse_sensitivity(value)
	_update_sensitivity_label()


func _update_sensitivity_label() -> void:
	sensitivity_value.text = "%.1fx" % GameManager.mouse_sensitivity
