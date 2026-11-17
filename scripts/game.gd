extends Node
## Estado global: niveles, tiempos, estrellas y opciones. (Autoload "Game")

const TITLE := "Golf, según recuerdo"

## time = segundos de mecha. t3 / t2 = segundos máximos (tiempo usado) para 3 y 2 estrellas.
const LEVELS := [
	{"name": "Hoyo 1: Primer Día", "time": 60.0, "t3": 30.0, "t2": 45.0, "music": "level",
		"intro": "Bienvenido a la Unicaribe. El hoyo llegó tarde... y se va temprano.", "sky": "day"},
	{"name": "Hoyo 2: Camino a la Biblioteca", "time": 75.0, "t3": 35.0, "t2": 55.0, "music": "level",
		"intro": "Cangrejos, abejas y un ibis con prisa.", "sky": "afternoon"},
	{"name": "Hoyo 3: Santuario de Murciélagos", "time": 70.0, "t3": 30.0, "t2": 48.0, "music": "level",
		"intro": "No te quedes en lo oscuro. Los murciélagos te están viendo.", "sky": "cave"},
	{"name": "Hoyo 4: El Manglar", "time": 120.0, "t3": 55.0, "t2": 85.0, "music": "level",
		"intro": "Agua, raíces y un águila que confunde bombas con pescados.", "sky": "mangrove"},
	{"name": "Hoyo 5: SIGMAA (Jefe Final)", "time": 180.0, "t3": 85.0, "t2": 130.0, "music": "final",
		"intro": "", "sky": "sigmaa"},
]

const BOMB_COLORS := {
	"Clásica": Color(0.12, 0.12, 0.14),
	"Roja": Color(0.6, 0.08, 0.08),
	"Azul": Color(0.1, 0.2, 0.55),
	"Verde militar": Color(0.25, 0.32, 0.15),
	"Dorada": Color(0.85, 0.65, 0.15),
}

## Hoyos jugables por ahora (el 5, el jefe, está en construcción).
const PLAYABLE := 5

const PENALTY := 5.0     # segundos que cuesta caer al agua, lava o al vacío
const CLOCK_BONUS := 5.0  # segundos que da cada reloj

const SAVE_PATH := "user://golf_segun_recuerdo.cfg"

var current := 0
var in_run := false
var run_stars: Array = [0, 0, 0, 0, 0]
var run_times: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var run_strokes: Array = [0, 0, 0, 0, 0]
var best_stars: Array = [-1, -1, -1, -1, -1]   # -1 = sin jugar
var best_time: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var stats := {"crocs": 0, "voids": 0, "melted": 0, "booms": 0, "iguanas": 0, "bees": 0, "bats": 0, "eagles": 0}
var settings := {
	"music": 0.6, "sfx": 0.9, "shake": true, "fullscreen": false, "bomb": "Clásica",
}


func _ready() -> void:
	load_data()
	apply_settings()


func new_run() -> void:
	in_run = true
	run_stars = [0, 0, 0, 0, 0]
	run_times = [0.0, 0.0, 0.0, 0.0, 0.0]
	run_strokes = [0, 0, 0, 0, 0]


static func stars_for(level: int, used: float, exploded := false) -> int:
	if exploded:
		return 0
	var lv: Dictionary = LEVELS[level]
	if used <= lv.t3:
		return 3
	if used <= lv.t2:
		return 2
	return 1


func record(level: int, stars: int, used: float, strokes: int) -> void:
	if in_run:
		run_stars[level] = stars
		run_times[level] = used
		run_strokes[level] = strokes
	if stars > best_stars[level] or (stars == best_stars[level] and stars > 0 and used < best_time[level]):
		best_stars[level] = stars
		best_time[level] = used if stars > 0 else 0.0
	save_data()


func total_stars(arr: Array) -> int:
	var t := 0
	for i in mini(arr.size(), PLAYABLE):
		t += maxi(0, arr[i])
	return t


func animal_catches() -> int:
	return stats.crocs + stats.iguanas + stats.bees + stats.bats + stats.eagles


func bomb_color() -> Color:
	return BOMB_COLORS.get(settings.bomb, BOMB_COLORS["Clásica"])


static func fmt_time(sec: float) -> String:
	sec = maxf(sec, 0.0)
	return "%d:%04.1f" % [int(sec) / 60, fmod(sec, 60.0)]


func apply_settings() -> void:
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if has_node("/root/Sfx"):
		get_node("/root/Sfx").set_volumes(settings.music, settings.sfx)


func save_data() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.set_value("progress", "best_stars", best_stars)
	cfg.set_value("progress", "best_time", best_time)
	cfg.set_value("progress", "stats", stats)
	cfg.save(SAVE_PATH)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for k in settings:
		settings[k] = cfg.get_value("settings", k, settings[k])
	if not BOMB_COLORS.has(settings.bomb):
		settings.bomb = "Clásica"
	var b = cfg.get_value("progress", "best_stars", best_stars)
	if b is Array and b.size() == 5:
		best_stars = b
	var bt = cfg.get_value("progress", "best_time", best_time)
	if bt is Array and bt.size() == 5:
		best_time = bt
	var s = cfg.get_value("progress", "stats", stats)
	if s is Dictionary:
		for k in stats:
			stats[k] = s.get(k, 0)
