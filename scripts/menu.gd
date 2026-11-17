extends Node3D
## Menú principal con diorama 3D animado (y un cocodrilo con hambre).

const B = preload("res://scripts/build.gd")
const UiKit = preload("res://scripts/ui_kit.gd")
const CrocScript = preload("res://scripts/crocodile.gd")
const Stars = preload("res://scripts/stars.gd")
const U = preload("res://scripts/unicaribe.gd")
const IbisScript = preload("res://scripts/ibis.gd")

const TAGLINES := ["Las reglas eran más o menos así.", "Ahora con 100% más cocodrilos.", "La pelota era una bomba, ¿no?",
	"Basado en hechos (físicos) reales.", "El hoyo no quiere verte.", "Tienes 60 segundos. Suerte.",
	"Hecho por humanos. Con cariño y cafeína."]

var main: Node
var cam_pivot: Node3D
var camera: Camera3D
var ui: CanvasLayer
var title: Label
var main_box: VBoxContainer
var panels := {}
var _t := 0.0
var _croc_busy := false


func _ready() -> void:
	_build_world()
	_build_ui()
	Sfx.music("menu")
	Sfx.music_pitch(1.0)
	get_tree().create_timer(2.5).timeout.connect(_croc_show)


func _build_world() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.25, 0.45, 0.95)
	sm.sky_horizon_color = Color(1.0, 0.8, 0.7)
	sm.ground_horizon_color = sm.sky_horizon_color
	sm.ground_bottom_color = Color(0.45, 0.45, 0.8)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-30), 0)
	sun.light_color = Color(1, 0.92, 0.8)
	add_child(sun)
	var g := B.ground(self, Vector3(3, 0, -2))
	B.csg_box(g, Vector3(16, 2, 14), Vector3(0, -1, 0))
	B.csg_cyl(g, 0.42, 0.7, Vector3(3, -0.34, -2), true, B.mat(Color(0.95, 0.95, 0.95)))
	B.csg_box(g, Vector3(6, 1.6, 4.5), Vector3(-3.5, 0, 2.5), Vector3.ZERO, true)
	B.add_mesh(self, B.box_mesh(Vector3(14.5, 1.6, 12.5)), B.mat(Color(0.45, 0.3, 0.18)), Vector3(0, -2.8, 0))
	B.add_mesh(self, B.box_mesh(Vector3(10, 2, 8)), B.mat(Color(0.35, 0.22, 0.13)), Vector3(0, -4.5, 0))
	var water := PlaneMesh.new()
	water.size = Vector2(6, 4.5)
	water.subdivide_depth = 8
	water.subdivide_width = 8
	B.add_mesh(self, water, B.shader_mat("res://shaders/water.gdshader"), Vector3(-3.5, -0.25, 2.5))
	B.flag(self, Vector3(3, -0.68, -2))
	for p in [Vector3(-6, 0, -5), Vector3(6.5, 0, 4.5), Vector3(-6.5, 0, -1), Vector3(6, 0, -5.5)]:
		B.tree(self, p, randf_range(0.9, 1.3))
	B.sign_post(self, Vector3(0.5, 0, 4.5), "BIENVENIDO A LA UNICARIBE", -0.2)
	# fauna del campus de paseo (no todos: hay que descubrir al resto jugando)
	var ig := Node3D.new()
	ig.position = Vector3(5.2, 0, 1.5)
	ig.rotation.y = 2.4
	add_child(ig)
	U.iguana(ig)
	var crab_d: Dictionary = U.crab(self, true)
	var cn: Node3D = crab_d.node
	cn.position = Vector3(-0.3, 0, 1.8)
	cn.scale = Vector3.ONE * 0.6
	var twc := cn.create_tween().set_loops()
	twc.tween_property(cn, "position:x", 0.9, 1.6).set_trans(Tween.TRANS_SINE)
	twc.tween_property(cn, "position:x", -0.3, 1.6).set_trans(Tween.TRANS_SINE)
	var ib = IbisScript.new()
	ib.mode = "line"
	ib.a = Vector3(-1.5, 0, -4.5)
	ib.b = Vector3(5.5, 0, -4.5)
	ib.period = 9.0
	add_child(ib)
	# pelota decorativa
	var ballm := B.add_mesh(self, B.sphere_mesh(0.22, 16), B.mat(Game.bomb_color(), 0.3, 0.0, 0.4), Vector3(1.2, 0.22, 0.3))
	B.add_mesh(ballm, B.cyl_mesh(0.07, 0.09, 0.08, 10), B.mat(Color(0.6, 0.6, 0.65), 0.3, 0.0, 0.9), Vector3(0, 0.23, 0))
	B.add_mesh(ballm, B.cyl_mesh(0.02, 0.02, 0.2, 6), B.mat(Color(0.75, 0.62, 0.4)), Vector3(0.03, 0.34, 0), Vector3(0, 0, -0.3))
	var sp := CPUParticles3D.new()
	sp.amount = 16
	sp.lifetime = 0.3
	sp.mesh = B.sphere_mesh(0.025, 4)
	sp.material_override = B.mat(Color(1, 0.75, 0.2), 1.0, 4.0)
	sp.spread = 70
	sp.initial_velocity_min = 0.6
	sp.initial_velocity_max = 1.5
	sp.position = Vector3(0.06, 0.44, 0)
	ballm.add_child(sp)
	for k in 10:
		var c := B.cloud(self, Vector3(randf_range(-40, 40), randf_range(8, 16), randf_range(-40, 10)), randf_range(1, 2))
		var tw := c.create_tween().set_loops()
		tw.tween_property(c, "position:x", c.position.x + 6, 10).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "position:x", c.position.x, 10).set_trans(Tween.TRANS_SINE)
	cam_pivot = Node3D.new()
	add_child(cam_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 7, 15)
	camera.fov = 55
	cam_pivot.add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true


