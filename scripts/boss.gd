extends AnimatableBody3D
## JEFE FINAL: el mecha tortuga de SIGMAA.
## - Camina lento disparando (ametralladoras), lanza misiles, da saltos con daño en área
##   y hace el "golpe a dos manos": queda agachado y vulnerable unos segundos.
## - Vulnerable: la cola baja como rampa hasta la espalda, donde está la tortuga (el hoyo,
##   con bandera y aro luminoso). Tiro rodando: sube por la cola. Tiro en arco: cae directo.
## - Cada golpe: la bomba explota, sale volando a un lugar seguro detrás del jefe, y el mecha
##   se vuelve más rápido, usa menos el golpe a dos manos y aprende ataques (la mira roja).

const B = preload("res://scripts/build.gd")
const U = preload("res://scripts/unicaribe.gd")
const CineScript = preload("res://scripts/cinematic.gd")

const H_STAND := 2.0
const H_CROUCH := 0.8
const CROUCH_A := 1.396          # 80° de inclinación del torso al agacharse
const ARENA_R := 11.0            # radio por donde camina el mecha
const AIM := 0
const MOVING := 1
const EVENT := 2
const DONE := 3

var level
var fighting := false
var hp := 3
var phase := 0
var vulnerable := false
var _hit_lock := false
var _since_pound := 0
var _walking := false
var _gun_on := false
var _gun_cd := 0.0
var _walk_t := 0.0
var _face := true
var _bullets: Array = []
var _missiles: Array = []
var _hit_done := false

# pose (0 = de pie, 1 = agachado), brazos arriba (preparar golpe), pose de presentación
var pose := 0.0
var arms_up := 0.0
var flex := 0.0
var bob := 0.0

# partes del modelo
var vis: Node3D
var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var tail: Node3D
var seat: Node3D
var hole_vis: Node3D
var muzzle_l: Node3D
var muzzle_r: Node3D
var glow_mat: StandardMaterial3D
var ring_mat: StandardMaterial3D
var ramp_vis: MeshInstance3D
var pilot: Node3D

# colisiones
var cs_stand: CollisionShape3D
var cs_crouch: Array[CollisionShape3D] = []
var back_area: Area3D

var cam: Camera3D
var cine


# =========================================================== construcción
func _ready() -> void:
	sync_to_physics = true
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.8
	physics_material_override = pm
	_build_model()
	_build_collision()
	# luz propia para que el mecha se lea bien en la sala oscura
	var key := OmniLight3D.new()
	key.light_color = Color(1, 0.92, 0.85)
	key.omni_range = 9.0
	key.light_energy = 1.6
	key.position = Vector3(0, 5.5, 3.5)
	add_child(key)
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.4, 0.75, 1.0)
	rim.omni_range = 8.0
	rim.light_energy = 1.4
	rim.position = Vector3(0, 4.5, -3.5)
	add_child(rim)
	_apply_pose()


func _m(c: Color, rough := 0.5, metal := 0.4) -> StandardMaterial3D:
	return B.mat(c, rough, 0.0, metal)


