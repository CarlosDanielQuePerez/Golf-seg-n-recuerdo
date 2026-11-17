extends Node3D
## Lógica común de un hoyo: cámara, apuntar/tirar, peligros, eventos y victoria.
## La geometría de cada hoyo está en levels.gd.

const B = preload("res://scripts/build.gd")
const BallScript = preload("res://scripts/ball.gd")
const CrocScript = preload("res://scripts/crocodile.gd")
const HudScript = preload("res://scripts/hud.gd")
const Levels = preload("res://scripts/levels.gd")

enum { AIM, MOVING, EVENT, DONE }

const QUIPS_WATER := ["El cocodrilo agradece tu donación.", "Eso era una pelota. ERA.", "Ñam ñam. +1 golpe.", "Dato: los cocodrilos no devuelven pelotas."]
const QUIPS_LAVA := ["Ahora es sopa de pelota.", "Don Coco: 'crujiente, gracias'.", "Bien cocida. +1 golpe.", "La lava quema. ¿Quién lo diría?"]
const QUIPS_VOID := ["La pelota decidió irse.", "Física: 1 — Tú: 0", "Se fue a buscar una vida mejor.", "Al vacío. Literal."]
const QUIPS_SHOT := ["¡Qué swing!", "Eso tenía fe.", "Con estilo.", "Ni el profe la vio venir.", "Puro talento (y suerte)."]

var level_index := 0
var main: Node
var info: Dictionary
var time_limit := 60.0
var time_left := 60.0
var timer_on := false
var _tick_last := 99
var magnets: Array[Area3D] = []
var tag_requests := {}
var ball_tag: Label3D
var _portal_cd := 0.0

var ball: RigidBody3D
var hud
var ground: CSGCombiner3D
var cam_root: Node3D
var cam_flip: Node3D
var cam_yaw: Node3D
var cam_pitch: Node3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.45
var zoom := 8.5
var shake := 0.0

var state := EVENT
var strokes := 0
var tee_pos := Vector3(0, 0.3, 0)
var tee_yaw := 0.0
var last_pos := Vector3.ZERO
var last_flipped := false
var safe_pos := Vector3.ZERO
var flipped := false
var loft := false
var dragging := false
var drag_start := Vector2.ZERO
var drag_now := Vector2.ZERO
var rotating := false
var still_time := 0.0
var moving_time := 0.0
var paused := false
var kill_low := -12.0
var kill_high := 30.0

# hoyo
var hole_pos := Vector3.ZERO
var hole_node: Node3D
var hole_cut: CSGCylinder3D
var hole_area: Area3D
var walking_hole := false

# zonas activas (viento) y datos propios de cada nivel
var wind_zones: Array[Area3D] = []
var custom := {}

# apuntado
var aim_root: Node3D
var aim_arrow: MeshInstance3D
var dots: Array[MeshInstance3D] = []


func _ready() -> void:
	info = Game.LEVELS[level_index]
	time_limit = info.time
	time_left = time_limit
	_setup_environment(info.sky)
	ground = B.ground(self)
	hud = HudScript.new()
	hud.level = self
	add_child(hud)
	hud.setup(info.name, info)
	hud.set_time(time_left, time_limit)
	hud.set_mode(loft)
	Levels.build(self, level_index)
	if ground.material_override is ShaderMaterial and not walking_hole:
		ground.material_override.set_shader_parameter("hole_pos", hole_pos)
	_spawn_ball()
	ball.set_lit(false)
	ball_tag = Label3D.new()
	ball_tag.font_size = 120
	ball_tag.pixel_size = 0.006
	ball_tag.outline_size = 22
	ball_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ball_tag.no_depth_test = true
	ball_tag.visible = false
	add_child(ball_tag)
	_setup_camera()
	_setup_aim()
	Sfx.music(info.music)
	Sfx.music_pitch(1.0)
	_intro()


