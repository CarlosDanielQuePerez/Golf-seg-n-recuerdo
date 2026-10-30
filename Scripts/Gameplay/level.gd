class_name Level
extends Node2D
# Script común de todos los niveles.
# Para editar un nivel: pinta Ground y Course, las zonas Sand (arena) y Water (agua),
# pon el tile de la bandera (HOLE_TILE) en Course, mueve Start y ajusta Bounds.
# El tiempo, las estrellas y la física del tiro se ajustan en el Inspector.
# Controles: click izquierdo, arrastrar hacia atrás y soltar. Esc = pausa.

enum State { READY, PLAYING, WON, LOST }

const HOLE_TILE := Vector2i(0, 9)        # tile de la bandera en el tileset
const HOLE_OFFSET := Vector2(0, 7)       # el hoyo queda un poco abajo del centro del tile

@export var level_id := 1

@export_group("Tiempo y estrellas")
@export var time_limit := 30.0           # segundos antes de que explote la bomba
@export var three_star_time := 10.0      # terminar en este tiempo (o menos) da 3 estrellas
@export var two_star_time := 20.0        # terminar en este tiempo (o menos) da 2 estrellas

@export_group("Tiro")
@export var power_scale := 4.0
@export var max_pull := 250.0
@export var min_pull := 5.0              # tiros más cortos que esto no cuentan

@export_group("Hoyo")
@export var hole_radius := 10.0
@export var max_hole_speed := 400.0      # si va más rápido, pasa de largo

@export_group("Cámara")
@export var view_rect := Rect2(0, 0, 1152, 640)   # zona del mundo que llena la pantalla

var state := State.READY
var time_left := 0.0
var hole_pos := Vector2.ZERO
var has_hole := false
var _dragging := false
var _loss_reason := ""

@onready var course: TileMapLayer = $Course
@onready var sand: HazardLayer = $Sand
@onready var water: HazardLayer = $Water
@onready var start: Marker2D = $Start
@onready var bomb: Bomb = $Bomb
@onready var aim_line: Line2D = $AimLine
@onready var camera: Camera2D = $Camera2D
@onready var hud: LevelHUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var victory_screen: VictoryScreen = $VictoryScreen
@onready var defeat_screen: DefeatScreen = $DefeatScreen
@onready var music_player: AudioStreamPlayer = get_node_or_null("MusicPlayer")


func _ready() -> void:
	time_left = time_limit
	_setup_camera()
	_find_hole()
	bomb.position = start.position
	sand.bomb_entered.connect(func(b: Bomb) -> void: b.enter_sand())
	sand.bomb_exited.connect(func(b: Bomb) -> void: b.exit_sand())
	water.bomb_entered.connect(_on_water_entered)
	bomb.explosion_finished.connect(_on_explosion_finished)
	hud.setup(bomb, GameManager.level_title(level_id))
	hud.set_time(time_left)
	_apply_music_settings()
	GameManager.music_settings_changed.connect(_apply_music_settings)


func _setup_camera() -> void:
	var screen := get_viewport_rect().size
	var zoom := minf(screen.x / view_rect.size.x, screen.y / view_rect.size.y)
	camera.zoom = Vector2(zoom, zoom)
	camera.position = view_rect.get_center()


func _find_hole() -> void:
	var cells := course.get_used_cells_by_id(0, HOLE_TILE)
	if cells.is_empty():
		push_warning("Nivel %d: falta el tile de la bandera en Course." % level_id)
		return
	hole_pos = to_local(course.to_global(course.map_to_local(cells[0]))) + HOLE_OFFSET
	has_hole = true


func _unhandled_input(event: InputEvent) -> void:
	if state == State.WON or state == State.LOST:
		return
	if event.is_action_pressed("pause"):
		_cancel_aim()
		pause_menu.open()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = not bomb.is_moving()
		elif _dragging:
			var pull := _pull_vector()
			_cancel_aim()
			if pull.length() > min_pull:
				_shoot(pull)


func _pull_vector() -> Vector2:
	var mouse_offset := bomb.position - get_local_mouse_position()
	return (mouse_offset * GameManager.mouse_sensitivity).limit_length(max_pull)


func _cancel_aim() -> void:
	_dragging = false
	aim_line.clear_points()


func _shoot(pull: Vector2) -> void:
	bomb.shoot(pull * power_scale)
	if state == State.READY:
		state = State.PLAYING   # el cronómetro empieza con el primer tiro
		hud.show_hint(false)


func _process(delta: float) -> void:
	if _dragging:
		aim_line.points = PackedVector2Array([bomb.position, bomb.position + _pull_vector()])
	if state == State.PLAYING:
		time_left = maxf(time_left - delta, 0.0)
		hud.set_time(time_left)
		if time_left == 0.0:
			_lose("¡Se acabó el tiempo!")
			bomb.explode()


func _physics_process(_delta: float) -> void:
	if state != State.PLAYING or not has_hole:
		return
	if bomb.position.distance_to(hole_pos) < hole_radius and bomb.velocity.length() < max_hole_speed:
		_win()


func calculate_stars(time_used: float) -> int:
	if time_used <= three_star_time:
		return 3
	if time_used <= two_star_time:
		return 2
	return 1


func _win() -> void:
	state = State.WON
	_cancel_aim()
	bomb.stop()
	bomb.position = hole_pos
	var stars := calculate_stars(time_limit - time_left)
	var new_record := GameManager.complete_level(level_id, stars)
	victory_screen.show_result(level_id, time_left, stars, new_record)


func _lose(reason: String) -> void:
	state = State.LOST
	_cancel_aim()
	_loss_reason = reason


func _on_water_entered(b: Bomb) -> void:
	if state == State.WON or state == State.LOST:
		return
	_lose("¡La bomba cayó al agua!")
	b.explode(true)


func _on_explosion_finished() -> void:
	defeat_screen.show_result(_loss_reason)


func _apply_music_settings() -> void:
	if not music_player:
		return
	if GameManager.music_muted or GameManager.music_volume <= 0.0:
		music_player.volume_db = -80.0
	else:
		var linear: float = (GameManager.music_volume / 100.0) * 0.5
		music_player.volume_db = linear_to_db(linear)