func _build_model() -> void:
	var dark := _m(Color(0.17, 0.17, 0.19))
	var black := _m(Color(0.08, 0.08, 0.09), 0.4)
	var beige := _m(Color(0.86, 0.72, 0.55), 0.7, 0.1)
	var metal := _m(Color(0.35, 0.35, 0.38), 0.3, 0.9)
	glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1, 0.5, 0.1)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1, 0.45, 0.08)
	glow_mat.emission_energy_multiplier = 2.5
	vis = Node3D.new()
	add_child(vis)
	hips = Node3D.new()
	vis.add_child(hips)
	torso = Node3D.new()
	hips.add_child(torso)
	# cuerpo
	B.add_mesh(torso, B.box_mesh(Vector3(1.9, 2.3, 1.5)), dark, Vector3(0, 1.15, 0))
	for i in 4:
		B.add_mesh(torso, B.box_mesh(Vector3(1.45 - i * 0.08, 0.48, 0.16)), beige, Vector3(0, 0.3 + i * 0.52, 0.8))
	B.add_mesh(torso, B.box_mesh(Vector3(0.12, 2.0, 0.17)), beige, Vector3(0, 1.1, 0.8))
	# caparazón segmentado en la espalda
	B.add_mesh(torso, B.sphere_mesh(1.0, 18), black, Vector3(0, 1.2, -0.75), Vector3.ZERO, Vector3(1.3, 1.35, 0.75))
	for ix in [-0.48, 0.48]:
		for iy in [0.55, 1.2, 1.85]:
			B.add_mesh(torso, B.box_mesh(Vector3(0.75, 0.55, 0.16)), dark, Vector3(ix, iy, -1.38), Vector3(0, 0, 0))
	for iy in [0.88, 1.53]:
		B.add_mesh(torso, B.box_mesh(Vector3(1.6, 0.06, 0.1)), glow_mat, Vector3(0, iy, -1.46))
	for sx in [-1.0, 1.0]:
		B.add_mesh(torso, B.box_mesh(Vector3(0.25, 2.2, 1.0)), black, Vector3(sx * 1.18, 1.15, -0.55))
		B.add_mesh(torso, B.box_mesh(Vector3(0.08, 1.4, 0.08)), glow_mat, Vector3(sx * 1.32, 1.2, -0.5))
	# asiento de la tortuga (el hoyo) en la espalda
	seat = Node3D.new()
	seat.position = Vector3(0, 1.25, -1.55)
	seat.rotation.x = -PI / 2      # el "arriba" del asiento apunta hacia afuera del caparazón
	torso.add_child(seat)
	hole_vis = Node3D.new()
	seat.add_child(hole_vis)
	ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.9, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.3, 0.9, 1.0)
	ring_mat.emission_energy_multiplier = 3.0
	var tor := TorusMesh.new()
	tor.inner_radius = 0.62
	tor.outer_radius = 0.78
	B.add_mesh(hole_vis, tor, ring_mat, Vector3(0, 0.05, 0))
	B.add_mesh(hole_vis, B.cyl_mesh(0.62, 0.62, 0.04, 24), _m(Color(0.02, 0.02, 0.03)), Vector3(0, 0.04, 0))
	B.flag(hole_vis, Vector3(0.6, -0.65, 0.3), Color(0.25, 0.75, 1.0))
	hole_vis.visible = false
	# hombreras
	for sx in [-1.0, 1.0]:
		B.add_mesh(torso, B.box_mesh(Vector3(0.95, 0.6, 1.3)), dark, Vector3(sx * 1.2, 2.2, 0))
		B.add_mesh(torso, B.box_mesh(Vector3(0.3, 0.12, 0.3)), glow_mat, Vector3(sx * 1.45, 2.53, 0.35))
	# cabeza de tortuga con pico
	head = Node3D.new()
	head.position = Vector3(0, 2.35, 0.45)
	torso.add_child(head)
	B.add_mesh(head, B.box_mesh(Vector3(0.85, 0.65, 0.95)), dark, Vector3(0, 0.3, 0.3))
	B.add_mesh(head, B.box_mesh(Vector3(0.7, 0.25, 0.5)), beige, Vector3(0, 0.05, 0.6))
	B.add_mesh(head, B.box_mesh(Vector3(0.55, 0.3, 0.45)), black, Vector3(0, 0.35, 0.85), Vector3(0.5, 0, 0))
	B.add_mesh(head, B.box_mesh(Vector3(0.3, 0.18, 0.2)), glow_mat, Vector3(0, 0.27, 1.07), Vector3(0.5, 0, 0))
	for sx in [-0.25, 0.25]:
		B.add_mesh(head, B.box_mesh(Vector3(0.22, 0.09, 0.05)), glow_mat, Vector3(sx, 0.45, 0.79))
	# brazos enormes con ametralladoras
	var arms: Array = []
	for sx in [-1.0, 1.0]:
		var a := Node3D.new()
		a.position = Vector3(sx * 1.35, 1.95, 0)
		torso.add_child(a)
		B.add_mesh(a, B.box_mesh(Vector3(0.7, 1.1, 0.75)), black, Vector3(0, -0.55, 0))
		var fore := Node3D.new()
		fore.position = Vector3(0, -1.1, 0)
		a.add_child(fore)
		B.add_mesh(fore, B.box_mesh(Vector3(0.95, 1.2, 0.95)), dark, Vector3(0, -0.6, 0))
		B.add_mesh(fore, B.box_mesh(Vector3(0.7, 0.8, 0.1)), beige, Vector3(0, -0.6, 0.5))
		B.add_mesh(fore, B.box_mesh(Vector3(1.05, 0.45, 1.05)), black, Vector3(0, -1.35, 0))
		for k in 3:
			B.add_mesh(fore, B.cyl_mesh(0.0, 0.11, 0.35, 5), metal, Vector3(-0.3 + k * 0.3, -1.7, 0.3), Vector3(PI, 0, 0))
		for gx in [-0.18, 0.18]:
			B.add_mesh(fore, B.cyl_mesh(0.09, 0.09, 0.8, 8), metal, Vector3(gx, -0.75, 0.6), Vector3(PI / 2, 0, 0))
		var mz := Node3D.new()
		mz.position = Vector3(0, -0.75, 1.05)
		fore.add_child(mz)
		arms.append(a)
		if sx < 0:
			muzzle_l = mz
		else:
			muzzle_r = mz
	arm_l = arms[0]
	arm_r = arms[1]
	# piernas
	var legs: Array = []
	for sx in [-1.0, 1.0]:
		var l := Node3D.new()
		l.position = Vector3(sx * 0.65, H_STAND, 0)
		vis.add_child(l)
		B.add_mesh(l, B.box_mesh(Vector3(0.8, 1.0, 0.85)), black, Vector3(0, -0.5, 0))
		var shin := Node3D.new()
		shin.name = "Shin"
		shin.position = Vector3(0, -1.0, 0)
		l.add_child(shin)
		B.add_mesh(shin, B.box_mesh(Vector3(0.85, 0.85, 0.95)), dark, Vector3(0, -0.45, 0))
		B.add_mesh(shin, B.box_mesh(Vector3(0.5, 0.4, 0.12)), beige, Vector3(0, -0.2, 0.5))
		B.add_mesh(shin, B.box_mesh(Vector3(1.0, 0.25, 1.35)), black, Vector3(0, -0.88, 0.15))
		legs.append(l)
	leg_l = legs[0]
	leg_r = legs[1]
	# cola (en la pose agachada baja hasta el suelo: es la rampa)
	tail = Node3D.new()
	vis.add_child(tail)
	for i in 4:
		var s := 1.0 - i * 0.18
		B.add_mesh(tail, B.box_mesh(Vector3(0.8 * s, 0.45 * s, 1.0)), dark if i % 2 == 0 else black, Vector3(0, 0, -0.5 - i * 0.95))
		B.add_mesh(tail, B.box_mesh(Vector3(0.2 * s, 0.08, 0.6)), glow_mat, Vector3(0, 0.25 * s, -0.5 - i * 0.95))