# ================= ESCENARIO =================
func _setup_environment(sky_kind: String) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	var fog := false
	var fog_col := Color(0.35, 0.1, 0.06)
	var fog_den := 0.0035
	sm.sky_curve = 0.12
	match sky_kind:
		"day":
			sm.sky_top_color = Color(0.22, 0.5, 0.95)
			sm.sky_horizon_color = Color(0.7, 0.88, 1.0)
			sun.light_color = Color(1, 0.96, 0.88)
		"afternoon":
			sm.sky_top_color = Color(0.3, 0.45, 0.85)
			sm.sky_horizon_color = Color(1.0, 0.85, 0.65)
			sun.light_color = Color(1, 0.88, 0.7)
			sun.rotation.x = deg_to_rad(-35)
		"space":
			sm.sky_top_color = Color(0.05, 0.02, 0.15)
			sm.sky_horizon_color = Color(0.45, 0.2, 0.6)
			sm.ground_bottom_color = Color(0.02, 0.0, 0.05)
			sm.ground_horizon_color = Color(0.3, 0.1, 0.45)
			sun.light_color = Color(0.85, 0.8, 1.0)
			_stars()
		"sunset":
			sm.sky_top_color = Color(0.35, 0.25, 0.6)
			sm.sky_horizon_color = Color(1.0, 0.55, 0.35)
			sun.light_color = Color(1, 0.7, 0.5)
			sun.rotation.x = deg_to_rad(-25)
		"cave":
			sm.sky_top_color = Color(0.05, 0.035, 0.03)
			sm.sky_horizon_color = Color(0.2, 0.14, 0.1)
			sm.ground_bottom_color = Color(0.03, 0.02, 0.02)
			sm.ground_horizon_color = Color(0.2, 0.14, 0.1)
			sun.light_color = Color(0.8, 0.7, 0.6)
			sun.light_energy = 0.6
			fog = true
			fog_col = Color(0.12, 0.09, 0.07)
			fog_den = 0.012
		"sigmaa":
			sm.sky_top_color = Color(0.02, 0.04, 0.12)
			sm.sky_horizon_color = Color(0.05, 0.45, 0.55)
			sm.ground_bottom_color = Color(0.01, 0.02, 0.06)
			sm.ground_horizon_color = Color(0.05, 0.3, 0.4)
			sun.light_color = Color(0.75, 0.9, 1.0)
			_stars()
		"mangrove":
			sm.sky_top_color = Color(0.3, 0.55, 0.75)
			sm.sky_horizon_color = Color(0.75, 0.88, 0.8)
			sun.light_color = Color(1, 0.95, 0.85)
			fog = true
			fog_col = Color(0.6, 0.75, 0.68)
			fog_den = 0.006
		"volcano":
			sm.sky_top_color = Color(0.15, 0.04, 0.05)
			sm.sky_horizon_color = Color(0.8, 0.25, 0.1)
			sm.ground_bottom_color = Color(0.1, 0.02, 0.0)
			sm.ground_horizon_color = Color(0.6, 0.2, 0.05)
			sun.light_color = Color(1, 0.6, 0.45)
			fog = true
	if sky_kind not in ["space", "volcano", "cave", "sigmaa"]:
		sm.ground_horizon_color = sm.sky_horizon_color
		sm.ground_bottom_color = sm.sky_horizon_color.lerp(sm.sky_top_color, 0.7)
		sm.ground_curve = 0.08
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.1
	if fog:
		env.fog_enabled = true
		env.fog_light_color = fog_col
		env.fog_density = fog_den
		env.fog_sky_affect = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	add_child(sun)


func _stars() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = B.sphere_mesh(0.25, 4)
	mm.instance_count = 350
	for i in mm.instance_count:
		var d := Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized()
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * randf_range(0.5, 1.6)), d * 120.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = B.mat(Color(1, 1, 0.9), 1.0, 3.0)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


# ================= HOYO =================
func make_hole(pos: Vector3) -> void:
	hole_pos = pos
	hole_cut = B.csg_cyl(ground, 0.42, 0.7, pos + Vector3(0, -0.34, 0), true, B.mat(Color(0.95, 0.95, 0.95), 0.5))
	hole_node = Node3D.new()
	hole_node.position = pos
	add_child(hole_node)
	B.add_mesh(hole_node, B.cyl_mesh(0.41, 0.41, 0.02, 24), B.mat(Color(0.05, 0.05, 0.05)), Vector3(0, -0.66, 0))
	B.flag(hole_node, Vector3(0, -0.68, 0))
	hole_area = Area3D.new()
	hole_area.position = Vector3(0, -0.5, 0)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.38
	sh.height = 0.3
	cs.shape = sh
	hole_area.add_child(cs)
	hole_node.add_child(hole_area)
	hole_area.body_entered.connect(_on_hole_entered)


func _hole_hop(k: float, from: Vector3, to: Vector3, h: float) -> void:
	hole_node.position = from.lerp(to, k) + Vector3(0, sin(k * PI) * h, 0)
	hole_node.rotation.y = k * TAU


func move_hole(new_pos: Vector3, hop_height := 2.5, time := 0.6) -> void:
	var from := hole_node.position
	var tw := create_tween()
	tw.tween_method(_hole_hop.bind(from, new_pos, hop_height), 0.0, 1.0, time).set_trans(Tween.TRANS_SINE)
	# el corte del terreno "salta" al llegar
	hole_cut.position = Vector3(0, -50, 0)
	await tw.finished
	hole_pos = new_pos
	hole_cut.position = new_pos + Vector3(0, -0.34, 0)
	ground.move_child(hole_cut, ground.get_child_count() - 1)   # que corte también los tramos nuevos
	if ground.material_override is ShaderMaterial:
		ground.material_override.set_shader_parameter("hole_pos", hole_pos)
	B.burst(self, new_pos, Color(0.5, 0.35, 0.2), 20, 4.0, -12.0, 0.1, 0.8, 60.0)
	add_shake(0.2)


# ================= PELOTA Y CÁMARA =================
func _spawn_ball() -> void:
	ball = BallScript.new()
	ball.position = tee_pos
	add_child(ball)
	ball.hit_something.connect(_on_ball_hit)
	last_pos = tee_pos
	safe_pos = tee_pos
	# tee decorativo
	B.add_mesh(self, B.cyl_mesh(0.03, 0.08, 0.15, 8), B.mat(Color(1, 0.9, 0.2)), tee_pos + Vector3(0, -0.25, 0))


