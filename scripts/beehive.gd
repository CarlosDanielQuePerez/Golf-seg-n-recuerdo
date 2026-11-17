extends Node3D
## Árbol con panal. Si la bomba se queda 3 s en el área amarilla, las abejas se la
## llevan a la colmena. El contador se reinicia al salir del área.

const B = preload("res://scripts/build.gd")

var level
var radius := 3.3
var limit := 3.0
var _t := 0.0
var _busy := false
var hive: Node3D
var swarm: CPUParticles3D
var disc_mat: StandardMaterial3D


func _ready() -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.45
	sh.height = 3.0
	cs.shape = sh
	cs.position = Vector3(0, 1.5, 0)
	sb.add_child(cs)
	add_child(sb)
	var bark := B.mat(Color(0.42, 0.28, 0.16))
	B.add_mesh(self, B.cyl_mesh(0.3, 0.45, 3.0, 10), bark, Vector3(0, 1.5, 0))
	B.add_mesh(self, B.cyl_mesh(0.1, 0.14, 1.6, 6), bark, Vector3(0.7, 2.9, 0), Vector3(0, 0, -0.9))
	for k in 6:
		var a := k * TAU / 6
		B.add_mesh(self, B.sphere_mesh(1.2, 10), B.mat([Color(0.2, 0.55, 0.25), Color(0.16, 0.48, 0.2)][k % 2]), Vector3(cos(a) * 1.1, 4.0 + randf() * 0.5, sin(a) * 1.1))
	B.add_mesh(self, B.sphere_mesh(1.3, 10), B.mat(Color(0.18, 0.5, 0.22)), Vector3(0, 4.6, 0))
	hive = Node3D.new()
	hive.position = Vector3(1.35, 2.55, 0)
	add_child(hive)
	var honey := B.mat(Color(0.95, 0.72, 0.2), 0.5)
	for k in 5:
		B.add_mesh(hive, B.sphere_mesh(0.42 - k * 0.06, 10), honey if k % 2 == 0 else B.mat(Color(0.85, 0.6, 0.15)), Vector3(0, -k * 0.16, 0), Vector3.ZERO, Vector3(1, 0.55, 1))
	B.add_mesh(hive, B.sphere_mesh(0.09, 6), B.mat(Color(0.15, 0.08, 0.02)), Vector3(0, -0.3, 0.33))
	swarm = CPUParticles3D.new()
	swarm.amount = 22
	swarm.lifetime = 1.4
	swarm.mesh = B.sphere_mesh(0.05, 4)
	swarm.material_override = B.mat(Color(1, 0.85, 0.1), 0.6, 0.8)
	swarm.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	swarm.emission_sphere_radius = 0.8
	swarm.gravity = Vector3.ZERO
	swarm.initial_velocity_min = 0.3
	swarm.initial_velocity_max = 1.0
	swarm.spread = 180
	swarm.local_coords = true
	hive.add_child(swarm)
	disc_mat = StandardMaterial3D.new()
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color = Color(1, 0.85, 0.1, 0.15)
	var disc := B.add_mesh(self, B.cyl_mesh(radius, radius, 0.02, 32), disc_mat, Vector3(0, 0.03, 0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.06
	ring.outer_radius = radius
	B.add_mesh(self, ring, B.mat(Color(1, 0.85, 0.1), 0.5, 1.5), Vector3(0, 0.04, 0))


func _physics_process(delta: float) -> void:
	if level == null or _busy:
		return
	var bp: Vector3 = level.ball.global_position
	var flat := Vector3(bp.x - global_position.x, 0, bp.z - global_position.z)
	var inside: bool = flat.length() < radius and absf(bp.y - global_position.y) < 2.0 and level.state in [0, 1]
	if not inside:
		_t = 0.0
		disc_mat.albedo_color.a = 0.15
		swarm.speed_scale = 1.0
		return
	_t += delta
	disc_mat.albedo_color.a = 0.15 + 0.2 * (_t / limit)
	swarm.speed_scale = 1.0 + _t * 1.5
	level.tag_requests["bees"] = ["%d" % int(ceil(limit - _t)), Color(1, 0.85, 0.1)]
	if _t >= limit and level.try_capture():
		_carry()


func _carry() -> void:
	_busy = true
	Game.stats.bees += 1
	Sfx.play("growl", 0.1, -6.0, 3.0)
	var ball: Node3D = level.ball
	# nube de abejas alrededor de la bomba
	var cloud := CPUParticles3D.new()
	cloud.amount = 40
	cloud.lifetime = 0.6
	cloud.mesh = B.sphere_mesh(0.05, 4)
	cloud.material_override = B.mat(Color(1, 0.85, 0.1), 0.6, 0.8)
	cloud.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	cloud.emission_sphere_radius = 0.5
	cloud.gravity = Vector3.ZERO
	cloud.spread = 180
	cloud.initial_velocity_max = 1.5
	ball.add_child(cloud)
	await get_tree().create_timer(0.5).timeout
	var from := ball.global_position
	var to := hive.global_position + Vector3(0, -0.3, 0.3)
	var tw := create_tween()
	tw.tween_method(func(k: float): ball.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * 1.5, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	await tw.finished
	cloud.queue_free()
	await level.swallow(hive, to, Color(0.9, 0.75, 0.3))
	level.finish_capture("¡A LA COLMENA!", "Las abejas se llevaron tu bomba.", Color(1, 0.85, 0.2))
	_t = 0.0
	_busy = false
