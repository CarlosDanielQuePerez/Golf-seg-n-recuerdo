extends Node
## Controla qué se muestra: menú, hoyos o tarjeta final (con transición en fundido).

const MenuScript = preload("res://scripts/menu.gd")
const LevelScript = preload("res://scripts/level.gd")
const ScoreScript = preload("res://scripts/scorecard.gd")

var current: Node
var fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	var cl := CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	fade = ColorRect.new()
	fade.color = Color(0.05, 0.02, 0.1, 1.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(fade)
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		var t = load("res://tools/autotest.gd").new()
		t.main = self
		add_child(t)
		return
	show_menu()


func _swap(n: Node) -> void:
	while _busy:
		await get_tree().process_frame
	_busy = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	await tw.finished
	if current:
		current.queue_free()
		await get_tree().process_frame
	current = n
	n.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(n)
	tw = create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.35)
	await tw.finished
	_busy = false


func show_menu() -> void:
	Game.in_run = false
	var m = MenuScript.new()
	m.main = self
	_swap(m)


func start_run() -> void:
	Game.new_run()
	start_level(0)


func start_level(i: int) -> void:
	Game.current = i
	var l = LevelScript.new()
	l.level_index = i
	l.main = self
	_swap(l)


func level_finished(i: int) -> void:
	if i < Game.PLAYABLE - 1:
		start_level(i + 1)
	elif Game.in_run:
		var s = ScoreScript.new()
		s.main = self
		_swap(s)
	else:
		show_menu()