func _setup_camera() -> void:
	cam_root = Node3D.new()
	add_child(cam_root)
	cam_flip = Node3D.new()
	cam_root.add_child(cam_flip)
	cam_yaw = Node3D.new()
	cam_flip.add_child(cam_yaw)
	cam_pitch = Node3D.new()
	cam_yaw.add_child(cam_pitch)
	camera = Camera3D.new()
	camera.fov = 60
	camera.far = 400
	cam_pitch.add_child(camera)
	camera.current = true
	yaw = tee_yaw
	cam_root.global_position = tee_pos


func _setup_aim() -> void:
	aim_root = Node3D.new()
	add_child(aim_root)
	aim_arrow = B.add_mesh(aim_root, B.box_mesh(Vector3(0.12, 0.04, 1.0)), B.mat(Color(1, 1, 1), 0.5, 1.5), Vector3(0, 0, -0.5))
	var tip := B.add_mesh(aim_arrow, B.cyl_mesh(0.0, 0.2, 0.35, 4), B.mat(Color(1, 1, 1), 0.5, 1.5), Vector3(0, 0, -0.6), Vector3(-PI / 2, 0, 0))
	tip.scale = Vector3(1, 1, 0.3)
	aim_root.visible = false
	for i in 18:
		var d := B.add_mesh(self, B.sphere_mesh(0.07, 6), B.mat(Color(1, 1, 1), 1.0, 2.0))
		d.visible = false
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dots.append(d)


func _intro() -> void:
	state = EVENT
	if custom.has("cinematic"):
		# el jefe trae su propia cinemática (se puede saltar)
		hud.visible = false
		await custom.cinematic.call()
		hud.visible = true
		if state == EVENT:
			state = AIM
		timer_on = true
		ball.set_lit(true)
		return
	camera.position.z = 24.0
	pitch = -0.9
	var start := hole_pos if hole_node else tee_pos
	cam_root.global_position = start
	hud.popup(info.name.get_slice(":", 1).strip_edges(), info.intro, Color(1, 0.9, 0.4), 2.2)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam_root, "global_position", tee_pos, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.6)
	tw.tween_property(self, "pitch", -0.45, 2.4).set_delay(0.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if state == EVENT:
		state = AIM
	timer_on = true
	ball.set_lit(true)
	Sfx.play("hop", 0.0, -6.0, 0.7)


func add_shake(amount: float) -> void:
	if Game.settings.shake:
		shake = maxf(shake, amount)


func up_dir() -> Vector3:
	return Vector3.DOWN if flipped else Vector3.UP


func _process(delta: float) -> void:
	if not is_instance_valid(ball):
		return
	if state != EVENT or custom.get("follow_in_event", false):
		var target := ball.global_position
		if custom.has("cam_target"):
			target = custom.cam_target
		elif walking_hole and state == DONE:
			target = hole_node.global_position
		cam_root.global_position = cam_root.global_position.lerp(target, 1.0 - exp(-7.0 * delta))
	# cámara con teclado
	var rot := 0.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		rot += 1.0
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		rot -= 1.0
	yaw += rot * 1.8 * delta
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pitch = clampf(pitch - delta, -1.35, -0.08)
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pitch = clampf(pitch + delta, -1.35, -0.08)
	cam_yaw.rotation.y = yaw
	cam_pitch.rotation.x = pitch
	if state != EVENT or camera.position.z < 20.0:
		camera.position.z = lerpf(camera.position.z, zoom, 1.0 - exp(-6.0 * delta))
	shake = move_toward(shake, 0.0, delta * 1.6)
	camera.h_offset = randf_range(-1, 1) * shake * 0.35
	camera.v_offset = randf_range(-1, 1) * shake * 0.35
	_update_aim()
	_update_timer(delta)
	# etiqueta flotante sobre la bomba (cuenta de abejas, oscuridad...)
	if tag_requests.is_empty() or state in [EVENT, DONE]:
		ball_tag.visible = false
	else:
		var req: Array = tag_requests.values()[0]
		ball_tag.text = req[0]
		ball_tag.modulate = req[1]
		ball_tag.global_position = ball.global_position + up_dir() * 0.9
		ball_tag.visible = true
	tag_requests.clear()


func _update_timer(delta: float) -> void:
	if not timer_on or state == DONE:
		return
	if state in [AIM, MOVING]:
		time_left -= delta
	var frac := clampf(time_left / time_limit, 0.0, 1.0)
	ball.fuse_left = frac
	hud.set_time(time_left, time_limit)
	Sfx.fuse(state != EVENT, lerpf(1.6, 1.0, frac))
	var whole := int(ceil(time_left))
	if time_left < 10.0 and whole != _tick_last and whole > 0:
		_tick_last = whole
		Sfx.play("tick", 0.0, 0.0, 1.0 + (10 - whole) * 0.04)
	if time_left <= 0.0 and state in [AIM, MOVING]:
		time_left = 0.0
		_time_out()


# ================= ENTRADA =================
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_ESCAPE, KEY_P:
				if state != DONE:
					toggle_pause()
			KEY_F, KEY_SPACE:
				if not paused:
					loft = not loft
					hud.set_mode(loft)
					Sfx.play("click")
			KEY_R:
				if state == AIM and not paused and strokes > 0:
					_respawn("Reinicio de tiro (-3 s)", "", Color.WHITE, 3.0)
	if paused or state == DONE:
		return
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				if e.pressed and state == AIM:
					dragging = true
					drag_start = e.position
					drag_now = e.position
				elif not e.pressed and dragging:
					dragging = false
					_release()
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				rotating = e.pressed
			MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom - 0.7, 3.5, 22.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom + 0.7, 3.5, 22.0)
	elif e is InputEventMouseMotion:
		if dragging:
			drag_now = e.position
		if rotating:
			yaw -= e.relative.x * 0.008
			pitch = clampf(pitch - e.relative.y * 0.006, -1.35, -0.08)