func _process(delta: float) -> void:
	_t += delta
	cam_pivot.rotation.y = sin(_t * 0.12) * 0.7
	if title:
		title.rotation = sin(_t * 1.6) * 0.04
		title.scale = Vector2.ONE * (1.0 + sin(_t * 3.1) * 0.025)


func add_shake(_a: float) -> void:
	pass


## Una pelota cae al estanque y el cocodrilo hace lo suyo. Cada tanto. Para siempre.
func _croc_show() -> void:
	if not is_inside_tree() or _croc_busy:
		return
	_croc_busy = true
	var target := Vector3(randf_range(-5, -2), -0.2, randf_range(1.5, 3.5))
	var ball := B.add_mesh(self, B.sphere_mesh(0.22, 16), B.mat(Game.bomb_color(), 0.3, 0.0, 0.4), target + Vector3(0, 9, 0))
	B.add_mesh(ball, B.cyl_mesh(0.07, 0.09, 0.08, 10), B.mat(Color(0.6, 0.6, 0.65), 0.3, 0.0, 0.9), Vector3(0, 0.23, 0))
	B.add_mesh(ball, B.cyl_mesh(0.02, 0.02, 0.2, 6), B.mat(Color(0.75, 0.62, 0.4)), Vector3(0.03, 0.34, 0), Vector3(0, 0, -0.3))
	var tw := create_tween()
	tw.tween_property(ball, "position", target, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Sfx.play("splash", 0.1, -8.0)
	B.burst(self, target, Color(0.75, 0.92, 1.0), 20, 4.0, -12.0, 0.08, 0.8, 40.0)
	await get_tree().create_timer(0.5).timeout
	var croc := CrocScript.new(false)
	add_child(croc)
	var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	croc.global_position = Vector3(target.x, -0.25, target.z) - dir * 1.9
	croc.rotation.y = atan2(dir.x, dir.z)
	await croc.eat(ball)
	if is_instance_valid(ball):
		ball.queue_free()
	_croc_busy = false
	if is_inside_tree():
		get_tree().create_timer(randf_range(5.0, 8.0)).timeout.connect(_croc_show)


# ================= UI =================
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.02, 0.12, 0.35)
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 560
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	title = UiKit.label("GOLF,\nSEGÚN\nRECUERDO", 74, Color(1, 0.85, 0.25))
	title.position = Vector2(60, 18)
	title.size = Vector2(480, 250)
	title.pivot_offset = Vector2(240, 125)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -14)
	title.add_theme_constant_override("outline_size", 22)
	root.add_child(title)
	var tag := UiKit.label(TAGLINES.pick_random(), 26, Color(1, 1, 1))
	tag.position = Vector2(60, 270)
	tag.size = Vector2(480, 40)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(tag)

	main_box = VBoxContainer.new()
	main_box.position = Vector2(120, 330)
	main_box.add_theme_constant_override("separation", 12)
	root.add_child(main_box)
	main_box.add_child(UiKit.button("JUGAR", func(): main.start_run(), 34, Color(0.2, 0.75, 0.35)))
	main_box.add_child(UiKit.button("ELEGIR HOYO", func(): _show("levels")))
	main_box.add_child(UiKit.button("OPCIONES", func(): _show("options"), 30, Color(0.3, 0.5, 0.95)))
	main_box.add_child(UiKit.button("CRÉDITOS", func(): _show("credits"), 30, Color(0.65, 0.4, 0.9)))
	if OS.get_name() != "Web":
		main_box.add_child(UiKit.button("SALIR", func(): get_tree().quit(), 30, Color(0.55, 0.55, 0.6)))

	var st := Game.stats
	var stats := UiKit.label("Bombas atrapadas por la fauna: %d   ·   Caídas al vacío: %d   ·   Explosiones: %d" % [Game.animal_catches(), st.voids, st.booms], 18, Color(1, 1, 1, 0.85))
	stats.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	stats.position.y = -36
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(stats)

	panels.levels = _levels_panel(root)
	panels.options = _options_panel(root)
	panels.credits = _credits_panel(root)
	for p in panels.values():
		p.visible = false


