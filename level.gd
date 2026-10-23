@tool
extends Node2D
# Script compartido por todos los niveles.
# Edita cada nivel pintando en las capas Ground, Course, Sand y Water.
# Controles: click izquierdo + arrastrar hacia atrás + soltar. R reinicia. Esc = menú.

const POWER_SCALE := 4.0
const MAX_PULL := 250.0
const STOP_SPEED := 10.0
const HOLE_RADIUS := 10.0
const MAX_HOLE_SPEED := 400.0
const HOLE_TILE := Vector2i(0, 9)          # tile de la bandera en el tileset
const FRICTION := 0.4                      # fricción normal (menor = frena más)
const SAND_FRICTION := 0.05                # fricción en la arena
const MENU_SCENE := "res://menu.tscn"
const SAVE_PATH := "user://scores.cfg"

@export var level_id := 1                  # se usa para guardar el mejor puntaje

@onready var course: TileMapLayer = $Course
@onready var water: TileMapLayer = $Water
@onready var sand: TileMapLayer = $Sand
@onready var ball: CharacterBody2D = $Ball
@onready var start: Marker2D = $Start
@onready var aim_line: Line2D = $AimLine
@onready var strokes_label: Label = $UI/StrokesLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var back_button: Button = $UI/BackButton

var vel := Vector2.ZERO
var strokes := 0
var dragging := false
var won := false
var last_safe_pos := Vector2.ZERO
var hole_pos := Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	back_button.pressed.connect(go_to_menu)
	# El hoyo está donde pintaste el tile de la bandera (el hoyo queda abajo del tile)
	var cells := course.get_used_cells_by_id(0, HOLE_TILE)
	if cells.size() > 0:
		hole_pos = course.map_to_local(cells[0]) + Vector2(0, 7)
	reset()


func go_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func reset() -> void:
	ball.position = start.position
	last_safe_pos = start.position
	vel = Vector2.ZERO
	strokes = 0
	dragging = false
	won = false
	aim_line.clear_points()
	message_label.text = "Arrastra hacia atrás y suelta para golpear"
	_update_strokes()


func _update_strokes() -> void:
	strokes_label.text = "Golpes: %d" % strokes


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_ESCAPE:
			go_to_menu()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if won:
				reset()
			elif vel == Vector2.ZERO:
				dragging = true
		elif dragging:
			dragging = false
			aim_line.clear_points()
			var pull := _pull_vector()
			if pull.length() > 5.0:
				last_safe_pos = ball.position
				vel = pull * POWER_SCALE
				strokes += 1
				message_label.text = ""
				_update_strokes()


func _pull_vector() -> Vector2:
	return (ball.position - get_global_mouse_position()).limit_length(MAX_PULL)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if dragging:
		aim_line.points = PackedVector2Array([ball.position, ball.position + _pull_vector()])


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or won or vel == Vector2.ZERO:
		return
	var hit := ball.move_and_collide(vel * delta)
	if hit:
		vel = vel.bounce(hit.get_normal()) * 0.8
	# Fricción (más fuerte en la arena)
	var in_sand := sand.get_cell_source_id(sand.local_to_map(ball.position)) != -1
	vel *= pow(SAND_FRICTION if in_sand else FRICTION, delta)
	if vel.length() < STOP_SPEED:
		vel = Vector2.ZERO
	# Agua: vuelve al punto del último golpe (+1 golpe de castigo)
	if water.get_cell_source_id(water.local_to_map(ball.position)) != -1:
		ball.position = last_safe_pos
		vel = Vector2.ZERO
		strokes += 1
		_update_strokes()
		message_label.text = "¡Al agua! +1 golpe"
		return
	# Hoyo
	if ball.position.distance_to(hole_pos) < HOLE_RADIUS and vel.length() < MAX_HOLE_SPEED:
		ball.position = hole_pos
		vel = Vector2.ZERO
		won = true
		var new_record := _save_best()
		message_label.text = "¡HOYO en %d golpes!%s\nClick: reiniciar  ·  Esc: menú" % [
			strokes, "  ¡Nuevo récord!" if new_record else ""]


func _save_best() -> bool:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var key := "level_%d" % level_id
	var best: int = cfg.get_value("best", key, 9999)
	if strokes < best:
		cfg.set_value("best", key, strokes)
		cfg.save(SAVE_PATH)
		return true
	return false
