extends CanvasLayer
## Interfaz dentro del hoyo: golpes, potencia, mensajes, pausa y resultado.

const UiKit = preload("res://scripts/ui_kit.gd")
const Stars = preload("res://scripts/stars.gd")

var level  # nodo del nivel
var title_lbl: Label
var strokes_lbl: Label
var timer_lbl: Label
var fuse_bar: ProgressBar
var flash_lbl: Label
var goal_lbl: Label
var boss_box: Control
var boss_bar: ProgressBar
var boss_lbl: Label
var boss_max := 3
var mode_lbl: Label
var help_lbl: Label
var power_bar: ProgressBar
var power_box: Control
var popup_lbl: Label
var sub_lbl: Label
var pause_panel: Control
var result_panel: Control
var _popup_tween: Tween


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	title_lbl = _label(root, "", 30, Color(1, 1, 1))
	_place(title_lbl, Vector4(0, 0, 0, 0), Vector4(24, 14, 900, 60))
	strokes_lbl = _label(root, "", 34, Color(1, 0.92, 0.4))
	_place(strokes_lbl, Vector4(1, 0, 1, 0), Vector4(-460, 12, -24, 62))
	strokes_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# temporizador (la mecha)
	timer_lbl = _label(root, "1:00.0", 56, Color(1, 1, 1))
	_place(timer_lbl, Vector4(0.5, 0, 0.5, 0), Vector4(-160, 4, 160, 70))
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.pivot_offset = Vector2(160, 33)
	fuse_bar = ProgressBar.new()
	fuse_bar.show_percentage = false
	fuse_bar.max_value = 1.0
	var fb := StyleBoxFlat.new()
	fb.bg_color = Color(0.1, 0.06, 0.04, 0.6)
	fb.set_corner_radius_all(8)
	fb.set_border_width_all(2)
	fb.border_color = Color(0.2, 0.1, 0.05)
	var ff := StyleBoxFlat.new()
	ff.bg_color = Color(0.85, 0.7, 0.45)
	ff.set_corner_radius_all(6)
	fuse_bar.add_theme_stylebox_override("background", fb)
	fuse_bar.add_theme_stylebox_override("fill", ff)
	root.add_child(fuse_bar)
	_place(fuse_bar, Vector4(0.5, 0, 0.5, 0), Vector4(-200, 74, 200, 90))
	flash_lbl = _label(root, "", 40, Color(1, 0.4, 0.3))
	_place(flash_lbl, Vector4(0.5, 0, 0.5, 0), Vector4(170, 14, 400, 64))
	flash_lbl.modulate.a = 0.0
	goal_lbl = _label(root, "", 20, Color(1, 1, 1, 0.85))
	_place(goal_lbl, Vector4(0.5, 0, 0.5, 0), Vector4(-300, 94, 300, 122))
	goal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	help_lbl = _label(root, "Arrastra hacia atrás para tirar  ·  Clic der./Q-E: cámara  ·  Rueda: zoom  ·  F: rodar/elevar  ·  R: reiniciar tiro (-3 s)  ·  Esc: pausa", 17, Color(1, 1, 1, 0.8))
	_place(help_lbl, Vector4(0, 1, 1, 1), Vector4(0, -40, 0, -8))
	help_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	mode_lbl = _label(root, "", 24, Color(0.6, 1, 0.7))
	_place(mode_lbl, Vector4(0, 1, 0, 1), Vector4(24, -86, 700, -50))

	power_box = Control.new()
	power_box.visible = false
	root.add_child(power_box)
	_place(power_box, Vector4(0.5, 1, 0.5, 1), Vector4(-180, -130, 180, -90))
	power_bar = ProgressBar.new()
	power_bar.size = Vector2(360, 30)
	power_bar.show_percentage = false
	power_bar.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(14)
	bg.set_border_width_all(3)
	bg.border_color = Color.WHITE
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.3, 1, 0.4)
	fg.set_corner_radius_all(12)
	power_bar.add_theme_stylebox_override("background", bg)
	power_bar.add_theme_stylebox_override("fill", fg)
	power_box.add_child(power_bar)

	popup_lbl = _label(root, "", 84, Color(1, 1, 1))
	_place(popup_lbl, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-640, -210, 640, -90))
	popup_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_lbl.pivot_offset = Vector2(640, 60)
	popup_lbl.modulate.a = 0
	sub_lbl = _label(root, "", 32, Color(1, 1, 1))
	_place(sub_lbl, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-640, -90, 640, -40))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.modulate.a = 0

	pause_panel = _panel(root, "PAUSA", [
		["Continuar", func(): level.toggle_pause()],
		["Reiniciar hoyo", func(): level.restart_level()],
		["Menú principal", func(): level.go_menu()],
	], "El cocodrilo también se toma un descanso.")
	result_panel = null