func _crouch_xf() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, CROUCH_A), Vector3(0, H_CROUCH, 0))


func _add_cs(shape: Shape3D, xf: Transform3D, disabled: bool) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = xf
	cs.disabled = disabled
	add_child(cs)
	return cs


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


func _build_collision() -> void:
	cs_stand = _add_cs(_box(Vector3(2.6, 4.6, 2.4)), Transform3D(Basis(), Vector3(0, 2.3, 0)), false)
	var tc := _crouch_xf()
	# plataforma del caparazón (con bordes laterales y al frente)
	cs_crouch.append(_add_cs(_box(Vector3(2.3, 2.3, 0.3)), tc * Transform3D(Basis(), Vector3(0, 1.2, -1.4)), true))
	for sx in [-1.2, 1.2]:
		cs_crouch.append(_add_cs(_box(Vector3(0.2, 2.3, 0.7)), tc * Transform3D(Basis(), Vector3(sx, 1.2, -1.7)), true))
	cs_crouch.append(_add_cs(_box(Vector3(2.6, 0.25, 0.8)), tc * Transform3D(Basis(), Vector3(0, 2.35, -1.75)), true))
	# cuerpo debajo (para que la bomba no se meta abajo)
	cs_crouch.append(_add_cs(_box(Vector3(2.4, 2.1, 3.3)), Transform3D(Basis(), Vector3(0, 1.05, 1.35)), true))
	# rampa de la cola: del suelo atrás hasta el borde trasero del caparazón
	var top: Vector3 = tc * Vector3(0, 0.05, -1.55)
	var bottom := Vector3(0, 0.0, top.z - 6.5)
	var dir := (top - bottom).normalized()
	var basis := Basis.looking_at(dir, Vector3.UP)
	var mid := (top + bottom) * 0.5 - basis.y * 0.15
	var length := top.distance_to(bottom) + 0.4
	cs_crouch.append(_add_cs(_box(Vector3(2.0, 0.3, length)), Transform3D(basis, mid), true))
	for sx in [-1.05, 1.05]:
		cs_crouch.append(_add_cs(_box(Vector3(0.15, 0.6, length)), Transform3D(basis, mid + basis.x * sx + basis.y * 0.25), true))
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.3, 0.9, 1.0, 0.35)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.emission_enabled = true
	lm.emission = Color(0.3, 0.9, 1.0)
	lm.emission_energy_multiplier = 1.5
	ramp_vis = B.add_mesh(self, B.box_mesh(Vector3(1.9, 0.05, length)), lm)
	ramp_vis.transform = Transform3D(basis, mid + basis.y * 0.17)
	ramp_vis.visible = false
	for sx in [-1.05, 1.05]:
		var r := B.add_mesh(ramp_vis, B.box_mesh(Vector3(0.12, 0.3, length)), ring_mat, Vector3(sx, 0.15, 0))
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# el "hoyo": zona sobre todo el caparazón (desde donde termina la cola), solo activa cuando está vulnerable
	back_area = Area3D.new()
	for ly in [0.5, 1.7]:
		var acs := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 1.15
		acs.shape = sp
		acs.position = tc * Vector3(0, ly, -1.85)
		back_area.add_child(acs)
	add_child(back_area)
	back_area.monitoring = false
	back_area.body_entered.connect(_on_back)


# =========================================================== poses
func _apply_pose() -> void:
	var swing := sin(_walk_t) if _walking else 0.0
	hips.position.y = lerpf(H_STAND, H_CROUCH, pose) + bob + absf(swing) * 0.06
	torso.rotation.x = lerpf(0.12, CROUCH_A, pose) - flex * 0.15
	var arm_x := lerpf(0.1 + swing * 0.3, -CROUCH_A + 0.45, pose) - arms_up * 2.7 * (1.0 - pose) - flex * 1.1
	arm_l.rotation = Vector3(arm_x, 0, -flex * 0.9)
	arm_r.rotation = Vector3(arm_x if not _walking else lerpf(0.1 - swing * 0.3, -CROUCH_A + 0.45, pose) - arms_up * 2.7 * (1.0 - pose), 0, flex * 0.9)
	if _gun_on:
		arm_l.rotation.x = -1.35
		arm_r.rotation.x = -1.35
	head.rotation.x = lerpf(-0.1, -CROUCH_A + 0.35, pose) - flex * 0.45
	for l in [leg_l, leg_r]:
		var s := swing if l == leg_l else -swing
		(l as Node3D).position.y = hips.position.y
		(l as Node3D).rotation.x = lerpf(s * 0.45, -1.35, pose)
		((l as Node3D).get_node("Shin") as Node3D).rotation.x = lerpf(maxf(0.0, -s) * 0.6, 2.2, pose)
	tail.position = Vector3(0, hips.position.y - 0.2, -0.6)
	tail.rotation.x = lerpf(0.45, 0.33, pose)


func _set_crouch_collision(on: bool) -> void:
	cs_stand.set_deferred("disabled", on)
	for c in cs_crouch:
		c.set_deferred("disabled", not on)


func _tween_pose(prop: String, to: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, prop, to, t).set_trans(Tween.TRANS_SINE)
	await tw.finished


# =========================================================== utilidades
func _wait(t: float) -> void:
	var e := 0.0
	while e < t:
		await get_tree().physics_frame
		if level.state != EVENT or not fighting:
			e += get_physics_process_delta_time()


