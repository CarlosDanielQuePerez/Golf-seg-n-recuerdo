extends Node3D
## Águila pescadora.
##  - "perch": parada en un poste, aletea con pausas y su ráfaga empuja la bomba.
##  - "diver": vuela en círculos; marca un punto rojo y baja en picada. Si atrapa la bomba, se la lleva.

const U = preload("res://scripts/unicaribe.gd")
const B = preload("res://scripts/build.gd")

var level
var mode := "perch"
var gust := Vector3(7, 0, 0)       # perch: fuerza del aleteo
var gust_zone: Area3D              # perch: zona de viento que controla
var area := Rect2()                # diver: zona del suelo donde puede atacar (x, z)
var ground_y := 0.0
var _parts: Dictionary
var _t := 0.0
var _busy := false
var _cd := 6.0
var _leaves: CPUParticles3D


func _ready() -> void:
	_parts = U.osprey(self)
	if mode == "perch":
		_leaves = CPUParticles3D.new()
		_leaves.amount = 30
		_leaves.lifetime = 1.0
		_leaves.mesh = B.box_mesh(Vector3(0.15, 0.02, 0.08))
		_leaves.material_override = B.mat(Color(0.35, 0.65, 0.3))
		_leaves.direction = gust.normalized()
		_leaves.spread = 12
		_leaves.gravity = Vector3.ZERO
		_leaves.initial_velocity_min = 7
		_leaves.initial_velocity_max = 10
		_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_leaves.emission_sphere_radius = 1.0
		_leaves.emitting = false
		_leaves.local_coords = false
		_leaves.position = Vector3(0, -0.6, 0)
		add_child(_leaves)


func _flap(speed: float, amount: float) -> void:
	var w: Array = _parts.wings
	var k := sin(_t * speed) * amount
	(w[0] as Node3D).rotation.z = k
	(w[1] as Node3D).rotation.z = -k


func _physics_process(delta: float) -> void:
	_t += delta
	if mode == "perch":
		# ciclo: 2.5 s en calma, 1.6 s aleteando fuerte
		var c := fmod(_t, 4.1)
		var on := c > 2.5
		gust_zone.set_meta("force", gust if on else Vector3.ZERO)
		_leaves.emitting = on
		_flap(22.0 if on else 3.0, 0.9 if on else 0.1)
		if on and c - delta <= 2.5:
			Sfx.play("whoosh", 0.1, -2.0, 0.7)
		return
	if _busy or level == null:
		return
	# vuelo en círculos
	var w := _t * 0.6
	position = Vector3(area.get_center().x + cos(w) * 6.0, ground_y + 9.0, area.get_center().y + sin(w) * 6.0)
	rotation.y = atan2(-sin(w), cos(w)) + PI
	_flap(6.0, 0.4)
	_cd -= delta
	if _cd > 0.0 or not (level.state in [0, 1]):
		return
	var bp: Vector3 = level.ball.global_position
	if area.has_point(Vector2(bp.x, bp.z)) and absf(bp.y - ground_y) < 1.0:
		_dive(Vector3(bp.x, ground_y, bp.z))


func _dive(target: Vector3) -> void:
	_busy = true
	_cd = randf_range(8.0, 11.0)
	# sombra roja que crece: avisa dónde va a caer
	var mark := StandardMaterial3D.new()
	mark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark.albedo_color = Color(1, 0.15, 0.1, 0.35)
	var shadow := B.add_mesh(level, B.cyl_mesh(1.3, 1.3, 0.02, 24), mark, target + Vector3(0, 0.04, 0))
	shadow.scale = Vector3(0.2, 1, 0.2)
	var tw := create_tween()
	tw.tween_property(shadow, "scale", Vector3.ONE, 1.5)
	Sfx.play("squeak", 0.1, -4.0, 1.4)
	B.floating_text(level, target + Vector3.UP * 2.0, "¡¿PESCADO?!", Color(1, 0.5, 0.4), 80)
	await tw.finished
	var from := global_position
	tw = create_tween()
	tw.tween_property(self, "global_position", target + Vector3(0, 0.5, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	shadow.queue_free()
	Sfx.play("splash", 0.1, -6.0, 1.3)
	B.burst(level, target, Color(0.8, 0.9, 0.8), 16, 4.0, -9.0, 0.08, 0.6)
	var bp: Vector3 = level.ball.global_position
	if Vector2(bp.x - target.x, bp.z - target.z).length() < 1.3 and level.try_capture():
		Game.stats.eagles += 1
		var ball: Node3D = level.ball
		var away := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 25.0 + Vector3(0, 14, 0)
		var start := global_position
		tw = create_tween()
		tw.tween_method(_carry_step.bind(start, away, ball), 0.0, 1.0, 1.3).set_trans(Tween.TRANS_SINE)
		_flap(20.0, 0.9)
		await tw.finished
		level.finish_capture("¡PESCADA!", "El águila pescadora confundió tu bomba con un pescado.", Color(0.6, 0.85, 1.0))
		global_position = from
	else:
		tw = create_tween()
		tw.tween_property(self, "global_position", from, 0.8).set_trans(Tween.TRANS_SINE)
		await tw.finished
	_busy = false


func _carry_step(k: float, start: Vector3, away: Vector3, ball: Node3D) -> void:
	global_position = start.lerp(start + away, k)
	ball.global_position = global_position + Vector3(0, -0.45, 0)