func _make_panel(root: Control, header: String) -> Array:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiKit.panel_style())
	pc.custom_minimum_size = Vector2(680, 0)
	var holder := CenterContainer.new()
	holder.anchor_left = 0.44
	holder.anchor_right = 1.0
	holder.anchor_bottom = 1.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	holder.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var h := UiKit.label(header, 48, Color(1, 0.85, 0.3))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(h)
	return [holder, vb]


func _levels_panel(root: Control) -> Control:
	var r := _make_panel(root, "ELIGE TU SUFRIMIENTO")
	var vb: VBoxContainer = r[1]
	for i in Game.LEVELS.size():
		var lv: Dictionary = Game.LEVELS[i]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var bs: int = Game.best_stars[i]
		var extra := "Sin jugar" if bs < 0 else ("Mejor: %s" % Game.fmt_time(Game.best_time[i]) if bs > 0 else "Explotó")
		var locked := i >= Game.PLAYABLE
		if locked:
			extra = "EN CONSTRUCCIÓN"
		var b := UiKit.button("%s  ·  %s" % [lv.name, extra] if locked else "%s  ·  %d s  ·  %s" % [lv.name, int(lv.time), extra], func(): main.start_level(i), 20, Color(0.95, 0.5, 0.2).lerp(Color(0.85, 0.15, 0.2), i / 4.0))
		b.disabled = locked
		b.custom_minimum_size = Vector2(560, 54)
		hb.add_child(b)
		var st = Stars.new()
		st.setup(maxi(0, bs), 30.0)
		var cc := CenterContainer.new()
		cc.add_child(st)
		hb.add_child(cc)
		vb.add_child(hb)
	var tot := UiKit.label("Estrellas: %d / %d" % [Game.total_stars(Game.best_stars), Game.PLAYABLE * 3], 26, Color(1, 0.85, 0.3))
	tot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tot)
	vb.add_child(UiKit.button("Volver", func(): _show(""), 26, Color(0.5, 0.5, 0.55)))
	return r[0]


func _options_panel(root: Control) -> Control:
	var r := _make_panel(root, "OPCIONES")
	var vb: VBoxContainer = r[1]
	vb.add_child(_slider_row("Música", Game.settings.music, func(v: float):
		Game.settings.music = v
		Game.apply_settings()))
	vb.add_child(_slider_row("Efectos", Game.settings.sfx, func(v: float):
		Game.settings.sfx = v
		Game.apply_settings()
		Sfx.play("bounce")))
	vb.add_child(_check_row("Vibración de cámara", Game.settings.shake, func(v: bool): Game.settings.shake = v))
	vb.add_child(_check_row("Pantalla completa", Game.settings.fullscreen, func(v: bool):
		Game.settings.fullscreen = v
		Game.apply_settings()))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.add_child(UiKit.label("Bomba:", 26))
	var ob := OptionButton.new()
	ob.add_theme_font_size_override("font_size", 24)
	var keys: Array = Game.BOMB_COLORS.keys()
	for k in keys:
		ob.add_item(k)
	ob.selected = maxi(0, keys.find(Game.settings.bomb))
	ob.item_selected.connect(func(idx: int): Game.settings.bomb = keys[idx])
	ob.custom_minimum_size = Vector2(260, 48)
	hb.add_child(ob)
	vb.add_child(hb)
	vb.add_child(UiKit.button("Guardar y volver", func():
		Game.save_data()
		_show(""), 26, Color(0.2, 0.75, 0.35)))
	return r[0]


func _slider_row(text: String, value: float, cb: Callable) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	var l := UiKit.label(text, 26)
	l.custom_minimum_size.x = 160
	hb.add_child(l)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 1
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(340, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(cb)
	hb.add_child(s)
	return hb


func _check_row(text: String, value: bool, cb: Callable) -> Control:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.add_theme_font_size_override("font_size", 26)
	c.toggled.connect(cb)
	return c


func _credits_panel(root: Control) -> Control:
	var r := _make_panel(root, "CRÉDITOS")
	var vb: VBoxContainer = r[1]
	var txt := "Equipo:\nPérez Porthoz Juan Emilio\nNavarrete Pacheco Gael Alberto\nPeniche Santos Valeria Estefanía\nQue Pérez Carlos Daniel\nSalvador Carrión Ángel Alberto\nSamamé Andrade René De Jesús\n\nUniversidad del Caribe — Cancún, Q. Roo\n\"Golf, según recuerdo\" — inspirado en \"What the Golf?\"\nModelos, música y efectos generados por código · Fuente: Lilita One (SIL OFL) · Godot 4\n\nNingún cocodrilo, coatí, iguana ni murciélago resultó herido.\nWeb Shell, sí. (SIGMAA del juego es una parodia.)"
	var l := UiKit.label(txt, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 600
	vb.add_child(l)
	vb.add_child(UiKit.button("Volver", func(): _show(""), 26, Color(0.5, 0.5, 0.55)))
	return r[0]


func _show(which: String) -> void:
	for k in panels:
		var p: Control = panels[k]
		if k == which:
			p.visible = true
			p.modulate.a = 0
			var tw := create_tween()
			tw.tween_property(p, "modulate:a", 1.0, 0.2)
		else:
			p.visible = false