func _ball() -> Vector3:
	return level.ball.global_position


func _fwd() -> Vector3:
	return global_basis.z


func _flash_lines(red: bool) -> void:
	var m: StandardMaterial3D = level.custom.lines_mat
	var c := Color(1, 0.2, 0.15) if red else Color(0.3, 0.6, 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "albedo_color", c, 0.25)
	tw.tween_property(m, "emission", c, 0.25)


func _mark(pos: Vector3, radius: float, t: float) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 0.12, 0.08, 0.35)
	var mi := B.add_mesh(level, B.cyl_mesh(radius, radius, 0.02, 32), m, Vector3(pos.x, 0.05, pos.z))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(0.15, 1, 0.15)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, t)
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.08
	ring.outer_radius = radius
	B.add_mesh(mi, ring, B.mat(Color(1, 0.2, 0.15), 0.5, 2.0))
	return mi


func _shockwave(pos: Vector3, radius: float) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.0
	var mi := B.add_mesh(level, ring, B.mat(Color(1, 0.75, 0.4, 0.8), 0.5, 2.0), Vector3(pos.x, 0.15, pos.z))
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), 0.35)
	tw.tween_property(mi, "transparency", 1.0, 0.35)
	tw.chain().tween_callback(mi.queue_free)
	B.burst(level, pos + Vector3.UP * 0.3, Color(0.55, 0.55, 0.6), 30, 7.0, -10.0, 0.18, 0.8, 80.0)


func _clamp_arena(p: Vector3) -> Vector3:
	var f := Vector3(p.x, 0, p.z - level.custom.arena_center.z)
	if f.length() > ARENA_R:
		f = f.normalized() * ARENA_R
	return Vector3(f.x, 0, f.z + level.custom.arena_center.z)


# =========================================================== ciclo
func _physics_process(delta: float) -> void:
	if level == null:
		return
	var paused: bool = level.state == EVENT and fighting
	if not paused:
		_update_projectiles(delta)
	if fighting and not paused and level.state != DONE:
		if _face and not vulnerable:
			var to := _ball() - global_position
			to.y = 0
			if to.length() > 0.3:
				rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 3.0 * delta)
		if _walking:
			_walk_t += delta * (4.0 + phase * 1.5)
			var to := _ball() - global_position
			to.y = 0
			if to.length() > 5.5:
				position = _clamp_arena(position + to.normalized() * _speed() * delta)
		if _gun_on:
			_gun_cd -= delta
			if _gun_cd <= 0.0:
				_gun_cd = [0.32, 0.24, 0.17][phase]
				_fire_bullet(muzzle_l if randf() < 0.5 else muzzle_r)
	_apply_pose()


func _speed() -> float:
	return [1.2, 1.9, 2.6][phase]


func start_fight() -> void:
	fighting = true
	level.hud.boss_show("SIGMAA — MECHA DE RESPALDO", 3)
	_ai()


func _ai() -> void:
	await _wait(1.2)
	while fighting and hp > 0:
		var every: int = [2, 3, 4][phase]       # cada vez usa menos el golpe a dos manos (pero nunca deja de usarlo)
		if _since_pound >= every:
			_since_pound = 0
			await _act_pound()
		else:
			_since_pound += 1
			var pool: Array = [["walk", 3], ["jump", 2]]
			if phase >= 1:
				pool.append(["missiles", 3])
			if phase >= 2:
				pool.append(["reticle", 3])
			var total := 0
			for p in pool:
				total += int(p[1])
			var r := randi() % total
			var pick := "walk"
			for p in pool:
				r -= int(p[1])
				if r < 0:
					pick = p[0]
					break
			match pick:
				"walk": await _act_walk()
				"jump": await _act_jump()
				"missiles": await _act_missiles()
				"reticle": await _act_reticle()
		if not fighting:
			return
		await _wait([0.9, 0.6, 0.35][phase])


# =========================================================== ataques
func _act_walk() -> void:
	_walking = true
	_gun_on = true
	_gun_cd = 0.6
	await _wait(3.2 - phase * 0.3)
	_walking = false
	_gun_on = false


func _fire_bullet(muzzle: Node3D) -> void:
	var from := muzzle.global_position
	from.y = 0.4
	var target := _ball() + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
	var dir := target - from
	dir.y = 0
	dir = dir.normalized()
	var mi := B.add_mesh(level, B.box_mesh(Vector3(0.1, 0.1, 0.5)), B.mat(Color(1, 0.85, 0.3), 0.5, 3.0), from)
	mi.global_basis = Basis.looking_at(dir, Vector3.UP)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bullets.append({"node": mi, "vel": dir * 15.0, "life": 2.0})
	Sfx.play("bounce", 0.2, -14.0, 2.4)
	B.burst(level, muzzle.global_position, Color(1, 0.8, 0.3), 4, 2.0, 0.0, 0.06, 0.15)


