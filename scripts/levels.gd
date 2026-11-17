extends RefCounted
## Geometría y comportamiento de los hoyos (ambientados en la Universidad del Caribe).

const B = preload("res://scripts/build.gd")
const Mover = preload("res://scripts/mover.gd")
const U = preload("res://scripts/unicaribe.gd")
const IbisScript = preload("res://scripts/ibis.gd")
const IguanaScript = preload("res://scripts/iguana_turret.gd")
const HiveScript = preload("res://scripts/beehive.gd")
const OspreyScript = preload("res://scripts/osprey.gd")
const BossScript = preload("res://scripts/boss.gd")
const AIM := 0
const MOVING := 1
const EVENT := 2
const DONE := 3


static func build(lv, i: int) -> void:
	match i:
		0: _hoyo1(lv)
		1: _hoyo2(lv)
		2: _hoyo3(lv)
		3: _hoyo4(lv)
		4: _hoyo5(lv)


# ---------------- utilidades de escenario ----------------


static func island_under(lv, center: Vector3, size: Vector2, color := Color(0.42, 0.28, 0.17)) -> void:
	var dark := color.darkened(0.25)
	B.add_mesh(lv, B.box_mesh(Vector3(size.x * 0.92, 1.6, size.y * 0.92)), B.mat(color), center + Vector3(0, -2.6, 0))
	B.add_mesh(lv, B.box_mesh(Vector3(size.x * 0.7, 1.6, size.y * 0.7)), B.mat(dark), center + Vector3(0, -4.1, 0))
	B.add_mesh(lv, B.box_mesh(Vector3(size.x * 0.4, 2.0, size.y * 0.4)), B.mat(dark.darkened(0.2)), center + Vector3(0, -5.8, 0))


static func deco_island(lv, pos: Vector3, r := 3.0, trees := 2) -> void:
	B.add_mesh(lv, B.cyl_mesh(r, r * 0.95, 0.6, 10), B.mat(Color(0.3, 0.68, 0.27)), pos)
	B.add_mesh(lv, B.cyl_mesh(r * 0.95, 0.4, r * 1.3, 10), B.mat(Color(0.45, 0.3, 0.18)), pos + Vector3(0, -0.3 - r * 0.65, 0))
	for k in trees:
		B.tree(lv, pos + Vector3(randf_range(-r * 0.5, r * 0.5), 0.3, randf_range(-r * 0.5, r * 0.5)), randf_range(0.8, 1.3))
	if randf() < 0.6:
		B.rock(lv, pos + Vector3(randf_range(-r * 0.6, r * 0.6), 0.3, randf_range(-r * 0.6, r * 0.6)), 0.6)


static func clouds(lv, n := 8, y := 10.0, spread := 60.0, center := Vector3(0, 0, -20)) -> void:
	for k in n:
		var c := B.cloud(lv, center + Vector3(randf_range(-spread, spread), y + randf_range(-3, 6), randf_range(-spread, spread)), randf_range(1.0, 2.2))
		var tw := c.create_tween().set_loops()
		var dx := randf_range(4, 9)
		tw.tween_property(c, "position:x", c.position.x + dx, randf_range(8, 14)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "position:x", c.position.x, randf_range(8, 14)).set_trans(Tween.TRANS_SINE)


static func bumper(lv, pos: Vector3, r := 0.5) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	sb.add_to_group("bumper")
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = 0.9
	cs.shape = sh
	sb.add_child(cs)
	var vis := Node3D.new()
	sb.add_child(vis)
	B.add_mesh(vis, B.cyl_mesh(r, r, 0.9, 20), B.mat(Color(0.95, 0.2, 0.3), 0.4))
	B.add_mesh(vis, B.cyl_mesh(r + 0.03, r + 0.03, 0.25, 20), B.mat(Color(1, 1, 1), 0.4, 0.6), Vector3(0, 0.15, 0))
	B.add_mesh(vis, B.sphere_mesh(r * 0.6, 12), B.mat(Color(1, 0.85, 0.2), 0.3, 1.2), Vector3(0, 0.45, 0))
	lv.add_child(sb)
	return sb


static func mover(lv, pos: Vector3, mode: String, shapes: Array, cfg := {}) -> AnimatableBody3D:
	## shapes: [[size, offset, color], ...]
	var ab = Mover.new()
	ab.position = pos
	ab.mode = mode
	for k in cfg:
		ab.set(k, cfg[k])
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	pm.bounce = 0.4
	ab.physics_material_override = pm
	for s in shapes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = s[0]
		cs.shape = sh
		cs.position = s[1]
		ab.add_child(cs)
		B.add_mesh(ab, B.box_mesh(s[0]), B.mat(s[2]), s[1])
	lv.add_child(ab)
	return ab


static func glow_pad(lv, pos: Vector3, size: Vector2, color: Color, arrows := false, rot := Vector3.ZERO) -> void:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := B.add_mesh(lv, pm, B.shader_mat("res://shaders/pad.gdshader", {"color": color, "arrows": 1.0 if arrows else 0.0}), pos, rot)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func sparkles(lv, pos: Vector3, extents: Vector3, color: Color, up := Vector3.UP) -> void:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.6
	p.mesh = B.sphere_mesh(0.05, 4)
	p.material_override = B.mat(color, 1.0, 3.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = up
	p.spread = 10
	p.gravity = up * 2.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.position = pos
	lv.add_child(p)



# ---------------- mecánicas extra ----------------
## Letrero en una islita aparte: se ve, pero no estorba el camino.


static func side_sign(lv, pos: Vector3, text: String, rot_y := 0.0, top := Color(0.3, 0.62, 0.27)) -> void:
	B.add_mesh(lv, B.cyl_mesh(1.25, 1.15, 0.4, 10), B.mat(top), pos + Vector3(0, -0.2, 0))
	B.add_mesh(lv, B.cyl_mesh(1.15, 0.25, 1.6, 10), B.mat(Color(0.45, 0.3, 0.18)), pos + Vector3(0, -1.2, 0))
	B.sign_post(lv, pos, text, rot_y)


## Trampolín: lanza la bomba hacia arriba (y opcionalmente hacia adelante).


static func jump_pad(lv, pos: Vector3, power := 8.0, push := Vector3.ZERO) -> void:
	var vis := Node3D.new()
	vis.position = pos
	lv.add_child(vis)
	B.add_mesh(vis, B.cyl_mesh(0.75, 0.75, 0.04, 20), B.mat(Color(0.12, 0.12, 0.12)), Vector3(0, 0.02, 0))
	for k in 8:
		var a := k * TAU / 8
		B.add_mesh(vis, B.box_mesh(Vector3(0.22, 0.045, 0.12)), B.mat(Color(1, 0.8, 0.1)), Vector3(cos(a) * 0.62, 0.03, sin(a) * 0.62), Vector3(0, -a, 0))
	B.add_mesh(vis, B.cyl_mesh(0.48, 0.48, 0.06, 20), B.mat(Color(0.95, 0.2, 0.2), 0.4, 0.6), Vector3(0, 0.05, 0))
	var arrow := B.add_mesh(vis, B.cyl_mesh(0.0, 0.25, 0.04, 3), B.mat(Color(1, 1, 1), 0.5, 1.0), Vector3(0, 0.09, 0))
	if push.length() > 0.01:
		arrow.rotation.y = atan2(push.x, push.z) + PI / 2
	var zone: Area3D = lv.add_zone(pos + Vector3(0, 0.35, 0), Vector3(1.3, 0.7, 1.3), "jump", {"power": power, "push": push})
	zone.set_meta("visual", vis)


## Imán gigante flotando. strength > 0 atrae, < 0 repele.


static func portals(lv, a: Vector3, out_a: Vector3, b: Vector3, out_b: Vector3) -> void:
	var cols := [Color(0.3, 0.8, 1.0), Color(1, 0.45, 0.9)]
	var ends := [[a, out_a], [b, out_b]]
	for k in 2:
		var p: Vector3 = ends[k][0]
		var o: Vector3 = ends[k][1]
		var ring := Node3D.new()
		ring.position = p + Vector3(0, 0.75, 0)
		ring.rotation.y = atan2(o.x, o.z)
		lv.add_child(ring)
		var tor := TorusMesh.new()
		tor.inner_radius = 0.62
		tor.outer_radius = 0.78
		B.add_mesh(ring, tor, B.mat(cols[k], 0.4, 2.0), Vector3.ZERO, Vector3(PI / 2, 0, 0))
		var disc := B.add_mesh(ring, B.cyl_mesh(0.62, 0.62, 0.02, 24), B.shader_mat("res://shaders/pad.gdshader", {"color": cols[k]}), Vector3.ZERO, Vector3(PI / 2, 0, 0))
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tw := ring.create_tween().set_loops()
		tw.tween_property(disc, "rotation:y", TAU, 2.0).as_relative()
	# entrar por A -> salir por B (un poco delante) y viceversa
	lv.add_zone(a + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 0.5), "portal", {"to": b + out_b * 0.9 + Vector3(0, 0.25, 0), "out": out_b})
	lv.add_zone(b + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 0.5), "portal", {"to": a + out_a * 0.9 + Vector3(0, 0.25, 0), "out": out_a})


