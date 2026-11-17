extends Node3D
## Iguana quieta. Si la bomba entra a su radio rojo, avisa, apunta a donde estaba
## la bomba y lanza la lengua. Si atrapa la bomba, se la traga. Recarga 5 s.

const U = preload("res://scripts/unicaribe.gd")
const B = preload("res://scripts/build.gd")

var level
var radius := 3.6
var reload := 5.0
var _cd := 1.5
var _busy := false
var model: Node3D
var tongue: MeshInstance3D
var aim_line: MeshInstance3D
var disc_mat: StandardMaterial3D


func _ready() -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.4, 0.5, 0.6)
	cs.shape = sh
	cs.position = Vector3(0, 0.25, 0)
	sb.add_child(cs)
	add_child(sb)
	model = Node3D.new()
	add_child(model)
	U.iguana(model)
	# zona de peligro roja transparente
	disc_mat = StandardMaterial3D.new()
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color = Color(1, 0.15, 0.1, 0.16)
	var disc := B.add_mesh(self, B.cyl_mesh(radius, radius, 0.02, 32), disc_mat, Vector3(0, 0.03, 0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.06
	ring.outer_radius = radius
	B.add_mesh(self, ring, B.mat(Color(1, 0.2, 0.15), 0.5, 1.5), Vector3(0, 0.04, 0))
	tongue = B.add_mesh(self, B.box_mesh(Vector3(1, 0.07, 0.07)), B.mat(Color(1, 0.4, 0.55), 0.5, 0.3))
	tongue.visible = false
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1, 0.1, 0.1, 0.7)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aim_line = B.add_mesh(self, B.box_mesh(Vector3(1, 0.03, 0.03)), lm)
	aim_line.visible = false


func _mouth() -> Vector3:
	return model.global_transform * Vector3(0.68, 0.3, 0)


func _stretch(mi: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var d := to - from
	mi.global_position = from + d * 0.5
	mi.global_basis = Basis.looking_at(d.normalized() if d.length() > 0.01 else Vector3.FORWARD, Vector3.UP) * Basis(Vector3.UP, PI / 2)
	mi.scale = Vector3(maxf(d.length(), 0.01), 1, 1)


func _physics_process(delta: float) -> void:
	if level == null or _busy:
		return
	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0 or not (level.state in [0, 1]):
		return
	var bp: Vector3 = level.ball.global_position
	var flat := Vector3(bp.x - global_position.x, 0, bp.z - global_position.z)
	if flat.length() < radius and absf(bp.y - global_position.y) < 1.5:
		_attack(bp)


func _attack(target: Vector3) -> void:
	_busy = true
	# voltea hacia el objetivo (el modelo mira hacia +X)
	var d := target - global_position
	model.rotation.y = atan2(-d.z, d.x)
	# aviso: se infla y marca con una línea roja dónde va a pegar
	aim_line.visible = true
	_stretch(aim_line, _mouth(), target)
	disc_mat.albedo_color = Color(1, 0.15, 0.1, 0.32)
	Sfx.play("squeak", 0.1, -8.0, 0.6)
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(1.15, 1.3, 1.15), 0.7)
	await tw.finished
	aim_line.visible = false
	model.scale = Vector3.ONE
	if not is_inside_tree() or not (level.state in [0, 1]):
		_end()
		return
	# ¡lengüetazo!
	Sfx.play("whoosh", 0.1, -4.0, 1.8)
	tongue.visible = true
	var mouth := _mouth()
	var k := 0.0
	while k < 1.0:
		k = minf(1.0, k + get_physics_process_delta_time() / 0.12)
		_stretch(tongue, mouth, mouth.lerp(target, k))
		await get_tree().physics_frame
	var bp: Vector3 = level.ball.global_position
	if bp.distance_to(target) < 0.75 and level.try_capture():
		await _eat()
		return
	# falló: regresa la lengua
	k = 1.0
	while k > 0.0:
		k = maxf(0.0, k - get_physics_process_delta_time() / 0.2)
		_stretch(tongue, mouth, mouth.lerp(target, k))
		await get_tree().physics_frame
	_end()


func _eat() -> void:
	Game.stats.iguanas += 1
	var mouth := _mouth()
	var start: Vector3 = level.ball.global_position
	var k := 1.0
	while k > 0.0:
		k = maxf(0.0, k - get_physics_process_delta_time() / 0.25)
		var tip := mouth.lerp(start, k)
		_stretch(tongue, mouth, tip)
		level.ball.global_position = tip
		await get_tree().physics_frame
	tongue.visible = false
	await level.swallow(model, mouth)
	level.finish_capture("¡LENGÜETAZO!", "La iguana se comió tu bomba.", Color(0.6, 1, 0.4))
	_end()


func _end() -> void:
	tongue.visible = false
	aim_line.visible = false
	disc_mat.albedo_color = Color(1, 0.15, 0.1, 0.16)
	_cd = reload
	_busy = false