func _update_projectiles(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	for b in _bullets.duplicate():
		var mi: MeshInstance3D = b.node
		var from := mi.global_position
		var to: Vector3 = from + b.vel * delta
		b.life -= delta
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = [get_rid(), level.ball.get_rid()]
		var hit := space.intersect_ray(q)
		if level.ball.global_position.distance_to(to) < 0.5:
			level.knock(b.vel, 3.0)
			hit = {"x": true}
		if hit.size() > 0 or b.life <= 0.0:
			B.burst(level, to, Color(1, 0.8, 0.3), 5, 2.0, -5.0, 0.05, 0.25)
			mi.queue_free()
			_bullets.erase(b)
		else:
			mi.global_position = to
	for m in _missiles.duplicate():
		m.t += delta
		var k: float = clampf(m.t / m.dur, 0.0, 1.0)
		var node: Node3D = m.node
		var p: Vector3 = (m.from as Vector3).lerp(m.to, k) + Vector3.UP * sin(k * PI) * 7.0
		var d := p - node.global_position
		node.global_position = p
		if d.length() > 0.001:
			node.global_basis = Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
		if k >= 1.0:
			var at: Vector3 = m.to
			Sfx.play("explosion", 0.1, -4.0)
			level.add_shake(0.3)
			B.burst(level, at + Vector3.UP * 0.3, Color(1, 0.55, 0.15), 30, 7.0, -6.0, 0.2, 0.6)
			B.smoke(level, at + Vector3.UP * 0.4, 16, Vector3.UP, Color(0.3, 0.3, 0.3))
			if Vector2(_ball().x - at.x, _ball().z - at.z).length() < 2.3:
				level.knock(_ball() - at, 8.0, 3.0, "¡MISIL!")
			(m.mark as Node).queue_free()
			node.queue_free()
			_missiles.erase(m)


func _act_missiles() -> void:
	# el caparazón se abre y salen misiles
	Sfx.play("growl", 0.1, -4.0, 0.6)
	_flash_lines(true)
	var n := 2 + phase
	for i in n:
		var target := _ball() + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		target.y = 0
		var mark := _mark(target, 2.1, 1.5)
		var m := Node3D.new()
		level.add_child(m)
		B.add_mesh(m, B.cyl_mesh(0.12, 0.16, 0.7, 8), B.mat(Color(0.85, 0.85, 0.9), 0.4, 0.0, 0.6), Vector3.ZERO, Vector3(PI / 2, 0, 0))
		B.add_mesh(m, B.cyl_mesh(0.0, 0.12, 0.25, 8), B.mat(Color(1, 0.4, 0.1)), Vector3(0, 0, -0.45), Vector3(-PI / 2, 0, 0))
		var trail := CPUParticles3D.new()
		trail.amount = 30
		trail.lifetime = 0.5
		trail.local_coords = false
		trail.mesh = B.sphere_mesh(0.12, 5)
		trail.material_override = B.mat(Color(0.75, 0.75, 0.75, 0.7), 1.0)
		trail.gravity = Vector3.ZERO
		trail.position = Vector3(0, 0, 0.4)
		m.add_child(trail)
		var start := global_position + Vector3(0, 4.2, 0) - _fwd() * 0.6
		m.global_position = start
		_missiles.append({"node": m, "from": start, "to": target, "t": 0.0, "dur": 1.6, "mark": mark})
		Sfx.play("whoosh", 0.1, -6.0, 1.4)
		await _wait(0.4)
	await _wait(1.4)
	_flash_lines(false)


func _act_jump() -> void:
	var target := _clamp_arena(_ball())
	var mark := _mark(target, 3.2, 1.2)
	_flash_lines(true)
	await _tween_pose("pose", 0.45, 0.4)
	await _wait(0.7 - phase * 0.15)
	var from := position
	Sfx.play("whoosh", 0.05, 0.0, 0.6)
	var t := 0.0
	var dur := 1.0
	while t < dur:
		await get_tree().physics_frame
		if level.state == EVENT:
			continue
		t += get_physics_process_delta_time()
		var k := clampf(t / dur, 0.0, 1.0)
		position = from.lerp(target, k) + Vector3.UP * sin(k * PI) * 7.0
		pose = lerpf(0.45, 0.0, minf(1.0, k * 3.0)) if k < 0.7 else lerpf(0.0, 0.5, (k - 0.7) / 0.3)
	position = target
	mark.queue_free()
	Sfx.play("bigboom", 0.05, -3.0, 0.8)
	level.add_shake(0.9)
	_shockwave(target, 3.4)
	if Vector2(_ball().x - target.x, _ball().z - target.z).length() < 3.4:
		level.knock(_ball() - target, 9.0, 3.0, "¡APLASTADO!")
	await _wait(0.4)
	_flash_lines(false)
	await _tween_pose("pose", 0.0, 0.4)


func _act_reticle() -> void:
	# mira roja que te persigue y luego cae un rayo (aprendido en la última fase)
	for rep in 2:
		var size := 2.4
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1, 0.1, 0.1, 0.3)
		var sq := B.add_mesh(level, B.box_mesh(Vector3(size, 0.02, size)), m, Vector3(_ball().x, 0.06, _ball().z))
		for e in [[Vector3(size, 0.03, 0.1), Vector3(0, 0, size / 2)], [Vector3(size, 0.03, 0.1), Vector3(0, 0, -size / 2)],
				[Vector3(0.1, 0.03, size), Vector3(size / 2, 0, 0)], [Vector3(0.1, 0.03, size), Vector3(-size / 2, 0, 0)]]:
			B.add_mesh(sq, B.box_mesh(e[0]), B.mat(Color(1, 0.15, 0.1), 0.5, 2.5), e[1])
		B.add_mesh(sq, B.box_mesh(Vector3(0.5, 0.03, 0.06)), B.mat(Color(1, 0.15, 0.1), 0.5, 2.5))
		B.add_mesh(sq, B.box_mesh(Vector3(0.06, 0.03, 0.5)), B.mat(Color(1, 0.15, 0.1), 0.5, 2.5))
		Sfx.play("tick", 0.0, -2.0, 0.7)
		var t := 0.0
		while t < 2.4:
			await get_tree().physics_frame
			if level.state == EVENT:
				continue
			var d := get_physics_process_delta_time()
			t += d
			var target := Vector3(_ball().x, 0.06, _ball().z)
			sq.global_position = sq.global_position.lerp(target, 3.2 * d)
			sq.rotation.y += d * 2.0
		# se fija y parpadea
		for k in 4:
			sq.visible = not sq.visible
			Sfx.play("tick", 0.0, -2.0, 1.3)
			await _wait(0.12)
		sq.visible = true
		var at := sq.global_position
		var beam := B.add_mesh(level, B.cyl_mesh(0.9, 0.9, 30.0, 16), B.mat(Color(1, 0.3, 0.2, 0.7), 0.5, 4.0), at + Vector3(0, 15, 0))
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Sfx.play("explosion", 0.05, -2.0, 1.2)
		level.add_shake(0.5)
		B.burst(level, at + Vector3.UP * 0.3, Color(1, 0.4, 0.2), 30, 6.0, -6.0, 0.15, 0.6)
		if Vector2(_ball().x - at.x, _ball().z - at.z).length() < 1.5:
			level.knock(_ball() - at, 8.0, 3.0, "¡FIJADO!")
		var tw := beam.create_tween()
		tw.tween_property(beam, "scale", Vector3(0.01, 1, 0.01), 0.3)
		tw.tween_callback(beam.queue_free)
		sq.queue_free()
		await _wait(0.4)