func _shot() -> Dictionary:
	var d := drag_start - drag_now
	var power := clampf(d.length() / 260.0, 0.0, 1.0)
	var up := up_dir()
	var cb := camera.global_transform.basis
	var right := (cb.x - up * cb.x.dot(up)).normalized()
	var fwd := (-cb.z - up * (-cb.z).dot(up)).normalized()
	if fwd.length() < 0.1:
		fwd = (cb.y - up * cb.y.dot(up)).normalized()
	var dir := (right * d.x + fwd * (-d.y))
	dir = dir.normalized() if dir.length() > 0.001 else fwd
	var speed := lerpf(1.2, 21.0, pow(power, 1.1))
	var v: Vector3
	if loft:
		v = (dir * cos(0.78) + up * sin(0.78)) * speed * 0.85
	else:
		v = dir * speed + up * 0.4
	return {"power": power, "dir": dir, "v": v}


func _update_aim() -> void:
	var show := dragging and state == AIM
	if not show:
		aim_root.visible = false
		for dd in dots:
			dd.visible = false
		hud.show_power(0.0, false)
		return
	var s := _shot()
	var p: float = s.power
	hud.show_power(p, true)
	var bp := ball.global_position
	aim_root.visible = p > 0.03
	aim_root.global_position = bp
	var dir: Vector3 = s.dir
	if dir.length() > 0.01:
		aim_root.look_at(bp + dir, up_dir())
	aim_arrow.scale = Vector3(1, 1, 0.5 + p * 3.0)
	aim_arrow.position = Vector3(0, 0, -(0.5 + p * 3.0) * 0.5 - 0.3)
	var col := Color(0.3, 1, 0.4).lerp(Color(1, 0.85, 0.2), clampf(p * 2, 0, 1)).lerp(Color(1, 0.25, 0.2), clampf(p * 2 - 1, 0, 1))
	(aim_arrow.material_override as StandardMaterial3D).albedo_color = col
	# trayectoria aproximada
	var v: Vector3 = s.v
	var g := up_dir() * -9.8
	for i in dots.size():
		var t := 0.07 * (i + 1)
		var pos: Vector3
		if loft:
			pos = bp + v * t + 0.5 * g * t * t
		else:
			pos = bp + dir * (v.length() * t * 0.55)
		dots[i].global_position = pos
		dots[i].visible = p > 0.03 and (loft or i < 10)


func _release() -> void:
	var s := _shot()
	if s.power < 0.04:
		return
	var on_mover := _ground_is_moving()
	last_pos = safe_pos if on_mover else ball.global_position
	if not on_mover:
		safe_pos = ball.global_position
	last_flipped = flipped
	ball.set_rolling(s.v, up_dir())
	strokes += 1
	hud.set_strokes(strokes)
	state = MOVING
	still_time = 0.0
	moving_time = 0.0
	Sfx.play("hit", 0.05, 0.0, lerpf(1.25, 0.85, s.power))
	if s.power > 0.85:
		Sfx.play("whoosh", 0.1, -6.0)
		add_shake(0.15)
	if randf() < 0.12:
		B.floating_text(self, ball.global_position + up_dir() * 0.8, QUIPS_SHOT.pick_random(), Color(1, 1, 0.7), 64)
	on_shot()


