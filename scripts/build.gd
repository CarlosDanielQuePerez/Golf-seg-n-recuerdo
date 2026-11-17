extends RefCounted
## Utilidades para construir los modelos 3D y escenarios por código (assets procedurales).

static var _mats := {}
static var _shaders := {}


static func mat(color: Color, rough := 0.85, emission := 0.0, metallic := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [color.to_html(), rough, emission, metallic]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


static func shader_mat(path: String, params := {}) -> ShaderMaterial:
	if not _shaders.has(path):
		_shaders[path] = load(path)
	var m := ShaderMaterial.new()
	m.shader = _shaders[path]
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


# ---------- mallas ----------
static func box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func cyl_mesh(top: float, bottom: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func sphere_mesh(r: float, seg := 16) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = seg / 2
	return s


static func add_mesh(parent: Node, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func static_box(parent: Node, size: Vector3, pos: Vector3, color: Color, rot := Vector3.ZERO, bounce := 0.3) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	sb.rotation = rot
	var pm := PhysicsMaterial.new()
	pm.bounce = bounce
	pm.friction = 0.8
	sb.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	add_mesh(sb, box_mesh(size), mat(color))
	parent.add_child(sb)
	return sb


# ---------- terreno CSG (una sola colisión continua, sin "escalones" entre piezas) ----------
static func ground(parent: Node, hole_pos := Vector3(0, -999, 0)) -> CSGCombiner3D:
	var c := CSGCombiner3D.new()
	c.use_collision = true
	c.name = "Terreno"
	c.material_override = shader_mat("res://shaders/grass.gdshader", {"hole_pos": hole_pos})
	parent.add_child(c)
	return c


static func csg_box(comb: Node, size: Vector3, pos: Vector3, rot := Vector3.ZERO, subtract := false, material: Material = null) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation = rot
	if subtract:
		b.operation = CSGShape3D.OPERATION_SUBTRACTION
	if material:
		b.material = material
	comb.add_child(b)
	return b


static func csg_cyl(comb: Node, r: float, h: float, pos: Vector3, subtract := false, material: Material = null, sides := 24) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = r
	c.height = h
	c.sides = sides
	c.position = pos
	if subtract:
		c.operation = CSGShape3D.OPERATION_SUBTRACTION
	if material:
		c.material = material
	comb.add_child(c)
	return c


## Plataforma con borde (bordillo) para que la pelota no caiga tan fácil.
static func fairway(comb: Node, center: Vector3, size: Vector2, curbs := "lrfb", curb_h := 0.35) -> void:
	csg_box(comb, Vector3(size.x, 2.0, size.y), center + Vector3(0, -1.0, 0))
	var t := 0.4
	if "l" in curbs:
		csg_box(comb, Vector3(t, curb_h, size.y), center + Vector3(-size.x / 2 + t / 2, curb_h / 2, 0))
	if "r" in curbs:
		csg_box(comb, Vector3(t, curb_h, size.y), center + Vector3(size.x / 2 - t / 2, curb_h / 2, 0))
	if "f" in curbs:
		csg_box(comb, Vector3(size.x, curb_h, t), center + Vector3(0, curb_h / 2, -size.y / 2 + t / 2))
	if "b" in curbs:
		csg_box(comb, Vector3(size.x, curb_h, t), center + Vector3(0, curb_h / 2, size.y / 2 - t / 2))


# ---------- agua / lava ----------
static func liquid(level: Node, parent: Node, center: Vector3, size: Vector2, kind := "water") -> Area3D:
	var path := "res://shaders/water.gdshader" if kind == "water" else "res://shaders/lava.gdshader"
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = int(size.x * 1.5)
	pm.subdivide_depth = int(size.y * 1.5)
	var mi := add_mesh(parent, pm, shader_mat(path), center)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if kind == "lava":
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.45, 0.1)
		light.omni_range = maxf(size.x, size.y)
		light.light_energy = 1.5
		light.position = center + Vector3(0, 1.0, 0)
		parent.add_child(light)
	var a := Area3D.new()
	a.position = center + Vector3(0, -0.6, 0)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(size.x, 1.0, size.y)
	cs.shape = sh
	a.add_child(cs)
	a.set_meta("kind", kind)
	a.set_meta("surface", center.y)
	parent.add_child(a)
	a.body_entered.connect(level._on_hazard.bind(a))
	return a


# ---------- decoración ----------
static func tree(parent: Node, pos: Vector3, s := 1.0) -> void:
	var t := Node3D.new()
	t.position = pos
	t.scale = Vector3.ONE * s
	t.rotation.y = randf() * TAU
	parent.add_child(t)
	add_mesh(t, cyl_mesh(0.18, 0.25, 1.6, 8), mat(Color(0.45, 0.28, 0.15)), Vector3(0, 0.8, 0))
	var greens := [Color(0.18, 0.5, 0.22), Color(0.22, 0.58, 0.25), Color(0.15, 0.45, 0.2)]
	if randf() < 0.5:
		for i in 3:
			add_mesh(t, cyl_mesh(0.0, 1.2 - i * 0.3, 1.3, 8), mat(greens[i]), Vector3(0, 1.8 + i * 0.75, 0))
	else:
		add_mesh(t, sphere_mesh(1.1, 10), mat(greens[0]), Vector3(0, 2.4, 0))
		add_mesh(t, sphere_mesh(0.8, 10), mat(greens[1]), Vector3(0.6, 2.9, 0.3))
		add_mesh(t, sphere_mesh(0.7, 10), mat(greens[2]), Vector3(-0.5, 2.8, -0.4))


static func rock(parent: Node, pos: Vector3, s := 1.0, color := Color(0.55, 0.55, 0.58)) -> void:
	add_mesh(parent, sphere_mesh(0.6, 6), mat(color), pos, Vector3(randf(), randf(), randf()), Vector3(1.3, 0.8, 1.0) * s)


static func cloud(parent: Node, pos: Vector3, s := 1.0) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	c.scale = Vector3.ONE * s
	parent.add_child(c)
	var m := mat(Color(1, 1, 1), 1.0)
	for i in 5:
		var mi := add_mesh(c, sphere_mesh(1.0 + randf() * 0.6, 10), m, Vector3(i * 1.2 - 2.4, randf() * 0.5, randf() * 0.8))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return c


static func flag(parent: Node, pos: Vector3, color := Color(0.9, 0.15, 0.2)) -> Node3D:
	var f := Node3D.new()
	f.position = pos
	parent.add_child(f)
	add_mesh(f, cyl_mesh(0.035, 0.035, 2.6, 8), mat(Color(0.95, 0.95, 0.95), 0.3), Vector3(0, 1.3, 0))
	var cloth := Node3D.new()
	cloth.position = Vector3(0, 2.3, 0)
	f.add_child(cloth)
	var p1 := add_mesh(cloth, box_mesh(Vector3(0.45, 0.5, 0.02)), mat(color), Vector3(0.24, 0, 0))
	add_mesh(cloth, box_mesh(Vector3(0.45, 0.5, 0.02)), mat(color.darkened(0.15)), Vector3(0.66, -0.04, 0), Vector3(0, 0, -0.15))
	p1.name = "Tela"
	var tw := f.create_tween().set_loops()
	tw.tween_property(cloth, "rotation:y", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cloth, "rotation:y", -0.35, 0.6).set_trans(Tween.TRANS_SINE)
	return f


static func sign_post(parent: Node, pos: Vector3, text: String, rot_y := 0.0) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = rot_y
	parent.add_child(s)
	add_mesh(s, box_mesh(Vector3(0.15, 1.4, 0.15)), mat(Color(0.45, 0.3, 0.18)), Vector3(0, 0.7, 0))
	add_mesh(s, box_mesh(Vector3(2.8, 1.1, 0.12)), mat(Color(0.95, 0.85, 0.6)), Vector3(0, 1.55, 0))
	var l := Label3D.new()
	l.text = text
	l.font_size = 52 if text.length() > 16 else 64
	l.pixel_size = 0.005
	l.modulate = Color(0.25, 0.15, 0.08)
	l.outline_size = 0
	l.position = Vector3(0, 1.55, 0.07)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.width = 520
	s.add_child(l)


static func floating_text(parent: Node, pos: Vector3, text: String, color := Color.WHITE, size := 96) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.006
	l.modulate = color
	l.outline_size = 18
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", pos.y + 2.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.tween_callback(l.queue_free)


# ---------- partículas ----------
static func burst(parent: Node, pos: Vector3, color: Color, amount := 30, speed := 5.0, gravity := -9.8, size := 0.15, life := 1.0, spread := 180.0, dir := Vector3.UP) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.mesh = sphere_mesh(size, 6)
	var m := mat(color, 1.0)
	p.material_override = m
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	var t := parent.get_tree().create_timer(life + 0.5)
	t.timeout.connect(p.queue_free)
	return p


static func confetti(parent: Node, pos: Vector3, amount := 120) -> void:
	var colors := [Color(1, 0.2, 0.3), Color(1, 0.85, 0.1), Color(0.2, 0.6, 1), Color(0.3, 1, 0.4), Color(1, 0.4, 0.9)]
	for c in colors:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = amount / colors.size()
		p.lifetime = 2.5
		p.mesh = box_mesh(Vector3(0.12, 0.02, 0.18))
		p.material_override = mat(c, 0.6)
		p.direction = Vector3.UP
		p.spread = 50
		p.initial_velocity_min = 6
		p.initial_velocity_max = 13
		p.gravity = Vector3(0, -6, 0)
		p.damping_min = 1.5
		p.damping_max = 3.0
		p.angular_velocity_min = -720
		p.angular_velocity_max = 720
		p.particle_flag_rotate_y = true
		p.position = pos
		parent.add_child(p)
		p.emitting = true
		parent.get_tree().create_timer(3.5).timeout.connect(p.queue_free)


static func smoke(parent: Node, pos: Vector3, amount := 24, dir := Vector3.UP, color := Color(0.6, 0.6, 0.62)) -> CPUParticles3D:
	var p := burst(parent, pos, color, amount, 2.8, 1.2, 0.45, 2.0, 28.0, dir)
	p.explosiveness = 0.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(0.4, 1.2))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.damping_min = 1.0
	p.damping_max = 2.0
	return p
