extends Control
# Menú de selección de nivel. Los botones están en la escena (menu.tscn);
# aquí solo se les pone el texto, el mejor puntaje y la acción.

const LEVELS := [
	{"title": "Nivel 1  ·  Charco", "path": "res://level1.tscn"},
	{"title": "Nivel 2  ·  Derecha a Izquierda", "path": "res://level2.tscn"},
	{"title": "Nivel 3  ·  Arriba y Abajo", "path": "res://level3.tscn"},
]

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://scores.cfg")
	for i in LEVELS.size():
		var button: Button = $Levels.get_child(i)
		var best: int = cfg.get_value("best", "level_%d" % (i + 1), 0)
		var best_text := "   (mejor: %d)" % best if best > 0 else ""
		button.text = LEVELS[i]["title"] + best_text
		button.pressed.connect(_play.bind(LEVELS[i]["path"]))
	$Levels.get_child(0).grab_focus()

func _exit_tree() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("scores.cfg"):
		dir.remove("scores.cfg")

func _play(path: String) -> void:
	get_tree().change_scene_to_file(path)