# ================= FÍSICA / ESTADO =================
func _physics_process(delta: float) -> void:
	if not is_instance_valid(ball):
		return
	var bp := ball.global_position
	if state in [AIM, MOVING] and (bp.y < kill_low or bp.y > kill_high):
		_event_void()
		return
	_portal_cd = maxf(0.0, _portal_cd - delta)
	# en el aire casi no hay resistencia; en el suelo sí
	ball.linear_damp = 0.32 if _ground_hit().size() > 0 else 0.05
	# cangrejos-imán (la bomba es de metal...): rojo jala, azul empuja
	for m in magnets:
		if not is_instance_valid(m) or state == EVENT:
			continue
		var to := m.global_position - bp
		to -= up_dir() * to.dot(up_dir())
		var r: float = m.get_meta("radius")
		var st: float = m.get_meta("strength")
		var k := clampf(1.0 - to.length() / r, 0.0, 1.0)
		var dir := to.normalized() if to.length() > 0.01 else Vector3.ZERO
		ball.apply_central_force(dir * st * (0.3 + 0.7 * k) * ball.mass)
		if st > 0.0 and to.length() < 0.8:
			ball.linear_velocity *= 0.95
		if m.has_meta("beam"):
			var beam: MeshInstance3D = m.get_meta("beam")
			var src: Vector3 = m.global_position + up_dir() * 0.3
			var d := bp - src
			beam.visible = true
			beam.global_position = src + d * 0.5
			if d.length() > 0.05:
				beam.global_basis = Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
			beam.scale = Vector3(1, 1, maxf(d.length(), 0.01))
	# zonas de viento / cintas
	for z in wind_zones:
		if is_instance_valid(z):
			ball.apply_central_force(z.get_meta("force") * ball.mass)
	if state == AIM and not dragging:
		if (ball.linear_velocity - _ground_velocity()).length() > 2.0:
			state = MOVING
			moving_time = 0.0
			still_time = 0.0
	if state == MOVING:
		moving_time += delta
		var rel := ball.linear_velocity - _ground_velocity()
		var sp := rel.length()
		if sp < 1.2 and _ground_flat():
			ball.linear_velocity = ball.linear_velocity.lerp(_ground_velocity(), 0.03)
		still_time = still_time + delta if sp < 0.3 else 0.0
		if (still_time > 0.45 and moving_time > 0.5) or moving_time > 20.0:
			_ball_stopped()
		# imán del hoyo: ayuda cuando la pelota pasa lenta cerca
		if hole_node and not walking_hole:
			var flat := hole_pos - bp
			flat -= up_dir() * flat.dot(up_dir())
			if flat.length() < 0.75 and ball.linear_velocity.length() < 4.5 and absf(bp.y - hole_pos.y) < 0.6:
				ball.apply_central_force(flat.normalized() * 6.0 * ball.mass)
	level_tick(delta)


func _ground_hit() -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(ball.global_position, ball.global_position - up_dir() * 0.6)
	q.exclude = [ball.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)


func _ground_flat() -> bool:
	var h := _ground_hit()
	return h.size() > 0 and (h.normal as Vector3).dot(up_dir()) > 0.97


func _ground_is_moving() -> bool:
	var h := _ground_hit()
	return h.size() > 0 and h.collider is Node and h.collider.has_meta("moving")


func _ground_velocity() -> Vector3:
	var h := _ground_hit()
	if h.size() > 0 and h.collider is Node and h.collider.has_meta("moving") and "vel" in h.collider:
		return h.collider.vel
	return Vector3.ZERO


func _ball_stopped() -> void:
	state = AIM
	if not _ground_is_moving():
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		safe_pos = ball.global_position
	if strokes >= 7 and not custom.get("mercy", false):
		custom.mercy = true
		hud.popup("Respira hondo", "Tip: F cambia entre rodar y elevar.", Color(0.7, 0.9, 1.0), 2.0)


func _on_ball_hit(body: Node, speed: float) -> void:
	if body.is_in_group("bumper"):
		var away: Vector3 = ball.global_position - (body as Node3D).global_position
		away -= up_dir() * away.dot(up_dir())
		ball.linear_velocity = away.normalized() * maxf(speed * 1.1, 9.0) + up_dir() * 1.5
		Sfx.play("boing", 0.15)
		var m: Node3D = body.get_child(body.get_child_count() - 1)
		var tw := create_tween()
		tw.tween_property(m, "scale", Vector3(1.35, 0.8, 1.35), 0.06)
		tw.tween_property(m, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC)
		add_shake(0.12)
		if body.has_meta("quips") and randf() < 0.5:
			B.floating_text(self, body.global_position + Vector3.UP * 1.4, (body.get_meta("quips") as Array).pick_random(), Color(1, 0.9, 0.6), 64)
	elif body.is_in_group("shield"):
		if custom.has("on_shield"):
			custom.on_shield.call(speed)
	elif body.is_in_group("tnt"):
		_explode(body)


func _explode(barrel: Node3D) -> void:
	if barrel.get_meta("boom", false):
		return
	barrel.set_meta("boom", true)
	var p := barrel.global_position
	Sfx.play("explosion", 0.1)
	add_shake(0.8)
	Game.stats.booms += 1
	B.burst(self, p + Vector3.UP * 0.5, Color(1, 0.6, 0.1), 40, 9.0, -6.0, 0.25, 0.7)
	B.burst(self, p + Vector3.UP * 0.5, Color(1, 0.95, 0.4), 20, 6.0, -3.0, 0.18, 0.4)
	B.smoke(self, p + Vector3.UP, 30, Vector3.UP, Color(0.3, 0.3, 0.3))
	B.floating_text(self, p + Vector3.UP * 2.0, "¡KABOOM!", Color(1, 0.5, 0.2), 120)
	var d := ball.global_position - p
	if d.length() < 4.5:
		var push := d
		push.y = 0
		ball.linear_velocity += push.normalized() * 12.0 + Vector3.UP * 9.0
		if state == AIM:
			state = MOVING
			moving_time = 0.0
	barrel.visible = false
	barrel.process_mode = Node.PROCESS_MODE_DISABLED
	var col: CollisionShape3D = barrel.get_child(0)
	col.set_deferred("disabled", true)
	await get_tree().create_timer(9.0).timeout
	# no reaparece encima (ni debajo) de la bomba
	while is_instance_valid(barrel) and is_instance_valid(ball) and ball.global_position.distance_to(barrel.global_position) < 2.0:
		await get_tree().create_timer(1.0).timeout
	if is_instance_valid(barrel):
		barrel.visible = true
		barrel.process_mode = Node.PROCESS_MODE_INHERIT
		col.set_deferred("disabled", false)
		barrel.set_meta("boom", false)
		barrel.scale = Vector3(0.1, 0.1, 0.1)
		create_tween().tween_property(barrel, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)


