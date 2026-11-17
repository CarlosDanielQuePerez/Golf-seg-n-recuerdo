extends RigidBody3D
## La "pelota" es una bomba con la mecha encendida. La mecha se acorta con el tiempo.

const B = preload("res://scripts/build.gd")
const RADIUS := 0.22

signal hit_something(body: Node, speed: float)

var trail: CPUParticles3D
var mesh_inst: MeshInstance3D      # esfera que rueda
var upright: Node3D                # tapa + mecha + chispa (siempre "hacia arriba")
var fuse_root: Node3D
var spark: CPUParticles3D
var spark_light: OmniLight3D
var body_mat: StandardMaterial3D
var fuse_left := 1.0               # 1 = mecha completa, 0 = ¡BOOM!
var _last_impact := 0.0
var _blink := 0.0


func _ready() -> void:
	mass = 0.5
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 6
	can_sleep = false
	linear_damp = 0.32
	angular_damp = 0.5
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.9
	physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = RADIUS
	cs.shape = sh
	add_child(cs)
	body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Game.bomb_color()
	body_mat.roughness = 0.25
	body_mat.metallic = 0.35
	body_mat.rim_enabled = true
	body_mat.rim = 0.5
	body_mat.emission_enabled = true
	body_mat.emission = Color(1, 0.1, 0.05)
	body_mat.emission_energy_multiplier = 0.0
	mesh_inst = B.add_mesh(self, B.sphere_mesh(RADIUS, 20), body_mat)
	# remaches y una calavera pintada: así se nota que rueda
	var rivet := B.mat(Color(0.55, 0.55, 0.6), 0.3, 0.0, 0.9)
	for i in 8:
		var a := i * TAU / 8
		B.add_mesh(mesh_inst, B.sphere_mesh(0.022, 6), rivet, Vector3(cos(a), 0, sin(a)) * (RADIUS - 0.005))
	var skull := B.mat(Color(0.95, 0.93, 0.85), 0.6)
	B.add_mesh(mesh_inst, B.sphere_mesh(0.07, 10), skull, Vector3(0, 0.03, RADIUS - 0.035), Vector3.ZERO, Vector3(1, 0.9, 0.35))
	B.add_mesh(mesh_inst, B.box_mesh(Vector3(0.07, 0.035, 0.03)), skull, Vector3(0, -0.045, RADIUS - 0.03))
	for sx in [-0.025, 0.025]:
		B.add_mesh(mesh_inst, B.sphere_mesh(0.018, 6), B.mat(Color(0.05, 0.05, 0.05)), Vector3(sx, 0.04, RADIUS - 0.005))

	# parte superior que no rueda (tapa, mecha y chispa)
	upright = Node3D.new()
	upright.top_level = true
	add_child(upright)
	B.add_mesh(upright, B.cyl_mesh(0.075, 0.09, 0.08, 12), B.mat(Color(0.6, 0.6, 0.65), 0.3, 0.0, 0.9), Vector3(0, RADIUS + 0.01, 0))
	fuse_root = Node3D.new()
	fuse_root.position = Vector3(0, RADIUS + 0.05, 0)
	upright.add_child(fuse_root)
	var rope := B.mat(Color(0.75, 0.62, 0.4), 0.9)
	B.add_mesh(fuse_root, B.cyl_mesh(0.02, 0.02, 0.12, 6), rope, Vector3(0, 0.06, 0))
	B.add_mesh(fuse_root, B.cyl_mesh(0.02, 0.02, 0.14, 6), rope, Vector3(0.035, 0.17, 0), Vector3(0, 0, -0.5))
	spark = CPUParticles3D.new()
	spark.position = Vector3(0.07, 0.24, 0)
	spark.amount = 24
	spark.lifetime = 0.35
	spark.local_coords = false
	spark.mesh = B.sphere_mesh(0.025, 4)
	spark.material_override = B.mat(Color(1, 0.75, 0.2), 1.0, 4.0)
	spark.direction = Vector3.UP
	spark.spread = 70
	spark.initial_velocity_min = 0.6
	spark.initial_velocity_max = 1.6
	spark.gravity = Vector3(0, -3, 0)
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0))
	spark.scale_amount_curve = c
	fuse_root.add_child(spark)
	spark_light = OmniLight3D.new()
	spark_light.light_color = Color(1, 0.6, 0.2)
	spark_light.omni_range = 1.6
	spark_light.light_energy = 1.2
	spark_light.position = spark.position
	fuse_root.add_child(spark_light)

	# estela
	trail = CPUParticles3D.new()
	trail.local_coords = false
	trail.amount = 40
	trail.lifetime = 0.45
	trail.mesh = B.sphere_mesh(0.08, 6)
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.vertex_color_use_as_albedo = true
	trail.material_override = tm
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_max = 0.2
	var g := Gradient.new()
	g.set_color(0, Color(0.6, 0.6, 0.6, 0.6))
	g.set_color(1, Color(0.3, 0.3, 0.3, 0.0))
	trail.color_ramp = g
	var c2 := Curve.new()
	c2.add_point(Vector2(0, 1))
	c2.add_point(Vector2(1, 0.1))
	trail.scale_amount_curve = c2
	trail.emitting = false
	add_child(trail)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# la tapa y la mecha siguen a la bomba pero apuntan contra la gravedad
	upright.global_position = global_position
	upright.global_basis = Basis(Vector3(0, 0, 1), PI) if gravity_scale < 0.0 else Basis.IDENTITY
	upright.visible = visible
	fuse_root.scale = Vector3(1, maxf(0.08, fuse_left), 1)
	spark.position = Vector3(0.07 * fuse_left, 0.24 * fuse_left / maxf(0.08, fuse_left), 0)
	spark_light.position = spark.position
	# parpadeo rojo cuando queda poco
	if fuse_left < 0.2 and visible:
		_blink += delta * lerpf(14.0, 4.0, fuse_left / 0.2)
		body_mat.emission_energy_multiplier = (0.5 + 0.5 * sin(_blink)) * 2.5
	else:
		body_mat.emission_energy_multiplier = 0.0


func _physics_process(delta: float) -> void:
	_last_impact -= delta
	trail.emitting = visible and linear_velocity.length() > 5.0


func set_lit(on: bool) -> void:
	spark.emitting = on
	spark_light.visible = on


func _on_body_entered(body: Node) -> void:
	var sp := linear_velocity.length()
	hit_something.emit(body, sp)
	if sp > 2.5 and _last_impact <= 0.0:
		_last_impact = 0.12
		Sfx.play("bounce", 0.15, linear_to_db(clampf(sp / 12.0, 0.15, 1.0)), 0.8)
		var tw := create_tween()
		tw.tween_property(mesh_inst, "scale", Vector3(1.25, 0.75, 1.25), 0.05)
		tw.tween_property(mesh_inst, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)


## Ajusta el giro para que ruede sin patinar (evita perder velocidad al tirar).
func set_rolling(v: Vector3, up: Vector3) -> void:
	linear_velocity = v
	var vh := v - up * v.dot(up)
	angular_velocity = up.cross(vh) / RADIUS


func teleport(pos: Vector3, vel := Vector3.ZERO) -> void:
	freeze = true
	global_position = pos
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	visible = true
	mesh_inst.scale = Vector3.ONE
	scale = Vector3.ONE
	await get_tree().physics_frame
	await get_tree().physics_frame
	freeze = false
	linear_velocity = vel
	angular_velocity = Vector3.ZERO
