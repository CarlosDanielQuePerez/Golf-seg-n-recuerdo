extends Node3D
## Ibis blanco: patrulla en línea, círculo u ocho. Si toca la bomba le da un
## empujón corto proporcional a su velocidad. No quita tiempo.

const U = preload("res://scripts/unicaribe.gd")
const B = preload("res://scripts/build.gd")

var level
var mode := "line"          # "line" | "circle" | "eight"
var a := Vector3.ZERO       # línea: inicio
var b := Vector3.ZERO       # línea: fin
var center := Vector3.ZERO
var radius := 2.5
var period := 6.0
var phase := 0.0
var _t := 0.0
var _cd := 0.0
var _parts: Dictionary
var _prev := Vector3.ZERO


func _ready() -> void:
	_parts = U.ibis(self)
	_t = phase
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.55
	sh.height = 1.2
	cs.shape = sh
	cs.position = Vector3(0, 0.6, 0)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)
	position = _pos(_t)
	_prev = position


func _pos(t: float) -> Vector3:
	var w := t / period * TAU
	match mode:
		"circle":
			return center + Vector3(cos(w), 0, sin(w)) * radius
		"eight":
			return center + Vector3(sin(w) * radius, 0, sin(2.0 * w) * radius * 0.5)
	return a.lerp(b, 0.5 - 0.5 * cos(w))


func _physics_process(delta: float) -> void:
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	position = _pos(_t)
	var v := position - _prev
	if v.length() > 0.0005:
		rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), 0.2)
	_prev = position
	# caminar: patitas y cabeceo
	var k := _t * 9.0
	var legs: Array = _parts.legs
	(legs[0] as Node3D).rotation.x = sin(k) * 0.5
	(legs[1] as Node3D).rotation.x = -sin(k) * 0.5
	(_parts.head as Node3D).position.z = 0.45 + sin(k) * 0.05


func _on_body(body: Node) -> void:
	if level == null or body != level.ball or _cd > 0.0:
		return
	if not (level.state in [0, 1]):
		return
	_cd = 0.6
	var bp: Vector3 = level.ball.global_position
	var dir := Vector3(bp.x - global_position.x, 0, bp.z - global_position.z)
	if dir.length() < 0.01:
		dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	dir = dir.normalized()
	var sp: float = level.ball.linear_velocity.length()
	var push := clampf(sp * 0.35, 1.2, 3.5)   # empujón corto según la velocidad de la bomba
	level.ball.linear_velocity += dir * push + level.up_dir() * 0.6
	if level.state == 0:
		level.state = 1
		level.moving_time = 0.0
	Sfx.play("hop", 0.1, -6.0, 1.8)
	B.burst(level, bp + Vector3.UP * 0.3, Color(1, 1, 1), 10, 2.0, -3.0, 0.06, 0.6)
	var body_n: Node3D = _parts.body
	var tw := create_tween()
	tw.tween_property(body_n, "rotation:x", 0.5, 0.08)
	tw.tween_property(body_n, "rotation:x", 0.0, 0.2)
	if randf() < 0.3:
		B.floating_text(level, global_position + Vector3.UP * 1.6, ["¡Permiso!", "*graznido*", "Voy tarde"].pick_random(), Color(1, 1, 1), 60)
