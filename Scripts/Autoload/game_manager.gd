extends Node
# Autoload "GameManager": lista de niveles, progreso guardado, ajustes y cambio de escenas.
# El progreso se guarda en user://save.cfg y se conserva al cerrar el juego.

const SAVE_PATH := "user://save.cfg"
const MAIN_MENU := "res://UI/main_menu.tscn"
const LEVELS := [
	{"name": "El estanque", "path": "res://Scenes/Levels/level1.tscn"},
	{"name": "La serpiente", "path": "res://Scenes/Levels/level2.tscn"},
	{"name": "El slalom", "path": "res://Scenes/Levels/level3.tscn"},
	{"name": "", "path": "res://Scenes/Levels/level4.tscn"},
	{"name": "", "path": "res://Scenes/Levels/level5.tscn"},
]
const MIN_SENSITIVITY := 0.5
const MAX_SENSITIVITY := 2.0

var unlocked_level := 1          # nivel más alto que se puede jugar
var best_stars := {}             # level_id -> mejor número de estrellas (1 a 3)
var mouse_sensitivity := 1.0     # multiplica la distancia del ratón al calcular la fuerza

@onready var ui_click_sound: AudioStreamPlayer = $UIClickSound


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	load_game()


# --- Niveles ---------------------------------------------------------------

func level_count() -> int:
	return LEVELS.size()


func level_title(level_id: int) -> String:
	var level_name: String = LEVELS[level_id - 1]["name"]
	if level_name.is_empty():
		return "Nivel %d" % level_id
	return "Nivel %d: %s" % [level_id, level_name]


func is_unlocked(level_id: int) -> bool:
	return level_id <= unlocked_level


func has_next_level(level_id: int) -> bool:
	return level_id < level_count()


func get_best_stars(level_id: int) -> int:
	return best_stars.get(level_id, 0)


# Registra la victoria, desbloquea el siguiente nivel y guarda.
# Devuelve true si es un nuevo récord de estrellas.
func complete_level(level_id: int, stars: int) -> bool:
	var new_record := stars > get_best_stars(level_id)
	if new_record:
		best_stars[level_id] = stars
	unlocked_level = maxi(unlocked_level, mini(level_id + 1, level_count()))
	save_game()
	return new_record


# --- Navegación ------------------------------------------------------------

func go_to_level(level_id: int) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVELS[level_id - 1]["path"])


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- Ajustes ---------------------------------------------------------------

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, MIN_SENSITIVITY, MAX_SENSITIVITY)
	save_game()


# --- Sonido de interfaz ----------------------------------------------------

func play_ui_click() -> void:
	if ui_click_sound.stream:
		ui_click_sound.play()


func add_click_sound(button: BaseButton) -> void:
	button.pressed.connect(play_ui_click)


# --- Guardado --------------------------------------------------------------

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	for level_id in best_stars:
		cfg.set_value("best_stars", "level_%d" % level_id, best_stars[level_id])
	cfg.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_level = clampi(cfg.get_value("progress", "unlocked_level", 1), 1, level_count())
	best_stars.clear()
	for level_id in range(1, level_count() + 1):
		var stars: int = cfg.get_value("best_stars", "level_%d" % level_id, 0)
		if stars > 0:
			best_stars[level_id] = clampi(stars, 1, 3)
	mouse_sensitivity = clampf(cfg.get_value("settings", "mouse_sensitivity", 1.0),
			MIN_SENSITIVITY, MAX_SENSITIVITY)