func setup(level_name: String, info: Dictionary) -> void:
	title_lbl.text = level_name
	goal_lbl.text = "3 estrellas: menos de %d s   ·   2 estrellas: menos de %d s" % [int(info.t3), int(info.t2)]
	set_strokes(0)


func set_time(left: float, total: float) -> void:
	var frac := clampf(left / total, 0.0, 1.0)
	timer_lbl.text = Game.fmt_time(left)
	fuse_bar.value = frac
	var col := Color(1, 1, 1)
	if left < 10.0:
		col = Color(1, 0.3, 0.25)
		timer_lbl.scale = Vector2.ONE * (1.0 + 0.12 * absf(sin(left * PI)))
	elif left < 20.0:
		col = Color(1, 0.8, 0.3)
		timer_lbl.scale = Vector2.ONE
	timer_lbl.add_theme_color_override("font_color", col)
	(fuse_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.85, 0.7, 0.45).lerp(Color(1, 0.25, 0.1), 1.0 - frac)


func flash_time(text: String, color: Color) -> void:
	flash_lbl.text = text
	flash_lbl.add_theme_color_override("font_color", color)
	flash_lbl.modulate.a = 1.0
	flash_lbl.position.y = 14
	var tw := create_tween()
	tw.tween_property(flash_lbl, "position:y", 40.0, 1.0)
	tw.parallel().tween_property(flash_lbl, "modulate:a", 0.0, 1.0).set_delay(0.4)


func set_strokes(s: int) -> void:
	strokes_lbl.text = "Golpes: %d" % s
	var tw := create_tween()
	strokes_lbl.pivot_offset = strokes_lbl.size * Vector2(1.0, 0.5)
	tw.tween_property(strokes_lbl, "scale", Vector2(1.2, 1.2), 0.06)
	tw.tween_property(strokes_lbl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func set_mode(loft: bool) -> void:
	mode_lbl.text = "Modo: ELEVAR (por el aire)" if loft else "Modo: RODAR (por el suelo)"
	mode_lbl.modulate = Color(1, 0.8, 0.4) if loft else Color(0.6, 1, 0.7)


func show_power(v: float, visible_: bool) -> void:
	power_box.visible = visible_
	power_bar.value = v
	var fg: StyleBoxFlat = power_bar.get_theme_stylebox("fill")
	fg.bg_color = Color(0.3, 1, 0.4).lerp(Color(1, 0.85, 0.2), clampf(v * 2, 0, 1)).lerp(Color(1, 0.25, 0.2), clampf(v * 2 - 1, 0, 1))


func popup(text: String, sub := "", color := Color.WHITE, time := 1.8) -> void:
	popup_lbl.text = text
	popup_lbl.modulate = color
	sub_lbl.text = sub
	if _popup_tween:
		_popup_tween.kill()
	popup_lbl.scale = Vector2(0.2, 0.2)
	popup_lbl.rotation = randf_range(-0.12, 0.12)
	sub_lbl.modulate.a = 0
	_popup_tween = create_tween()
	_popup_tween.tween_property(popup_lbl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.parallel().tween_property(popup_lbl, "rotation", randf_range(-0.05, 0.05), 0.35)
	_popup_tween.parallel().tween_property(sub_lbl, "modulate:a", 1.0, 0.3).set_delay(0.15)
	_popup_tween.tween_interval(time)
	_popup_tween.tween_property(popup_lbl, "modulate:a", 0.0, 0.35)
	_popup_tween.parallel().tween_property(sub_lbl, "modulate:a", 0.0, 0.35)


func show_pause(v: bool) -> void:
	pause_panel.visible = v


func show_result(title: String, detail: String, stars: int, last_level: bool, in_run: bool, failed: bool) -> void:
	help_lbl.visible = false
	power_box.visible = false
	var next_text := "Siguiente hoyo"
	if last_level:
		next_text = "Ver tarjeta final" if in_run else "Volver al menú"
	var items := []
	if failed:
		items.append(["Reintentar", func(): level.restart_level()])
		items.append([next_text + " (0 estrellas)", func(): level.next_level()])
	else:
		items.append([next_text, func(): level.next_level()])
		items.append(["Repetir hoyo", func(): level.restart_level()])
	items.append(["Menú", func(): level.go_menu()])
	result_panel = _panel(get_child(0), title, items, detail, stars)
	result_panel.visible = true
	result_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(result_panel, "modulate:a", 1.0, 0.4)


func boss_show(title: String, max_hp: int) -> void:
	boss_max = max_hp
	boss_box = Control.new()
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_child(0).add_child(boss_box)
	_place(boss_box, Vector4(0.5, 0, 0.5, 0), Vector4(-220, 126, 220, 180))
	boss_lbl = _label(boss_box, title, 22, Color(1, 0.5, 0.45))
	_place(boss_lbl, Vector4(0, 0, 1, 0), Vector4(0, 0, 0, 26))
	boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.max_value = max_hp
	boss_bar.value = max_hp
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.12, 0.7)
	bg.set_corner_radius_all(8)
	bg.set_border_width_all(3)
	bg.border_color = Color(1, 1, 1)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.35, 0.95, 1.0)
	fg.set_corner_radius_all(6)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar.add_theme_stylebox_override("fill", fg)
	boss_box.add_child(boss_bar)
	_place(boss_bar, Vector4(0, 0, 1, 0), Vector4(0, 28, 0, 50))