# ================= ZONAS =================
func add_zone(pos: Vector3, size: Vector3, kind: String, data := {}) -> Area3D:
	var a := Area3D.new()
	a.position = pos
	var cs := CollisionShape3D.new()
	var sh: Shape3D
	if data.has("radius"):
		sh = SphereShape3D.new()
		sh.radius = data.radius
	else:
		sh = BoxShape3D.new()
		sh.size = size
	cs.shape = sh
	a.add_child(cs)
	a.set_meta("kind", kind)
	for k in data:
		a.set_meta(k, data[k])
	add_child(a)
	a.body_entered.connect(_on_zone_enter.bind(a))
	a.body_exited.connect(_on_zone_exit.bind(a))
	return a


func _on_zone_enter(body: Node, a: Area3D) -> void:
	if body != ball or state == DONE:
		return
	match a.get_meta("kind"):
		"gravity_up":
			if not flipped:
				set_flip(true)
		"gravity_down":
			if flipped:
				set_flip(false)
		"wind":
			wind_zones.append(a)
		"boost":
			var f: Vector3 = a.get_meta("dir")
			ball.set_rolling(f * maxf(ball.linear_velocity.dot(f) + 8.0, 19.0), up_dir())
			Sfx.play("boost")
			add_shake(0.15)
		"trigger":
			var cb: Callable = a.get_meta("callback")
			cb.call()
		"magnet":
			magnets.append(a)
			Sfx.play("magnet", 0.05)
			# tirón inmediato para que se note al entrar
			var to := a.global_position - ball.global_position
			to -= up_dir() * to.dot(up_dir())
			var sgn := 1.0 if float(a.get_meta("strength")) > 0.0 else -1.0
			ball.linear_velocity += to.normalized() * sgn * 2.5
			if state == AIM:
				state = MOVING
				moving_time = 0.0
		"jump":
			if state == EVENT:
				return
			var v := ball.linear_velocity
			var up := up_dir()
			var h := v - up * v.dot(up)
			var boost: Vector3 = a.get_meta("push", Vector3.ZERO)
			ball.linear_velocity = h * 0.9 + boost + up * float(a.get_meta("power"))
			if state == AIM:
				state = MOVING
				moving_time = 0.0
			Sfx.play("spring", 0.08)
			add_shake(0.15)
			var vis: Node3D = a.get_meta("visual")
			var tw := create_tween()
			tw.tween_property(vis, "scale", Vector3(1.2, 0.4, 1.2), 0.05)
			tw.tween_property(vis, "scale", Vector3(0.9, 1.5, 0.9), 0.1)
			tw.tween_property(vis, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
		"portal":
			if _portal_cd > 0.0 or state == EVENT:
				return
			_portal_cd = 0.8
			var to: Vector3 = a.get_meta("to")
			var out: Vector3 = a.get_meta("out")
			var sp := maxf(ball.linear_velocity.length(), 5.0)
			B.burst(self, ball.global_position, Color(0.4, 0.9, 1), 20, 4.0, 0.0, 0.1, 0.5)
			ball.global_position = to
			ball.set_rolling(out * sp, up_dir())
			B.burst(self, to, Color(1, 0.5, 1), 20, 4.0, 0.0, 0.1, 0.5)
			Sfx.play("portal")
			if state == AIM:
				state = MOVING
				moving_time = 0.0
		"clock":
			if a.get_meta("taken", false):
				return
			a.set_meta("taken", true)
			time_left += Game.CLOCK_BONUS
			Sfx.play("pickup")
			hud.flash_time("+%d s" % int(Game.CLOCK_BONUS), Color(0.5, 1, 0.5))
			B.floating_text(self, a.global_position + Vector3.UP, "+%d s" % int(Game.CLOCK_BONUS), Color(0.5, 1, 0.6), 110)
			B.burst(self, a.global_position, Color(0.5, 1, 0.7), 24, 4.0, -4.0, 0.08, 0.7)
			var vis: Node3D = a.get_meta("visual")
			var tw := create_tween()
			tw.tween_property(vis, "scale", Vector3.ONE * 1.6, 0.1)
			tw.tween_property(vis, "scale", Vector3.ZERO, 0.2)


func _on_zone_exit(body: Node, a: Area3D) -> void:
	if body == ball:
		wind_zones.erase(a)
		magnets.erase(a)
		if a.has_meta("beam"):
			(a.get_meta("beam") as Node3D).visible = false


func set_flip(v: bool, silent := false) -> void:
	flipped = v
	ball.gravity_scale = -1.0 if v else 1.0
	var tw := create_tween()
	tw.tween_property(cam_flip, "rotation:z", PI if v else 0.0, 0.7).set_trans(Tween.TRANS_BACK)
	if not silent:
		Sfx.play("warp")
		add_shake(0.25)
		hud.popup("¡ARRIBA!" if v else "¡ABAJO!", "La gravedad cambió de opinión.", Color(0.8, 0.5, 1.0), 1.0)


# ================= PELIGROS =================
func _on_hazard(body: Node, area: Area3D) -> void:
	if body != ball or state in [EVENT, DONE]:
		return
	state = EVENT
	dragging = false
	var kind: String = area.get_meta("kind")
	var surface: float = area.get_meta("surface")
	var bp := ball.global_position
	ball.freeze = true
	var float_pos := Vector3(bp.x, surface + 0.05, bp.z)
	custom.follow_in_event = false
	var tw := create_tween()
	tw.tween_property(ball, "global_position", float_pos, 0.25)
	if kind == "water":
		Sfx.play("splash")
		B.burst(self, float_pos, Color(0.75, 0.92, 1.0), 30, 5.0, -12.0, 0.1, 0.9, 40.0)
		Game.stats.crocs += 1
	else:
		Sfx.play("sizzle")
		B.smoke(self, float_pos, 20, Vector3.UP, Color(0.3, 0.28, 0.26))
		var t2 := create_tween()
		t2.tween_property(ball.body_mat, "albedo_color", Color(1, 0.35, 0.05), 0.6)
		Game.stats.melted += 1
	await get_tree().create_timer(0.7).timeout
	# ¡Aparece el cocodrilo!
	var croc := CrocScript.new(kind == "lava" or area.has_meta("don_coco"))
	add_child(croc)
	var center: Vector3 = area.global_position
	var dir := Vector3(bp.x - center.x, 0, bp.z - center.z)
	if dir.length() < 0.5:
		dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	dir = dir.normalized()
	croc.global_position = Vector3(bp.x, surface, bp.z) - dir * 1.9
	croc.rotation.y = atan2(dir.x, dir.z)
	await croc.eat(ball)
	if kind == "lava":
		_respawn(QUIPS_LAVA.pick_random(), "¡DERRETIDA!", Color(1, 0.5, 0.15))
	else:
		_respawn(QUIPS_WATER.pick_random(), "¡ÑAM!", Color(0.5, 1, 0.5))


func _event_void() -> void:
	state = EVENT
	dragging = false
	Sfx.play("fall")
	Game.stats.voids += 1
	hud.popup("¡AL VACÍO!", QUIPS_VOID.pick_random(), Color(0.7, 0.8, 1.0), 1.2)
	await get_tree().create_timer(1.3).timeout
	_respawn("La bomba se fue al vacío.", "", Color.WHITE)


func _respawn(msg: String, title := "", color := Color.WHITE, penalty := Game.PENALTY) -> void:
	if penalty > 0.0:
		time_left -= penalty
		hud.flash_time("-%d s" % int(penalty), Color(1, 0.35, 0.3))
	if title != "":
		hud.popup(title, msg + "  (-%d s)" % int(Game.PENALTY), color, 1.6)
	elif msg != "":
		hud.popup("¡OTRA VEZ!", msg, Color(1, 1, 1), 1.0)
	if flipped != last_flipped:
		set_flip(last_flipped, true)
	ball.gravity_scale = -1.0 if flipped else 1.0
	ball.body_mat.albedo_color = Game.bomb_color()
	if state == DONE:
		return
	await ball.teleport(last_pos + up_dir() * 0.04)
	if state == DONE:
		return
	B.burst(self, ball.global_position, Color(1, 1, 1), 16, 3.0, 0.0, 0.08, 0.5)
	Sfx.play("hop", 0.05, -6.0)
	state = AIM


# ================= DAÑO DE ATAQUES (JEFE) =================
var _knock_cd := 0.0


## Un ataque alcanzó la bomba: la empuja y (opcionalmente) cuesta segundos.
func knock(dir: Vector3, power: float, penalty := 0.0, text := "") -> void:
	if not (state in [AIM, MOVING]) or Time.get_ticks_msec() / 1000.0 < _knock_cd:
		return
	_knock_cd = Time.get_ticks_msec() / 1000.0 + 0.8
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	ball.linear_velocity = dir.normalized() * power + Vector3.UP * power * 0.45
	state = MOVING
	moving_time = 0.0
	still_time = 0.0
	add_shake(0.35)
	if penalty > 0.0:
		time_left -= penalty
		hud.flash_time("-%d s" % int(penalty), Color(1, 0.35, 0.3))
	if text != "":
		B.floating_text(self, ball.global_position + Vector3.UP * 1.2, text, Color(1, 0.5, 0.35), 80)


# ================= CAPTURAS DE LA FAUNA =================
## Congela la bomba para una animación de captura. Devuelve false si no se puede.
func try_capture() -> bool:
	if state in [EVENT, DONE] or not is_instance_valid(ball):
		return false
	state = EVENT
	dragging = false
	ball.freeze = true
	return true


## La bomba entra a la boca (o colmena), explota adentro y sale humo.
func swallow(animal: Node3D, mouth: Vector3, smoke_col := Color(0.35, 0.35, 0.37)) -> void:
	ball.visible = false
	Sfx.play("chomp", 0.05)
	await get_tree().create_timer(0.3).timeout
	Sfx.play("muffled", 0.05)
	add_shake(0.5)
	var base := animal.scale
	var tw := create_tween()
	tw.tween_property(animal, "scale", base * Vector3(1.35, 1.45, 1.3), 0.08)
	tw.tween_property(animal, "scale", base, 0.5).set_trans(Tween.TRANS_ELASTIC)
	await get_tree().create_timer(0.45).timeout
	Sfx.play("poof", 0.05)
	B.smoke(self, mouth, 30, Vector3.UP, smoke_col)
	await get_tree().create_timer(0.8).timeout


func finish_capture(title: String, msg: String, color: Color) -> void:
	_respawn(msg, title, color)


# ================= VICTORIA =================
func _on_hole_entered(body: Node) -> void:
	if body != ball or not (state in [AIM, MOVING]):
		return
	win()


func win() -> void:
	if state == DONE:
		return
	state = DONE
	dragging = false
	_stop_fuse()
	var used := time_limit - time_left
	var stars := Game.stars_for(level_index, used)
	Sfx.play("cup")
	await get_tree().create_timer(0.25).timeout
	ball.freeze = true
	if walking_hole:
		ball.visible = false
	# la mecha se apaga con un "pfff"
	Sfx.play("poof", 0.05, -4.0)
	B.smoke(self, ball.global_position + up_dir() * 0.4, 16, up_dir(), Color(0.7, 0.7, 0.7))
	var titles := ["¡CASI EXPLOTA!", "¡DESACTIVADA!", "¡RAPIDÍSIMO!", "¡LEYENDA!"]
	Sfx.play("fanfare" if stars >= 2 else "sad")
	if stars >= 2:
		Sfx.play("cheer", 0.05, -4.0)
	B.confetti(self, hole_node.global_position + Vector3.UP * 0.5, 150)
	add_shake(0.3)
	Engine.time_scale = 0.35
	hud.popup(titles[stars], "Tiempo: %s" % Game.fmt_time(used), Color(1, 0.85, 0.2), 2.0)
	await get_tree().create_timer(0.6 * 0.35).timeout
	Engine.time_scale = 1.0
	Game.record(level_index, stars, used, strokes)
	await get_tree().create_timer(1.8).timeout
	var comments := [
		"Por un pelo. La mecha ya estaba sudando.",
		"Nada mal. La bomba sobrevivió.",
		"Rápido y explosivo. Bueno, sin explotar.",
		"Eso fue ilegal. Impresionante, pero ilegal.",
	]
	hud.show_result(titles[stars], "%s\nTiempo: %s · Golpes: %d" % [comments[stars], Game.fmt_time(used), strokes], stars, level_index == Game.PLAYABLE - 1, Game.in_run, false)


## Se acabó la mecha: la bomba explota. 0 estrellas.
func _time_out() -> void:
	state = DONE
	dragging = false
	_stop_fuse()
	var p := ball.global_position
	custom.cam_target = p
	ball.freeze = true
	var tw := create_tween()
	tw.tween_property(ball.mesh_inst, "scale", Vector3.ONE * 1.6, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	ball.visible = false
	Sfx.play("bigboom", 0.05)
	add_shake(1.2)
	B.burst(self, p, Color(1, 0.6, 0.1), 60, 12.0, -6.0, 0.35, 0.8)
	B.burst(self, p, Color(1, 0.95, 0.5), 30, 8.0, -3.0, 0.25, 0.5)
	B.smoke(self, p + up_dir() * 0.5, 50, up_dir(), Color(0.25, 0.25, 0.25))
	B.floating_text(self, p + up_dir() * 2.0, "¡BOOM!", Color(1, 0.5, 0.2), 160)
	var flash := OmniLight3D.new()
	flash.light_color = Color(1, 0.7, 0.3)
	flash.light_energy = 8.0
	flash.omni_range = 14.0
	flash.position = p + up_dir()
	add_child(flash)
	create_tween().tween_property(flash, "light_energy", 0.0, 0.6)
	Game.stats.booms += 1
	hud.popup("¡BOOM!", "Se acabó la mecha.", Color(1, 0.45, 0.2), 1.6)
	Game.record(level_index, 0, time_limit, strokes)
	await get_tree().create_timer(2.2).timeout
	hud.show_result("SE ACABÓ EL TIEMPO", "La bomba explotó antes de llegar al hoyo.\n0 estrellas. El hoyo sobrevivió.", 0, level_index == Game.PLAYABLE - 1, Game.in_run, true)


func _stop_fuse() -> void:
	timer_on = false
	Sfx.fuse(false)
	ball.set_lit(false)


# ================= NAVEGACIÓN =================
func toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	hud.show_pause(paused)
	dragging = false


func restart_level() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	main.start_level(level_index)


func go_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	main.show_menu()


func next_level() -> void:
	main.level_finished(level_index)


# ================= LÓGICA POR NIVEL =================
func on_shot() -> void:
	if custom.has("on_shot"):
		custom.on_shot.call()


func level_tick(delta: float) -> void:
	if custom.has("tick"):
		custom.tick.call(delta)