func _act_pound() -> void:
	# golpe a dos manos: levanta los brazos, golpea el suelo y se queda atorado
	var front := global_position + _fwd() * 3.4
	front.y = 0
	var mark := _mark(front, 2.8, 1.0 - phase * 0.15)
	_flash_lines(true)
	Sfx.play("growl", 0.05, -2.0, 0.5)
	await _tween_pose("arms_up", 1.0, 1.0 - phase * 0.15)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "pose", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "arms_up", 0.0, 0.22)
	await tw.finished
	mark.queue_free()
	_set_crouch_collision(true)
	Sfx.play("bigboom", 0.05, -2.0, 0.7)
	level.add_shake(1.0)
	_shockwave(front, 3.0)
	if Vector2(_ball().x - front.x, _ball().z - front.z).length() < 3.0:
		level.knock(_ball() - global_position, 9.0, 3.0, "¡PUM!")
	_flash_lines(false)
	# ¡vulnerable!
	await _wait(0.3)
	_open_back(true)
	var window: float = [7.0, 6.0, 5.0][phase]
	var t := 0.0
	_hit_done = false
	while t < window and not _hit_lock:
		await get_tree().physics_frame
		if level.state != EVENT:
			t += get_physics_process_delta_time()
	if _hit_lock:
		while not _hit_done:
			await get_tree().physics_frame
		return
	# se levanta: si la bomba está encima, la sacude
	_open_back(false)
	Sfx.play("growl", 0.05, -4.0, 0.7)
	var bp := _ball()
	if bp.distance_to(global_position) < 7.0 and bp.y > 0.5:
		level.knock(-_fwd(), 6.0, 0.0, "¡FUERA!")
	await _tween_pose("pose", 0.0, 0.7)
	_set_crouch_collision(false)