## Reloj flotante: +5 segundos de mecha.


static func clock(lv, pos: Vector3, upside_down := false) -> void:
	var vis := Node3D.new()
	vis.position = pos
	if upside_down:
		vis.rotation.z = PI
	lv.add_child(vis)
	var inner := Node3D.new()
	vis.add_child(inner)
	B.add_mesh(inner, B.cyl_mesh(0.42, 0.42, 0.12, 20), B.mat(Color(0.3, 0.85, 0.45), 0.4, 0.8), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	B.add_mesh(inner, B.cyl_mesh(0.34, 0.34, 0.14, 20), B.mat(Color(0.98, 0.98, 0.92)), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	B.add_mesh(inner, B.box_mesh(Vector3(0.04, 0.24, 0.16)), B.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.1, 0))
	B.add_mesh(inner, B.box_mesh(Vector3(0.17, 0.04, 0.16)), B.mat(Color(0.1, 0.1, 0.1)), Vector3(0.07, 0, 0))
	B.add_mesh(inner, B.sphere_mesh(0.08, 8), B.mat(Color(0.3, 0.85, 0.45)), Vector3(0, 0.48, 0))
	var l := Label3D.new()
	l.text = "+5"
	l.font_size = 64
	l.pixel_size = 0.006
	l.outline_size = 12
	l.modulate = Color(0.6, 1, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 0.75, 0)
	vis.add_child(l)
	var tw := inner.create_tween().set_loops()
	tw.tween_property(inner, "rotation:y", TAU, 2.5).as_relative()
	var tw2 := vis.create_tween().set_loops()
	tw2.tween_property(vis, "position:y", pos.y + 0.2, 0.8).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(vis, "position:y", pos.y, 0.8).set_trans(Tween.TRANS_SINE)
	var zone: Area3D = lv.add_zone(pos, Vector3.ZERO, "clock", {"radius": 0.75})
	zone.set_meta("visual", vis)


# ---------------- campus ----------------
## Iguana que cruza el camino de lado a lado (con preferencia de paso).


static func bat_orbit(lv, center: Vector3, radius: float, height: float, period: float) -> void:
	var pivot := Node3D.new()
	pivot.position = center
	pivot.rotation.y = randf() * TAU
	lv.add_child(pivot)
	var b := U.bat(pivot)
	b.position = Vector3(radius, height, 0)
	var tw := pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:y", TAU * signf(period), absf(period)).as_relative()
	var tw2 := b.create_tween().set_loops()
	tw2.tween_property(b, "position:y", height + 0.4, 0.5).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(b, "position:y", height - 0.2, 0.5).set_trans(Tween.TRANS_SINE)


static func palm_island(lv, pos: Vector3, r := 3.0, palms := 2) -> void:
	B.add_mesh(lv, B.cyl_mesh(r, r * 0.95, 0.6, 10), B.mat(Color(0.3, 0.68, 0.27)), pos)
	B.add_mesh(lv, B.cyl_mesh(r * 0.95, 0.4, r * 1.3, 10), B.mat(Color(0.45, 0.3, 0.18)), pos + Vector3(0, -0.3 - r * 0.65, 0))
	for k in palms:
		U.palm(lv, pos + Vector3(randf_range(-r * 0.5, r * 0.5), 0.3, randf_range(-r * 0.5, r * 0.5)), randf_range(0.8, 1.2))


# ---------------- fauna ----------------
## Cangrejo-imán. Rojo: jala la bomba. Azul: la empuja. Con radio visible y línea de jalón.
static func crab(lv, pos: Vector3, red: bool, radius := 3.0, strength := 22.0) -> void:
	var c: Dictionary = U.crab(lv, red)
	var n: Node3D = c.node
	n.position = pos
	n.rotation.y = randf() * TAU
	var col := Color(1, 0.25, 0.2) if red else Color(0.3, 0.55, 1.0)
	var disc := B.add_mesh(lv, B.cyl_mesh(radius, radius, 0.02, 32), B.shader_mat("res://shaders/pad.gdshader", {"color": col * 0.55}), pos + Vector3(0, 0.03, 0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.albedo_color = Color(col.r, col.g, col.b, 0.7)
	var beam := B.add_mesh(lv, B.box_mesh(Vector3(0.06, 0.06, 1.0)), lm)
	beam.visible = false
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var z: Area3D = lv.add_zone(pos + Vector3(0, 0.3, 0), Vector3.ZERO, "magnet", {"radius": radius, "strength": strength if red else -strength})
	z.set_meta("beam", beam)


static func ibis(lv, cfg: Dictionary) -> void:
	var b = IbisScript.new()
	b.level = lv
	for k in cfg:
		b.set(k, cfg[k])
	lv.add_child(b)


static func iguana(lv, pos: Vector3, radius := 3.6) -> Node3D:
	var g = IguanaScript.new()
	g.level = lv
	g.radius = radius
	g.position = pos
	lv.add_child(g)
	return g


static func beehive(lv, pos: Vector3, radius := 3.3) -> void:
	var h = HiveScript.new()
	h.level = lv
	h.radius = radius
	h.position = pos
	lv.add_child(h)


## Construye un tramo de terreno con bloques que caen del cielo. La colisión
## se activa al terminar, y al final se llama `after` (para obstáculos, etc.).
static func grow_section(lv, center: Vector3, size: Vector2, curbs: String, after: Callable) -> void:
	var mat: Material = lv.ground.material_override
	var nx := int(ceil(size.x / 2.0))
	var nz := int(ceil(size.y / 2.0))
	var tx := size.x / nx
	var tz := size.y / nz
	var tiles: Array = []
	Sfx.play("whoosh", 0.05, -2.0, 0.8)
	for iz in nz:
		for ix in nx:
			var p := center + Vector3(-size.x / 2 + tx * (ix + 0.5), -1.0, size.y / 2 - tz * (iz + 0.5))
			var mi := B.add_mesh(lv, B.box_mesh(Vector3(tx, 2, tz)), mat, p + Vector3(0, 14 + randf() * 4, 0))
			tiles.append(mi)
			var tw := mi.create_tween()
			tw.tween_interval(iz * 0.09 + randf() * 0.06)
			tw.tween_property(mi, "position:y", p.y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var t2: Tween = lv.create_tween()
		t2.tween_interval(iz * 0.09 + 0.38)
		t2.tween_callback(Sfx.play.bind("bounce", 0.2, -4.0, 0.55))
	await lv.get_tree().create_timer(nz * 0.09 + 0.55).timeout
	B.fairway(lv.ground, center, size, curbs)
	island_under(lv, center, size)
	for t in tiles:
		(t as Node).queue_free()
	B.burst(lv, center + Vector3(0, 0.2, size.y / 2 - 1.0), Color(0.6, 0.5, 0.35), 30, 5.0, -10.0, 0.12, 0.8, 70.0)
	lv.add_shake(0.25)
	after.call()


## Hace aparecer un nodo con un "pop".
static func pop_in(n: Node3D) -> void:
	var s := n.scale
	n.scale = Vector3.ONE * 0.01
	var tw := n.create_tween()
	tw.tween_property(n, "scale", s, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func planter(lv, p: Vector3) -> void:
	var sb := B.static_box(lv, Vector3(1.8, 0.6, 1.8), p + Vector3(0, 0.3, 0), Color(0.6, 0.55, 0.5))
	B.add_mesh(sb, B.box_mesh(Vector3(1.5, 0.1, 1.5)), B.mat(Color(0.35, 0.25, 0.15)), Vector3(0, 0.32, 0))
	U.palm(sb, Vector3(0, 0.3, 0), 0.8)
	pop_in(sb)


# =====================================================================
# HOYO 1 — "Primer Día": el hoyo huye y el campus se va construyendo detrás.
# =====================================================================
static func _hoyo1(lv) -> void:
	var g: CSGCombiner3D = lv.ground
	lv.tee_pos = Vector3(0, 0.3, 4)
	# tramo 1 (el único que existe al principio)
	B.fairway(g, Vector3(0, 0, -15), Vector2(12, 44), "lrb")
	island_under(lv, Vector3(0, 0, -15), Vector2(12, 44))
	lv.custom.wall = B.static_box(lv, Vector3(12, 0.35, 0.4), Vector3(0, 0.175, -36.8), Color(0.45, 0.3, 0.18))
	# estanque (con cocodrilo monitoreado)
	B.csg_box(g, Vector3(9.3, 1.6, 6.0), Vector3(-0.95, 0.0, -17), Vector3.ZERO, true)
	B.liquid(lv, lv, Vector3(-0.95, -0.25, -17), Vector2(9.3, 6.0), "water")
	B.csg_cyl(g, 1.6, 0.6, Vector3(-3.5, -0.1, -8), false, null, 16)
	jump_pad(lv, Vector3(-1.0, 0, -10.5), 7.5, Vector3(0, 0, -5.5))
	ibis(lv, {"mode": "line", "a": Vector3(-4.5, 0, -25), "b": Vector3(4.5, 0, -25), "period": 7.0})
	clock(lv, Vector3(4.6, 0.7, -17.0))
	clock(lv, Vector3(-4.0, 0.7, -28.0))
	lv.make_hole(Vector3(0, 0, -32))
	lv.custom.stage = 0
	lv.custom.tick = func(d: float): _hoyo1_tick(lv, d)
	side_sign(lv, Vector3(-8.2, 0, 2.5), "BIENVENIDO A LA UNICARIBE. HOYO FÁCIL ;)", 0.45)
	side_sign(lv, Vector3(8.4, 0, -15.5), "COCODRILO EN MONITOREO. ÉL TAMBIÉN TE MONITOREA", -0.5)
	# campus alrededor
	U.building(lv, Vector3(17, -1, -8), Vector3(7, 6, 5), "RECTORÍA", -0.5)
	U.building(lv, Vector3(-18, 0, -26), Vector3(8, 5, 5), "AULAS", 0.6)
	U.building(lv, Vector3(18, 1, -50), Vector3(6, 4, 5), "CAFETERÍA", -0.7, Color(0.9, 0.5, 0.15))
	U.building(lv, Vector3(0, 2, -80), Vector3(10, 7, 5), "BIBLIOTECA")
	for p in [Vector3(-12, -1, -6), Vector3(13, 0, -26), Vector3(-14, 1, -48), Vector3(12, -2, 4), Vector3(-11, 2, -66), Vector3(11, 3, -68)]:
		palm_island(lv, p, randf_range(2.5, 3.5), 2)
	clouds(lv, 9, 19.0, 60.0, Vector3(0, 0, -30))
	for k in 2:
		var duck := Node3D.new()
		duck.position = Vector3(-3.0 + k * 2.5, -0.2, -16 + k)
		lv.add_child(duck)
		B.add_mesh(duck, B.sphere_mesh(0.22, 10), B.mat(Color(1, 0.9, 0.2)), Vector3.ZERO, Vector3.ZERO, Vector3(1.3, 0.8, 1))
		B.add_mesh(duck, B.sphere_mesh(0.13, 8), B.mat(Color(1, 0.9, 0.2)), Vector3(0.2, 0.2, 0))
		B.add_mesh(duck, B.box_mesh(Vector3(0.12, 0.04, 0.08)), B.mat(Color(1, 0.5, 0.1)), Vector3(0.33, 0.2, 0))
		var tw := duck.create_tween().set_loops()
		tw.tween_property(duck, "position:x", duck.position.x + 2.0, 3.0 + k).set_trans(Tween.TRANS_SINE)
		tw.tween_property(duck, "rotation:y", PI, 0.4)
		tw.tween_property(duck, "position:x", duck.position.x, 3.0 + k).set_trans(Tween.TRANS_SINE)
		tw.tween_property(duck, "rotation:y", 0.0, 0.4)


static func _hoyo1_tick(lv, _d: float) -> void:
	if lv.state != MOVING or lv.custom.get("building", false):
		return
	var bp: Vector3 = lv.ball.global_position
	var dist := Vector2(bp.x - lv.hole_pos.x, bp.z - lv.hole_pos.z).length()
	if dist > 3.2:
		return
	if lv.custom.stage < 2:
		_hoyo1_flee(lv)
	elif not lv.custom.get("gave_up", false) and dist < 2.5:
		lv.custom.gave_up = true
		lv.hud.popup("Vale, vale...", "Ya me quedo quieto.", Color(1, 1, 1), 1.2)


static func _hoyo1_flee(lv) -> void:
	var c: Dictionary = lv.custom
	c.building = true
	var stage: int = c.stage
	c.stage = stage + 1
	lv.state = EVENT
	Sfx.play("squeak")
	Sfx.play("hop", 0.05)
	var lines := ["¡NOPE!", "¡LLEGO TARDE A CLASE!"]
	var subs := ["El hoyo no estaba listo. El campus tampoco.", "Y se llevó el campus con él."]
	lv.hud.popup(lines[stage], subs[stage], Color(1, 0.6, 0.3), 1.4)
	var center: Vector3 = Vector3(0, 0, -44) if stage == 0 else Vector3(0, 0, -58.5)
	var size: Vector2 = Vector2(12, 14) if stage == 0 else Vector2(12, 15)
	var to: Vector3 = Vector3(-3.5, 0, -47.5) if stage == 0 else Vector3(3.5, 0, -61.5)
	var old_zoom: float = lv.zoom
	c.follow_in_event = true
	c.cam_target = center
	lv.zoom = 17.0
	lv.move_hole(to, 6.0, 1.7)
	var after := func():
		if stage == 0:
			planter(lv, Vector3(3.6, 0, -48.5))
			pop_in(iguana(lv, Vector3(4.0, 0, -41.5), 3.4))
			clock(lv, Vector3(0, 0.7, -40.0))
		else:
			planter(lv, Vector3(-3.6, 0, -63.0))
			pop_in(iguana(lv, Vector3(-4.0, 0, -54.0), 3.4))
			ibis(lv, {"mode": "circle", "center": Vector3(0.5, 0, -59.0), "radius": 2.4, "period": 6.0})
			clock(lv, Vector3(-1.5, 0.7, -52.5))
	await grow_section(lv, center, size, "lr" if stage == 0 else "lrf", after)
	# quitar el muro temporal y poner uno nuevo al final (si falta otro tramo)
	var wall: Node = c.wall
	wall.queue_free()
	if stage == 0:
		c.wall = B.static_box(lv, Vector3(12, 0.35, 0.4), Vector3(0, 0.175, -50.8), Color(0.45, 0.3, 0.18))
	await lv.get_tree().create_timer(0.6).timeout
	c.erase("cam_target")
	c.follow_in_event = false
	lv.zoom = old_zoom
	if lv.state == EVENT:
		lv.state = MOVING
		lv.moving_time = 0.0
	c.building = false


# =====================================================================
# HOYO 2 — "Camino a la Biblioteca": cangrejos, abejas, ibis y río con cocodrilo.
# =====================================================================
static func _hoyo2(lv) -> void:
	var g: CSGCombiner3D = lv.ground
	lv.tee_pos = Vector3(0, 0.3, 3.0)
	B.fairway(g, Vector3(0, 0, -4), Vector2(12, 20), "lrb")
	island_under(lv, Vector3(0, 0, -4), Vector2(12, 20))
	B.fairway(g, Vector3(0, 0, -22), Vector2(12, 16), "lr")
	island_under(lv, Vector3(0, 0, -22), Vector2(12, 16))
	B.fairway(g, Vector3(0, 0, -45), Vector2(12, 16), "lrf")
	island_under(lv, Vector3(0, 0, -45), Vector2(12, 16))
	# río
	B.csg_box(g, Vector3(12, 1.0, 7.0), Vector3(0, -1.3, -33.5))
	B.csg_box(g, Vector3(0.4, 1.15, 7.0), Vector3(-5.8, -0.225, -33.5))
	B.csg_box(g, Vector3(0.4, 1.15, 7.0), Vector3(5.8, -0.225, -33.5))
	B.liquid(lv, lv, Vector3(0, -0.25, -33.5), Vector2(11.2, 7.0), "water")
	var log_ := mover(lv, Vector3(0, -0.25, -33.5), "slide", [[Vector3(1.4, 0.5, 7.4), Vector3.ZERO, Color(0.5, 0.32, 0.18)]], {"offset": Vector3(4.0, 0, 0), "period": 5.0})
	B.add_mesh(log_, B.cyl_mesh(0.3, 0.3, 7.5, 10), B.mat(Color(0.42, 0.26, 0.14)), Vector3(-0.4, 0.15, 0), Vector3(PI / 2, 0, 0))
	B.add_mesh(log_, B.cyl_mesh(0.3, 0.3, 7.5, 10), B.mat(Color(0.47, 0.3, 0.16)), Vector3(0.4, 0.15, 0), Vector3(PI / 2, 0, 0))
	# jardín de entrada: cangrejos e ibis
	crab(lv, Vector3(-4.3, 0, -4.5), true)
	crab(lv, Vector3(4.3, 0, -9.0), false)
	ibis(lv, {"mode": "line", "a": Vector3(-4.5, 0, -12.5), "b": Vector3(4.5, 0, -12.5), "period": 5.5})
	# árbol con panal en el camino corto
	beehive(lv, Vector3(0, 0, -22), 3.3)
	jump_pad(lv, Vector3(-3.0, 0, -28.4), 6.5, Vector3(0, 0, -6.0))
	clock(lv, Vector3(4.6, 0.7, -22.0))
	clock(lv, Vector3(-2.6, 1.6, -33.5))
	# biblioteca y el hoyo frente a la puerta
	lv.make_hole(Vector3(0, 0, -48))
	crab(lv, Vector3(3.8, 0, -46.0), true, 2.4, 18.0)
	ibis(lv, {"mode": "eight", "center": Vector3(-1.5, 0, -42.0), "radius": 2.8, "period": 8.0})
	U.building(lv, Vector3(0, 0, -59.5), Vector3(12, 7, 5), "BIBLIOTECA")
	for k in 3:
		B.add_mesh(lv, B.box_mesh(Vector3(6 - k, 0.25, 0.8)), B.mat(Color(0.75, 0.72, 0.68)), Vector3(0, 0.12 + k * 0.25, -53.5 - k * 0.7))
	side_sign(lv, Vector3(-7.0, 0, -2.0), "CANGREJO ROJO JALA. AZUL EMPUJA. TÚ SUFRES", 0.5)
	side_sign(lv, Vector3(7.0, 0, -21.0), "NO MOLESTAR A LAS ABEJAS (TIENEN EXAMEN)", -0.5)
	U.building(lv, Vector3(-17, -1, -14), Vector3(7, 5, 5), "LABORATORIOS", 0.6)
	U.building(lv, Vector3(17, 0, -38), Vector3(6, 4, 5), "DEPORTES", -0.6, Color(0.2, 0.6, 0.3))
	for p in [Vector3(-12, -1, -32), Vector3(12, 1, -6), Vector3(-12, 0, -50), Vector3(12, -1, -54)]:
		palm_island(lv, p, randf_range(2.5, 3.5), 2)
	clouds(lv, 9, 11.0)


# =====================================================================
# HOYO 3 — "Santuario de Murciélagos": gravedad invertida, oscuridad y hongos.
# =====================================================================
static func _hoyo3(lv) -> void:
	var g: CSGCombiner3D = lv.ground
	lv.tee_pos = Vector3(0, 0.3, 2.5)
	lv.kill_low = -14.0
	lv.kill_high = 22.0
	g.material_override.set_shader_parameter("grass_a", Color(0.42, 0.36, 0.3))
	g.material_override.set_shader_parameter("grass_b", Color(0.38, 0.32, 0.27))
	g.material_override.set_shader_parameter("green_col", Color(0.5, 0.75, 0.4))
	g.material_override.set_shader_parameter("dirt_col", Color(0.32, 0.25, 0.2))
	g.material_override.set_shader_parameter("dirt_dark", Color(0.22, 0.17, 0.13))
	# piso inicial
	B.fairway(g, Vector3(0, 0, -3), Vector2(8, 14), "lrb")
	island_under(lv, Vector3(0, 0, -3), Vector2(8, 14), Color(0.32, 0.25, 0.2))
	# techo (se juega boca abajo)
	B.csg_box(g, Vector3(8, 2, 22), Vector3(0, 7, -16))
	B.csg_box(g, Vector3(0.4, 0.35, 22), Vector3(-3.8, 5.825, -16))
	B.csg_box(g, Vector3(0.4, 0.35, 22), Vector3(3.8, 5.825, -16))
	B.csg_box(g, Vector3(8, 0.35, 0.4), Vector3(0, 5.825, -5.2))
	# pilares colgantes en el techo
	B.csg_box(g, Vector3(1.6, 1.2, 1.0), Vector3(-1.6, 5.4, -14))
	B.csg_box(g, Vector3(1.6, 1.2, 1.0), Vector3(1.6, 5.4, -18.5))
	B.add_mesh(lv, B.cyl_mesh(4.5, 0.5, 4.0, 8), B.mat(Color(0.25, 0.2, 0.17)), Vector3(0, 10, -16))
	# isla final
	B.fairway(g, Vector3(0, 0, -31), Vector2(8, 12), "lrf")
	island_under(lv, Vector3(0, 0, -31), Vector2(8, 12), Color(0.32, 0.25, 0.2))
	lv.make_hole(Vector3(0, 0, -33.5))
	# pads de gravedad
	lv.add_zone(Vector3(0, 0.5, -7.5), Vector3(6.4, 1.2, 2.2), "gravity_up")
	glow_pad(lv, Vector3(0, 0.02, -7.5), Vector2(6.4, 2.2), Color(0.75, 0.3, 1.0))
	sparkles(lv, Vector3(0, 0.3, -7.5), Vector3(3, 0.1, 1), Color(0.8, 0.5, 1.0))
	lv.add_zone(Vector3(0, 5.5, -24.0), Vector3(6.4, 1.2, 2.2), "gravity_down")
	glow_pad(lv, Vector3(0, 5.98, -24.0), Vector2(6.4, 2.2), Color(0.3, 0.9, 1.0), false, Vector3(PI, 0, 0))
	sparkles(lv, Vector3(0, 5.7, -24.0), Vector3(3, 0.1, 1), Color(0.4, 0.9, 1.0), Vector3.DOWN)
	var l := Label3D.new()
	l.text = "↑ PIENSA COMO MURCIÉLAGO ↑"
	l.font_size = 120
	l.pixel_size = 0.01
	l.modulate = Color(1, 0.8, 0.5)
	l.outline_size = 20
	l.position = Vector3(0, 2.5, -8.5)
	lv.add_child(l)
	side_sign(lv, Vector3(-6.8, 0, -0.5), "QUÉDATE EN LA LUZ DE LOS HONGOS. LOS MURCIÉLAGOS ODIAN LA LUZ", 0.45, Color(0.4, 0.33, 0.27))
	# enjambre de murciélagos: empuja la bomba cuando vas por el techo
	lv.add_zone(Vector3(0, 5.3, -16.5), Vector3(8, 1.4, 3.0), "wind", {"force": Vector3(3.2, 0, 0)})
	for k in 6:
		var bt := U.bat(lv)
		bt.position = Vector3(-4.5, 4.4 + randf() * 0.6, -15.5 - randf() * 2.0)
		bt.rotation.y = PI / 2
		var tw := bt.create_tween().set_loops()
		tw.tween_interval(randf() * 1.5)
		tw.tween_property(bt, "position:x", 4.5, 1.8)
		tw.tween_property(bt, "position:x", -4.5, 0.0)
	for c in [Vector3(0, 3, -3), Vector3(0, 3, -16), Vector3(0, 3, -31)]:
		bat_orbit(lv, c, randf_range(5.0, 7.0), randf_range(0.0, 3.0), randf_range(5.0, 8.0) * (1 if randf() < 0.5 else -1))
	# hongos luminosos: la única zona segura contra la oscuridad
	var lights: Array = []
	for m in [[Vector3(-2.0, 0, 2.2), false], [Vector3(2.6, 0, -5.5), false], [Vector3(3.0, 6.0, -11.0), true],
			[Vector3(-3.0, 6.0, -20.5), true], [Vector3(2.6, 0, -29.5), false]]:
		U.mushroom(lv, m[0], 2.8, m[1])
		lights.append(m[0])
	lv.custom.lights = lights
	lv.custom.dark_t = 0.0
	lv.custom.tick = func(d: float): _hoyo3_tick(lv, d)
	lv.hud.dark_show()
	clock(lv, Vector3(-2.2, 5.2, -12.0), true)
	clock(lv, Vector3(2.2, 5.2, -21.0), true)
	jump_pad(lv, Vector3(-2.2, 0, -28.5), 7.0)
	# rocas y estalactitas de la cueva
	for k in 14:
		var r := Node3D.new()
		r.position = Vector3(randf_range(-25, 25), randf_range(-8, 14), randf_range(-45, 10))
		if absf(r.position.x) < 8:
			r.position.x += 16 * signf(r.position.x + 0.01)
		lv.add_child(r)
		B.rock(r, Vector3.ZERO, randf_range(1.0, 2.5), Color(0.35, 0.3, 0.27))
		B.add_mesh(r, B.cyl_mesh(0.0, 0.5, randf_range(1.5, 3.0), 6), B.mat(Color(0.4, 0.34, 0.3)), Vector3(0, -1.5, 0), Vector3(PI, 0, 0))


static func _hoyo3_tick(lv, d: float) -> void:
	var c: Dictionary = lv.custom
	if not (lv.state in [AIM, MOVING]):
		return
	var bp: Vector3 = lv.ball.global_position
	var lit := false
	for p in c.lights:
		if (p as Vector3).distance_to(bp) < 2.8:
			lit = true
			break
	c.dark_t = 0.0 if lit else c.dark_t + d
	lv.hud.dark_set(c.dark_t / 10.0)
	# la bomba tiembla cuando quedan 3 s
	lv.ball.mesh_inst.position = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.03 if c.dark_t > 7.0 else Vector3.ZERO
	if c.dark_t > 7.0:
		lv.tag_requests["dark"] = ["¡LUZ!", Color(0.6, 1, 0.9)]
	if c.dark_t >= 10.0 and lv.try_capture():
		c.dark_t = 0.0
		_bats_take(lv)


static func _bats_take(lv) -> void:
	Game.stats.bats += 1
	var ball: Node3D = lv.ball
	ball.mesh_inst.position = Vector3.ZERO
	lv.hud.dark_set(1.0)
	Sfx.play("squeak", 0.1, -2.0, 1.6)
	var bats: Array = []
	for k in 7:
		var bt := U.bat(lv)
		var a := k * TAU / 7
		bt.global_position = ball.global_position + Vector3(cos(a) * 3.0, 1.5, sin(a) * 3.0)
		bats.append(bt)
	var from := ball.global_position
	var to := from + Vector3(randf_range(-1, 1) * 18.0, 9.0, -6.0)
	var tw: Tween = lv.create_tween()
	tw.tween_method(func(k: float): _bats_step(bats, ball, from, to, k), 0.0, 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	for bt in bats:
		(bt as Node).queue_free()
	ball.visible = false
	lv.hud.dark_set(0.0)
	lv.finish_capture("¡A LA OSCURIDAD!", "Los murciélagos se llevaron tu bomba. Busca los hongos.", Color(0.75, 0.6, 1.0))


static func _bats_step(bats: Array, ball: Node3D, from: Vector3, to: Vector3, k: float) -> void:
	var lift := clampf((k - 0.35) / 0.65, 0.0, 1.0)
	var c := from.lerp(to, lift)
	if lift > 0.0:
		ball.global_position = c
	for i in bats.size():
		var a := i * TAU / bats.size() + k * 14.0
		var r := lerpf(3.0, 0.45, clampf(k / 0.35, 0.0, 1.0))
		(bats[i] as Node3D).global_position = c + Vector3(cos(a) * r, 0.35 + sin(k * 30.0 + i) * 0.1, sin(a) * r)


# =====================================================================
# HOYO 4 — "El Manglar": agua, troncos, águila pescadora y Don Coco.
# =====================================================================
static func _hoyo4(lv) -> void:
	var g: CSGCombiner3D = lv.ground
	lv.tee_pos = Vector3(0, 0.3, 3)
	var gm: ShaderMaterial = g.material_override
	gm.set_shader_parameter("grass_a", Color(0.3, 0.45, 0.25))
	gm.set_shader_parameter("grass_b", Color(0.27, 0.41, 0.22))
	gm.set_shader_parameter("green_col", Color(0.42, 0.68, 0.33))
	gm.set_shader_parameter("dirt_col", Color(0.33, 0.25, 0.17))
	gm.set_shader_parameter("dirt_dark", Color(0.24, 0.17, 0.11))
	var mud := Color(0.3, 0.22, 0.15)
	B.fairway(g, Vector3(0, 0, 1), Vector2(8, 8), "lrb")
	island_under(lv, Vector3(0, 0, 1), Vector2(8, 8), mud)
	# agua del manglar (con Don Coco)
	B.csg_box(g, Vector3(12, 1, 14), Vector3(0, -1.3, -10))
	B.csg_box(g, Vector3(0.4, 1.15, 14), Vector3(-5.8, -0.225, -10))
	B.csg_box(g, Vector3(0.4, 1.15, 14), Vector3(5.8, -0.225, -10))
	var water: Area3D = B.liquid(lv, lv, Vector3(0, -0.3, -10), Vector2(11.2, 14), "water")
	water.set_meta("don_coco", true)
	island_under(lv, Vector3(0, -1, -10), Vector2(12, 14), mud)
	var wood := Color(0.45, 0.32, 0.2)
	var pa := mover(lv, Vector3(0, -0.25, -5.6), "slide", [[Vector3(3.2, 0.5, 5.2), Vector3.ZERO, wood]], {"offset": Vector3(3.3, 0, 0), "period": 4.6})
	var pb := mover(lv, Vector3(0, -0.25, -12.6), "slide", [[Vector3(3.2, 0.5, 8.8), Vector3.ZERO, wood]], {"offset": Vector3(3.3, 0, 0), "period": 3.7, "phase": 1.3})
	for p in [pa, pb]:
		var l: float = 5.0 if p == pa else 8.6
		for k in 3:
			B.add_mesh(p, B.cyl_mesh(0.27, 0.27, l, 10), B.mat(Color(0.4, 0.28, 0.17)), Vector3(-1.0 + k * 1.0, 0.17, 0), Vector3(PI / 2, 0, 0))
	# zona de la águila pescadora (ráfagas al aletear)
	B.fairway(g, Vector3(0, 0, -24), Vector2(8, 14), "lr")
	island_under(lv, Vector3(0, 0, -24), Vector2(8, 14), mud)
	var wz: Area3D = lv.add_zone(Vector3(0, 0.8, -24), Vector3(8, 1.6, 6), "wind", {"force": Vector3.ZERO})
	B.add_mesh(lv, B.cyl_mesh(0.18, 0.22, 3.0, 8), B.mat(Color(0.4, 0.3, 0.2)), Vector3(-5.2, 1.5, -24))
	var perch = OspreyScript.new()
	perch.mode = "perch"
	perch.gust = Vector3(6.0, 0, 0)
	perch.gust_zone = wz
	perch.position = Vector3(-5.2, 3.4, -24)
	perch.rotation.y = PI / 2
	lv.add_child(perch)
	side_sign(lv, Vector3(-8.0, 0, -18.0), "ÁGUILA PESCADORA: ESPERA A QUE DEJE DE ALETEAR", 0.45, Color(0.3, 0.45, 0.25))
	side_sign(lv, Vector3(7.2, 0, 2.0), "MANGLAR: ÁREA PROTEGIDA (DE TI)", -0.45, Color(0.3, 0.45, 0.25))
	jump_pad(lv, Vector3(2.4, 0, -1.6), 8.5, Vector3(0, 0, -6.0))
	clock(lv, Vector3(0, 1.4, -9.0))
	clock(lv, Vector3(-2.5, 0.7, -25.0))
	clock(lv, Vector3(0, 3.0, -40.0))
	# corriente (turbo) y raíz-rampa
	lv.add_zone(Vector3(0, 0.4, -29.3), Vector3(3.5, 0.8, 2.2), "boost", {"dir": Vector3(0, 0, -1)})
	glow_pad(lv, Vector3(0, 0.02, -29.3), Vector2(3.5, 2.2), Color(0.3, 0.75, 1.0), true)
	var a := atan2(4.0, 13.0)
	var n := Vector3(0, cos(a), sin(a))
	var mid := Vector3(0, 2.0, -37.5)
	B.csg_box(g, Vector3(4, 1, 14.0), mid - n * 0.5, Vector3(a, 0, 0))
	B.csg_box(g, Vector3(0.4, 0.35, 14.0), mid + n * 0.175 + Vector3(-1.8, 0, 0), Vector3(a, 0, 0))
	B.csg_box(g, Vector3(0.4, 0.35, 14.0), mid + n * 0.175 + Vector3(1.8, 0, 0), Vector3(a, 0, 0))
	for k in 5:
		var z := -32.0 - k * 2.6
		for sx in [-2.4, 2.4]:
			B.add_mesh(lv, B.cyl_mesh(0.09, 0.11, 2.2, 6), B.mat(Color(0.42, 0.33, 0.25)), Vector3(sx, 0.8 + k * 0.8, z), Vector3(0, 0, -0.6 * signf(sx)))
	# meseta final con un ibis rondando el hoyo
	B.fairway(g, Vector3(0, 4, -50), Vector2(10, 12), "lrf")
	island_under(lv, Vector3(0, 4, -50), Vector2(10, 12), mud)
	lv.make_hole(Vector3(0, 4, -52.5))
	ibis(lv, {"mode": "circle", "center": Vector3(0, 4, -52.5), "radius": 2.3, "period": 7.0})
	# águila en picada sobre el agua y la zona del viento
	var diver = OspreyScript.new()
	diver.mode = "diver"
	diver.level = lv
	diver.area = Rect2(-5.5, -30.0, 11.0, 28.0)
	diver.ground_y = 0.0
	lv.add_child(diver)
	# manglares alrededor
	for p in [Vector3(-9, -0.5, -4), Vector3(9, -0.5, -12), Vector3(-9, -0.5, -18), Vector3(8.5, -0.5, -28), Vector3(-8, 1.5, -46), Vector3(8, 1.5, -50),
			Vector3(-14, -1, 6), Vector3(15, -1, -40), Vector3(0, 2, -62)]:
		U.mangrove(lv, p, randf_range(0.9, 1.4))
	var swamp := PlaneMesh.new()
	swamp.size = Vector2(90, 110)
	B.add_mesh(lv, swamp, B.shader_mat("res://shaders/water.gdshader", {"deep": Color(0.1, 0.25, 0.18), "shallow": Color(0.25, 0.45, 0.3), "wave": 0.03}), Vector3(0, -1.6, -25))
	for k in 6:
		crab_deco(lv, Vector3(randf_range(-4, 4), 0.0, randf_range(-1, 4)) if k < 2 else Vector3(randf_range(-4, 4), 4.0, randf_range(-55, -46)))


## Cangrejito decorativo (no hace nada, solo camina de lado).
static func crab_deco(lv, pos: Vector3) -> void:
	var c: Dictionary = U.crab(lv, randf() < 0.5)
	var n: Node3D = c.node
	n.scale = Vector3.ONE * 0.4
	n.position = pos
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "position:x", pos.x + 1.2, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position:x", pos.x - 1.2, 1.4).set_trans(Tween.TRANS_SINE)


# =====================================================================
# HOYO 5 — JEFE FINAL: la sala de SIGMAA (arena circular, trono y pantalla gigante).
# =====================================================================
static func _hoyo5(lv) -> void:
	var g: CSGCombiner3D = lv.ground
	var center := Vector3(0, 0, -1)
	lv.tee_pos = Vector3(0, 0.3, 11.5)
	lv.walking_hole = true
	lv.custom.arena_center = center
	var gm: ShaderMaterial = g.material_override
	gm.set_shader_parameter("grass_a", Color(0.37, 0.38, 0.43))
	gm.set_shader_parameter("grass_b", Color(0.33, 0.34, 0.39))
	gm.set_shader_parameter("dirt_col", Color(0.24, 0.25, 0.3))
	gm.set_shader_parameter("dirt_dark", Color(0.17, 0.18, 0.22))
	gm.set_shader_parameter("stripe_scale", 0.35)
	for c in lv.get_children():
		if c is WorldEnvironment:
			(c as WorldEnvironment).environment.ambient_light_energy = 0.45
	# arena circular con borde (la bomba no se puede caer)
	B.csg_cyl(g, 15.5, 2.0, center + Vector3(0, -1.0, 0), false, null, 48)
	B.csg_cyl(g, 16.0, 0.45, center + Vector3(0, 0.22, 0), false, null, 48)
	B.csg_cyl(g, 15.5, 0.6, center + Vector3(0, 0.31, 0), true, null, 48)
	island_under(lv, center, Vector2(26, 26), Color(0.2, 0.21, 0.26))
	# líneas azules del piso (se ponen rojas cuando viene un ataque)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.3, 0.6, 1.0)
	lm.emission_enabled = true
	lm.emission = Color(0.3, 0.6, 1.0)
	lm.emission_energy_multiplier = 2.2
	lv.custom.lines_mat = lm
	for r in [4.5, 9.5, 14.6]:
		var tor := TorusMesh.new()
		tor.inner_radius = r - 0.08
		tor.outer_radius = r
		tor.rings = 64
		var mi := B.add_mesh(lv, tor, lm, center + Vector3(0, 0.01, 0), Vector3.ZERO, Vector3(1, 0.05, 1))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 8:
		var a := k * TAU / 8 + PI / 8
		var d := Vector3(sin(a), 0, cos(a))
		var mi := B.add_mesh(lv, B.box_mesh(Vector3(0.12, 0.02, 10.0)), lm, center + d * 9.6 + Vector3(0, 0.01, 0), Vector3(0, a, 0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# obeliscos alrededor (sirven de cobertura contra las ametralladoras)
	var stone := Color(0.42, 0.43, 0.48)
	for deg in [35, 70, 110, 145, 215, 250, 290, 325]:
		var a := deg_to_rad(float(deg))
		var p := center + Vector3(sin(a), 0, cos(a)) * 13.2
		var sb := B.static_box(lv, Vector3(1.1, 4.5, 1.1), p + Vector3(0, 2.25, 0), stone, Vector3(0, -a, 0))
		B.add_mesh(sb, B.cyl_mesh(0.0, 0.78, 1.3, 4), B.mat(stone), Vector3(0, 2.9, 0), Vector3(0, PI / 4, 0))
		B.add_mesh(sb, B.box_mesh(Vector3(0.12, 3.6, 0.04)), lm, Vector3(0, 0, 0.57))
		B.add_mesh(sb, B.box_mesh(Vector3(0.12, 3.6, 0.04)), lm, Vector3(0, 0, -0.57))
		B.add_mesh(lv, B.cyl_mesh(0.0, 0.35, 1.8, 5), B.mat(Color(0.5, 0.75, 1.0, 0.85), 0.2, 1.2), p + Vector3(0.9, 0.9, 0), Vector3(0, 0, -0.2))
	clock(lv, center + Vector3(9.0, 0.7, 0))
	clock(lv, center + Vector3(-9.0, 0.7, 0))
	clock(lv, center + Vector3(0, 0.7, -9.5))
	# escalinata de entrada (decorativa, al frente)
	for k in 5:
		B.add_mesh(lv, B.box_mesh(Vector3(9.0, 0.4, 1.2)), B.mat(Color(0.35, 0.36, 0.41)), Vector3(0, -0.2 - k * 0.4, 15.6 + k * 1.2))
	# piso de la sala, paredes, trono y pantalla
	B.add_mesh(lv, B.box_mesh(Vector3(70, 1, 70)), B.mat(Color(0.12, 0.13, 0.17)), Vector3(0, -2.6, -6))
	var wall := B.mat(Color(0.2, 0.21, 0.26))
	B.add_mesh(lv, B.box_mesh(Vector3(64, 26, 2)), wall, Vector3(0, 10, -31))
	for sx in [-1.0, 1.0]:
		B.add_mesh(lv, B.box_mesh(Vector3(2, 26, 52)), wall, Vector3(sx * 31, 10, -6))
		for k in 5:
			B.add_mesh(lv, B.box_mesh(Vector3(2.4, 26, 2.4)), B.mat(Color(0.16, 0.17, 0.21)), Vector3(sx * 29.5, 10, -26 + k * 9))
	# trono sobre su plataforma con agujas de cristal
	var throne := center + Vector3(0, 2.0, -19.5)
	for k in 4:
		B.add_mesh(lv, B.cyl_mesh(6.0 - k * 1.1, 6.2 - k * 1.1, 0.55, 24), B.mat(Color(0.33, 0.34, 0.4)), center + Vector3(0, -0.6 + k * 0.55, -20.5))
	B.add_mesh(lv, B.box_mesh(Vector3(2.4, 0.6, 1.8)), B.mat(Color(0.3, 0.31, 0.36)), throne + Vector3(0, 0.3, -0.2))
	B.add_mesh(lv, B.box_mesh(Vector3(2.4, 3.4, 0.5)), B.mat(Color(0.3, 0.31, 0.36)), throne + Vector3(0, 1.7, -1.0))
	B.add_mesh(lv, B.box_mesh(Vector3(0.1, 2.8, 0.06)), lm, throne + Vector3(0, 1.7, -0.74))
	for k in 7:
		var a := -1.2 + k * 0.4
		var h := 3.5 + (3 - absf(k - 3)) * 1.3
		B.add_mesh(lv, B.cyl_mesh(0.0, 0.55, h, 5), B.mat(Color(0.45, 0.47, 0.55), 0.3), throne + Vector3(sin(a) * 3.2, h / 2 - 0.2, -cos(a) * 3.2 + 0.5))
		B.add_mesh(lv, B.box_mesh(Vector3(0.06, h * 0.6, 0.06)), lm, throne + Vector3(sin(a) * 3.2, h / 2 - 0.2, -cos(a) * 3.2 + 1.0))
	lv.custom.throne_pos = throne + Vector3(0, 0.6, 0.1)
	_sigmaa_screen(lv, Vector3(0, 13, -29.8))
	# estandartes con el emblema de tortuga
	for p in [[Vector3(-17, 12, -29.8), 0.0], [Vector3(17, 12, -29.8), 0.0], [Vector3(-29.8, 11, -12), PI / 2], [Vector3(29.8, 11, -12), -PI / 2]]:
		_banner(lv, p[0], p[1])
	# racks de servidores, escritorios y faroles
	for sx in [-1.0, 1.0]:
		for k in 6:
			_rack(lv, Vector3(sx * 21.5, -2.1, -22 + k * 4.2))
		for k in 3:
			_desk(lv, Vector3(sx * 18.0, -2.1, -8 + k * 7.0), PI / 2 * sx)
		for k in 3:
			var lp := Vector3(sx * 17.0, 1.5, -18 + k * 12.0)
			B.add_mesh(lv, B.box_mesh(Vector3(0.35, 0.5, 0.35)), B.mat(Color(1, 0.75, 0.4), 0.5, 3.0), lp)
			var l := OmniLight3D.new()
			l.light_color = Color(1, 0.72, 0.4)
			l.omni_range = 11.0
			l.light_energy = 1.4
			l.position = lp
			lv.add_child(l)
	var cl := OmniLight3D.new()
	cl.light_color = Color(0.45, 0.65, 1.0)
	cl.omni_range = 26.0
	cl.light_energy = 1.2
	cl.position = Vector3(0, 9, -24)
	lv.add_child(cl)
	# la tortuga en su trono y el mecha
	var pilot := U.sigmaa_turtle(lv)
	pilot.position = lv.custom.throne_pos
	var boss = BossScript.new()
	boss.level = lv
	boss.pilot = pilot
	boss.position = center
	boss.visible = false
	lv.add_child(boss)
	lv.hole_node = boss
	lv.hole_pos = center
	lv.custom.boss = boss
	lv.custom.cinematic = func(): await boss.intro()


static func _sigmaa_screen(lv, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	lv.add_child(n)
	var w := 24.0
	var h := 9.0
	B.add_mesh(n, B.box_mesh(Vector3(w + 0.8, h + 0.8, 0.3)), B.mat(Color(0.1, 0.12, 0.2), 0.4, 0.0, 0.6))
	B.add_mesh(n, B.box_mesh(Vector3(w, h, 0.32)), B.mat(Color(0.86, 0.9, 0.98), 0.6, 0.6))
	B.add_mesh(n, B.box_mesh(Vector3(w, 2.0, 0.34)), B.mat(Color(0.12, 0.35, 0.85), 0.5, 1.0), Vector3(0, h / 2 - 1.0, 0))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.6, 0.75, 1.0)
	glow.omni_range = 18.0
	glow.light_energy = 1.2
	glow.position = Vector3(0, 0, 4)
	n.add_child(glow)
	_label3d(n, "SIGMAA", Vector3(-w / 2 + 3.6, h / 2 - 0.75, 0.2), 150, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_LEFT)
	_label3d(n, "Servicios Escolares", Vector3(-w / 2 + 3.6, h / 2 - 1.55, 0.2), 70, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	B.add_mesh(n, B.sphere_mesh(0.55, 12), B.mat(Color(1, 1, 1), 0.5, 1.0), Vector3(-w / 2 + 1.8, h / 2 - 1.0, 0.25), Vector3.ZERO, Vector3(1, 0.8, 0.2))
	var items := ["Oferta\nAcadémica", "Kárdex", "Historial\nAcadémico", "Horario /\nB. Boleta", "Inscripción /\nReinscripción", "Sistema\nPagos"]
	for i in items.size():
		_label3d(n, items[i], Vector3(1.0 + i * 2.0, h / 2 - 1.0, 0.2), 40, Color(1, 1, 1))
	_label3d(n, "Terminar Sesión     ·     GAEL ALBERTO NAVARRETE PACHECO     ·     9:59", Vector3(-w / 2 + 0.6, h / 2 - 2.6, 0.2), 48, Color(0.15, 0.3, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	var body := _label3d(n, "espere un momento...", Vector3(0, -0.6, 0.2), 64, Color(0.25, 0.45, 0.85))
	lv.custom.screen_body = body
	var tor := TorusMesh.new()
	tor.inner_radius = 0.45
	tor.outer_radius = 0.6
	var sp := B.add_mesh(n, tor, B.mat(Color(0.25, 0.5, 0.95), 0.5, 1.0), Vector3(0, -1.9, 0.25), Vector3(PI / 2, 0, 0))
	var tw := sp.create_tween().set_loops()
	tw.tween_property(sp, "rotation:y", TAU, 1.0).as_relative()


static func _label3d(parent: Node, text: String, pos: Vector3, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = col
	l.outline_size = 0
	l.horizontal_alignment = align
	l.position = pos
	parent.add_child(l)
	return l


static func _banner(lv, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	lv.add_child(n)
	B.add_mesh(n, B.cyl_mesh(0.1, 0.1, 3.4, 8), B.mat(Color(0.6, 0.45, 0.2), 0.3, 0.0, 0.8), Vector3(0, 3.1, 0.15), Vector3(0, 0, PI / 2))
	B.add_mesh(n, B.box_mesh(Vector3(2.8, 6.0, 0.08)), B.mat(Color(0.1, 0.17, 0.42)), Vector3(0, 0, 0.1))
	B.add_mesh(n, B.box_mesh(Vector3(2.9, 0.12, 0.1)), B.mat(Color(0.8, 0.65, 0.3), 0.3, 0.0, 0.8), Vector3(0, -3.0, 0.1))
	var white := B.mat(Color(0.88, 0.9, 0.95))
	B.add_mesh(n, B.sphere_mesh(0.7, 12), white, Vector3(0, 0.6, 0.16), Vector3.ZERO, Vector3(1, 1.15, 0.1))
	B.add_mesh(n, B.sphere_mesh(0.25, 10), white, Vector3(0, 1.65, 0.16), Vector3.ZERO, Vector3(1, 1, 0.1))
	for sx in [-1.0, 1.0]:
		for sy in [0.2, 1.1]:
			B.add_mesh(n, B.box_mesh(Vector3(0.55, 0.22, 0.04)), white, Vector3(sx * 0.75, sy, 0.16), Vector3(0, 0, sx * (0.5 if sy > 0.5 else -0.5)))


static func _rack(lv, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	lv.add_child(n)
	B.add_mesh(n, B.box_mesh(Vector3(1.4, 3.2, 1.4)), B.mat(Color(0.08, 0.09, 0.12), 0.4, 0.0, 0.5), Vector3(0, 1.6, 0))
	for k in 7:
		var led := B.mat(Color(0.3, 0.6, 1.0) if k % 3 else Color(1, 0.6, 0.2), 0.5, 2.5)
		for side in [-1.0, 1.0]:
			var mi := B.add_mesh(n, B.box_mesh(Vector3(0.05, 0.06, 0.06)), led, Vector3(side * 0.71, 0.4 + k * 0.38, randf_range(-0.4, 0.4)))
			var tw := mi.create_tween().set_loops()
			tw.tween_property(mi, "visible", false, randf_range(0.2, 1.2))
			tw.tween_property(mi, "visible", true, randf_range(0.2, 1.2))


static func _desk(lv, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	lv.add_child(n)
	var wood := B.mat(Color(0.35, 0.24, 0.15))
	B.add_mesh(n, B.box_mesh(Vector3(2.2, 0.1, 1.0)), wood, Vector3(0, 1.0, 0))
	for sx in [-1.0, 1.0]:
		B.add_mesh(n, B.box_mesh(Vector3(0.1, 1.0, 0.9)), wood, Vector3(sx * 1.0, 0.5, 0))
	B.add_mesh(n, B.box_mesh(Vector3(0.8, 0.55, 0.05)), B.mat(Color(0.3, 0.55, 1.0), 0.4, 1.8), Vector3(-0.4, 1.4, -0.2))
	B.add_mesh(n, B.box_mesh(Vector3(0.1, 0.3, 0.1)), B.mat(Color(0.15, 0.15, 0.17)), Vector3(-0.4, 1.15, -0.2))
	for k in 3:
		B.add_mesh(n, B.box_mesh(Vector3(0.45, 0.12, 0.32)), B.mat([Color(0.6, 0.2, 0.15), Color(0.2, 0.35, 0.6), Color(0.75, 0.65, 0.4)][k]), Vector3(0.6, 1.11 + k * 0.12, 0.1), Vector3(0, k * 0.2, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.75, 0.45)
	l.omni_range = 3.0
	l.light_energy = 0.8
	l.position = Vector3(0.6, 1.6, 0)
	n.add_child(l)