func boss_set(hp: int) -> void:
	if boss_bar == null:
		return
	var tw := create_tween()
	tw.tween_property(boss_bar, "value", float(hp), 0.3)
	(boss_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.35, 0.95, 1.0).lerp(Color(1, 0.3, 0.25), 1.0 - float(hp) / boss_max)
	boss_box.pivot_offset = boss_box.size / 2
	var t2 := create_tween()
	t2.tween_property(boss_box, "scale", Vector2(1.15, 1.15), 0.06)
	t2.tween_property(boss_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
	if hp <= 0:
		boss_lbl.text = "WEB SHELL — ¡EXPUESTO!"
		boss_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))


var dark_bar: ProgressBar


func dark_show() -> void:
	boss_show("OSCURIDAD (murciélagos)", 1)
	dark_bar = boss_bar
	boss_bar.value = 0.0
	(boss_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.55, 0.35, 0.9)


func dark_set(frac: float) -> void:
	if dark_bar == null:
		return
	dark_bar.value = clampf(frac, 0.0, 1.0)
	(dark_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.55, 0.35, 0.9).lerp(Color(1, 0.25, 0.2), clampf((frac - 0.5) * 2.0, 0.0, 1.0))
	boss_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0) if frac < 0.7 else Color(1, 0.4, 0.35))


# ---------- helpers ----------
func _place(c: Control, anchors: Vector4, offsets: Vector4) -> void:
	c.anchor_left = anchors.x
	c.anchor_top = anchors.y
	c.anchor_right = anchors.z
	c.anchor_bottom = anchors.w
	c.offset_left = offsets.x
	c.offset_top = offsets.y
	c.offset_right = offsets.z
	c.offset_bottom = offsets.w


func _label(parent: Control, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.12))
	l.add_theme_constant_override("outline_size", max(6, size / 5))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _panel(parent: Control, title: String, items: Array, detail := "", stars := -1) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.1, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	parent.add_child(dim)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.22, 0.95)
	sb.set_corner_radius_all(26)
	sb.set_border_width_all(5)
	sb.border_color = Color(1, 0.85, 0.3)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 16
	panel.add_theme_stylebox_override("panel", sb)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var t := _label(vb, title, 56, Color(1, 0.85, 0.3))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if stars >= 0:
		var cc2 := CenterContainer.new()
		vb.add_child(cc2)
		var st = Stars.new()
		cc2.add_child(st)
		st.setup(stars, 64.0, true)
	if detail != "":
		var d := _label(vb, detail, 24, Color(1, 1, 1, 0.9))
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 520
	for it in items:
		vb.add_child(UiKit.button(it[0], it[1]))
	return dim