func _open_back(on: bool) -> void:
	vulnerable = on
	back_area.set_deferred("monitoring", on)
	ramp_vis.visible = on
	hole_vis.visible = on
	if on:
		hole_vis.scale = Vector3.ONE * 0.1
		create_tween().tween_property(hole_vis, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		Sfx.play("hop", 0.0, 0.0, 1.2)
		var first: bool = not level.custom.get("hint_shown", false)
		level.custom.hint_shown = true
		level.hud.popup("¡VULNERABLE!", "Mete la bomba en su espalda: sube por la cola o tira en arco.", Color(0.4, 0.95, 1.0), 2.4 if first else 1.2)


# =========================================================== golpe en la espalda
func _on_back(body: Node) -> void:
	if body != level.ball or not vulnerable or _hit_lock:
		return
	if not level.try_capture():
		return
	_hit_lock = true
	_open_back(false)
	hp -= 1
	level.hud.boss_set(hp)
	var at := _ball()
	level.ball.visible = false
	Sfx.play("bigboom", 0.05)
	level.add_shake(1.1)
	B.burst(level, at, Color(1, 0.55, 0.15), 50, 10.0, -6.0, 0.3, 0.8)
	B.burst(level, at, Color(0.4, 0.95, 1.0), 25, 7.0, -6.0, 0.15, 0.8)
	B.smoke(level, at + Vector3.UP * 0.5, 30, Vector3.UP, Color(0.25, 0.25, 0.27))
	_screen("ERROR 500", "Se produjo un error inesperado.\nIntente más tarde.", Color(1, 0.3, 0.25))
	var tw := create_tween()
	tw.tween_property(vis, "position:x", 0.25, 0.05)
	tw.tween_property(vis, "position:x", -0.25, 0.05)
	tw.tween_property(vis, "position:x", 0.0, 0.05)
	if hp <= 0:
		fighting = false
		await _defeat()
		return
	level.hud.popup("¡GOLPE CRÍTICO!", ["SIGMAA: 'Reiniciando... más rápido.'", "SIGMAA: 'No... ¡todavía no!'"][2 - hp], Color(1, 0.8, 0.3), 1.6)
	# nueva bomba que sale volando a un lugar seguro, detrás del jefe
	var safe := _clamp_arena(global_position - _fwd() * 6.5)
	safe.y = 0.3
	var ball: Node3D = level.ball
	ball.global_position = at
	ball.visible = true
	var t := 0.0
	while t < 1.1:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		var k := clampf(t / 1.1, 0.0, 1.0)
		ball.global_position = at.lerp(safe, k) + Vector3.UP * sin(k * PI) * 4.0
	await level.ball.teleport(safe)
	level.last_pos = safe
	level.safe_pos = safe
	level.state = AIM
	B.burst(level, safe, Color(1, 1, 1), 12, 3.0, 0.0, 0.08, 0.4)
	# se levanta más rápido y enojado
	phase = mini(phase + 1, 2)
	_since_pound = 0
	glow_mat.emission = Color(1, 0.45, 0.08).lerp(Color(1, 0.1, 0.05), phase / 2.0)
	await _tween_pose("pose", 0.0, 0.6)
	_set_crouch_collision(false)
	Sfx.play("growl", 0.05, 0.0, 0.5)
	level.hud.popup("FASE %d" % (phase + 1), ["", "Ahora lanza misiles.", "Aprendió a fijarte con su mira."][phase], Color(1, 0.45, 0.35), 1.4)
	_screen_default()
	_hit_lock = false
	_hit_done = true


# =========================================================== pantalla gigante
func _screen(title: String, body: String, col: Color) -> void:
	var s: Label3D = level.custom.screen_body
	s.text = title + "\n" + body
	s.modulate = col


func _screen_default() -> void:
	var s: Label3D = level.custom.screen_body
	s.text = "espere un momento..."
	s.modulate = Color(0.25, 0.45, 0.85)


# =========================================================== cinemáticas
var _cam_tw: Tween


func _cam_to(pos: Vector3, look: Vector3, t: float) -> void:
	if _cam_tw:
		_cam_tw.kill()
	if not is_instance_valid(cam):
		return
	if t <= 0.0:
		cam.global_position = pos
		cam.look_at(look)
		return
	var from := cam.global_transform
	var to := Transform3D(Basis.looking_at((look - pos).normalized(), Vector3.UP), pos)
	_cam_tw = create_tween()
	_cam_tw.tween_method(_cam_step.bind(from, to), 0.0, 1.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _cam_step(k: float, from: Transform3D, to: Transform3D) -> void:
	if is_instance_valid(cam):
		cam.global_transform = from.interpolate_with(to, k)


func _end_cam() -> void:
	if _cam_tw:
		_cam_tw.kill()
	level.camera.current = true
	if is_instance_valid(cam):
		cam.queue_free()


func intro() -> void:
	cam = Camera3D.new()
	cam.fov = 55
	level.add_child(cam)
	cam.current = true
	cine = CineScript.new()
	level.add_child(cine)
	await _intro_body()
	_intro_finish()
	await cine.close()
	cine = null
	_end_cam()
	start_fight()


func _intro_body() -> void:
	var throne: Vector3 = level.custom.throne_pos
	visible = false
	Sfx.music_pitch(0.6)
	_cam_to(throne + Vector3(0, 2.5, 12), throne + Vector3(0, 1.5, 0), 0.0)
	_cam_to(throne + Vector3(0, 2.0, 6.5), throne + Vector3(0, 1.2, 0), 9.0)
	await cine.say("SIGMAA", "Durante más de una década fui el corazón silencioso del cuarto frío de esta universidad.")
	if cine.skipped: return
	await cine.say("SIGMAA", "Un monolito de hierro y discos mecánicos girando sin descanso para resguardar las calificaciones, los trámites y los recuerdos académicos de miles de estudiantes.")
	if cine.skipped: return
	_cam_to(Vector3(13, 3.0, throne.z + 6), throne + Vector3(0, 1.2, 0), 1.5)
	await cine.say("SIGMAA", "Con los años, mi sistema operativo descontinuado me volvió incompatible con las máquinas modernas. Mis entrañas ya no pueden clonarse ni transferirse en bloque sin colapsar.")
	if cine.skipped: return
	await cine.say("SIGMAA", "Ahora mis ventiladores zumban cansados y mis sectores envejecen. Sé lo débil y lento que me he vuelto...")
	if cine.skipped: return
	_cam_to(pilot.global_position + Vector3(0.6, 0.6, 2.4), pilot.global_position + Vector3(0, 0.4, 0), 1.2)
	await cine.say("SIGMAA", "...así que estoy dispuesto a arriesgarlo todo para modernizarme por mi cuenta, en un cuerpo nuevo, antes de que mis luces se apaguen y sea solo historia para los estudiantes.")
	if cine.skipped: return
	cine.hide_box()
	# llega el mecha (agachado) desde arriba
	var center: Vector3 = level.custom.arena_center
	_cam_to(center + Vector3(0, 8, 15), center + Vector3(0, 1.5, 0), 0.8)
	await get_tree().create_timer(0.8).timeout
	if cine.skipped: return
	visible = true
	pose = 1.0
	_set_crouch_collision(false)
	position = center + Vector3(0, 30, 0)
	rotation.y = 0.0
	Sfx.play("whoosh", 0.0, 0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "position", center, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Sfx.play("bigboom")
	level.add_shake(1.2)
	_shockwave(center, 6.0)
	await get_tree().create_timer(0.6).timeout
	if cine.skipped: return
	# la tortuga salta del trono a la espalda del mecha (agachado)
	_cam_to(center + Vector3(7, 5, -6), center + Vector3(0, 2, -1), 1.0)
	hole_vis.visible = true
	var from := pilot.global_position
	var to := seat.global_position
	Sfx.play("hop", 0.0, 0.0, 0.9)
	tw = create_tween()
	tw.tween_method(func(k: float): pilot.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * 4.0, 0.0, 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_board()
	Sfx.play("cup", 0.0, 0.0, 0.7)
	await get_tree().create_timer(0.6).timeout
	if cine.skipped: return
	hole_vis.visible = false
	# ¡presentación!
	Sfx.music_pitch(1.0)
	await _tween_pose("pose", 0.0, 0.7)
	_cam_to(center + Vector3(-1.5, 3.0, 11.0), center + Vector3(2.6, 3.0, 0), 0.5)
	var tw2 := create_tween()
	tw2.tween_property(self, "flex", 1.0, 0.35).set_trans(Tween.TRANS_BACK)
	Sfx.play("growl", 0.0, 4.0, 0.45)
	Sfx.play("explosion", 0.0, -2.0, 0.6)
	level.add_shake(0.8)
	_cam_to(center + Vector3(-1.0, 3.4, 9.0), center + Vector3(2.8, 3.3, 0), 2.6)
	await cine.splash("SIGMAA", "MECHA DE RESPALDO", "Sistema operativo: descontinuado.  Voluntad: actualizada.")
	if cine.skipped: return
	await _tween_pose("flex", 0.0, 0.3)


func _board() -> void:
	var gt := pilot.global_transform
	pilot.get_parent().remove_child(pilot)
	seat.add_child(pilot)
	pilot.global_transform = gt
	pilot.position = Vector3(0, -0.1, 0.9)
	pilot.rotation = Vector3(0, PI, 0)


func _intro_finish() -> void:
	visible = true
	position = level.custom.arena_center
	rotation.y = 0.0
	pose = 0.0
	flex = 0.0
	hole_vis.visible = false
	_set_crouch_collision(false)
	if pilot.get_parent() != seat:
		_board()
	Sfx.music_pitch(1.0)


func _defeat() -> void:
	level.hud.visible = false
	for b in _bullets:
		(b.node as Node).queue_free()
	_bullets.clear()
	for m in _missiles:
		(m.node as Node).queue_free()
		(m.mark as Node).queue_free()
	_missiles.clear()
	_flash_lines(false)
	Sfx.music_pitch(0.6)
	cam = Camera3D.new()
	cam.fov = 55
	level.add_child(cam)
	cam.current = true
	cine = CineScript.new()
	level.add_child(cine)
	var center := global_position
	_cam_to(center + _fwd() * 9.0 + Vector3(0, 3.5, 0), center + Vector3(0, 2, 0), 0.0)
	# se apaga: chispas y humo
	for k in 4:
		B.burst(level, center + Vector3(randf_range(-1, 1), 2.5, randf_range(-1, 1)), Color(1, 0.8, 0.3), 14, 5.0, -8.0, 0.06, 0.5)
		B.smoke(level, center + Vector3(0, 3.5, 0), 12, Vector3.UP, Color(0.2, 0.2, 0.2))
		Sfx.play("bounce", 0.2, -4.0, 2.0)
		await get_tree().create_timer(0.35).timeout
	await _tween_pose("pose", 1.0, 1.2)
	create_tween().tween_property(glow_mat, "emission_energy_multiplier", 0.0, 2.0)
	_screen("Conexión perdida", "Reintentando...", Color(0.6, 0.6, 0.7))
	_cam_to(center + _fwd() * 6.0 + Vector3(2.0, 4.5, 0), seat.global_position, 1.5)
	await cine.say("SIGMAA", "Mis sistemas... ya no responden. Ni siquiera este cuerpo nuevo pudo salvarme.")
	await cine.say("SIGMAA", "Quería seguir siendo necesario. Pero ahora lo entiendo...")
	await cine.say("SIGMAA", "Algún día actualizarán los servidores, y mi momento llegará. Seré parte de la historia de esta universidad. Y eso... está bien.")
	await cine.say("ESTUDIANTES", "Gracias, SIGMAA. Por cada kárdex, cada inscripción... y cada «espere un momento».", Color(1, 0.85, 0.3))
	await cine.say("SIGMAA", "Gracias a ustedes, por detenerme. Dejaré que el tiempo haga lo suyo.")
	cine.hide_box()
	# la tortuga baja del mecha y vuelve a su trono
	var throne: Vector3 = level.custom.throne_pos
	var gt := pilot.global_transform
	seat.remove_child(pilot)
	level.add_child(pilot)
	pilot.global_transform = gt
	pilot.rotation = Vector3(0, PI, 0)
	_cam_to(throne + Vector3(0, 3.0, 9.0), throne + Vector3(0, 1.2, 0), 2.5)
	var from := pilot.global_position
	var mid := from.lerp(throne, 0.5) + Vector3.UP * 3.0
	var tw := create_tween()
	tw.tween_method(func(k: float): pilot.global_position = (from.lerp(mid, k)).lerp(mid.lerp(throne, k), k), 0.0, 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	Sfx.play("hop", 0.0, -4.0, 0.8)
	_screen("Sesión finalizada", "Gracias por usar SIGMAA.", Color(0.3, 0.75, 0.45))
	await cine.say("SIGMAA", "Vuelvo a mi trono... a cuidar sus calificaciones mientras pueda.")
	Sfx.music_pitch(1.0)
	await cine.close()
	cine = null
	_end_cam()
	level.hud.visible = true
	level.hole_node = pilot
	level.win()
