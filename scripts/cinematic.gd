extends CanvasLayer
## Capa de cinemáticas: franjas negras, diálogo con efecto máquina de escribir,
## botón para saltar y la presentación estilo "character splash".

const UiKit = preload("res://scripts/ui_kit.gd")

signal advanced

var skipped := false
var can_skip := true
var _root: Control
var _top: ColorRect
var _bottom: ColorRect
var _box: PanelContainer
var _name: Label
var _text: Label
var _hint: Label
var _skip_btn: Button
var _typing := false
var _line_id := 0
var _type_tween: Tween


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_top = ColorRect.new()
	_top.color = Color.BLACK
	_root.add_child(_top)
	_place(_top, Vector4(0, 0, 1, 0), Vector4(0, -90, 0, 0))
	_bottom = ColorRect.new()
	_bottom.color = Color.BLACK
	_root.add_child(_bottom)
	_place(_bottom, Vector4(0, 1, 1, 1), Vector4(0, 0, 0, 90))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_top, "offset_bottom", 80.0, 0.5)
	tw.tween_property(_top, "offset_top", 0.0, 0.5)
	tw.tween_property(_bottom, "offset_top", -80.0, 0.5)
	tw.tween_property(_bottom, "offset_bottom", 0.0, 0.5)
	# caja de diálogo
	_box = PanelContainer.new()
	var sb := UiKit.panel_style()
	sb.bg_color = Color(0.04, 0.06, 0.16, 0.92)
	sb.border_color = Color(0.35, 0.65, 1.0)
	_box.add_theme_stylebox_override("panel", sb)
	_root.add_child(_box)
	_place(_box, Vector4(0.5, 1, 0.5, 1), Vector4(-520, -250, 520, -96))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_box.add_child(vb)
	_name = UiKit.label("SIGMAA", 30, Color(0.45, 0.8, 1.0))
	vb.add_child(_name)
	_text = UiKit.label("", 24, Color(1, 1, 1))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(960, 80)
	vb.add_child(_text)
	_hint = UiKit.label("Clic / Espacio para continuar", 16, Color(1, 1, 1, 0.6))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_hint)
	_box.visible = false
	_skip_btn = UiKit.button("SALTAR CINEMÁTICA (ESC)", func(): skip(), 20, Color(0.35, 0.35, 0.45))
	_skip_btn.custom_minimum_size = Vector2(300, 46)
	_root.add_child(_skip_btn)
	_place(_skip_btn, Vector4(1, 0, 1, 0), Vector4(-320, 18, -20, 64))


func _place(c: Control, a: Vector4, o: Vector4) -> void:
	c.anchor_left = a.x
	c.anchor_top = a.y
	c.anchor_right = a.z
	c.anchor_bottom = a.w
	c.offset_left = o.x
	c.offset_top = o.y
	c.offset_right = o.z
	c.offset_bottom = o.w


func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE and can_skip:
			skip()
			get_viewport().set_input_as_handled()
		elif e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance()
			get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _box.visible:
		_advance()


func _done_typing() -> void:
	_typing = false


func _advance() -> void:
	if _typing:
		if _type_tween:
			_type_tween.kill()
		_text.visible_ratio = 1.0
		_typing = false
	else:
		advanced.emit()


func skip() -> void:
	if skipped or not can_skip:
		return
	skipped = true
	advanced.emit()


## Muestra una línea de diálogo y espera a que el jugador avance (o pase el tiempo de lectura).
func say(speaker: String, text: String, color := Color(0.45, 0.8, 1.0)) -> void:
	if skipped:
		return
	_box.visible = true
	_name.text = speaker
	_name.add_theme_color_override("font_color", color)
	_text.text = text
	_text.visible_ratio = 0.0
	_typing = true
	_type_tween = create_tween()
	_type_tween.tween_property(_text, "visible_ratio", 1.0, text.length() * 0.028)
	_type_tween.tween_callback(_done_typing)
	_line_id += 1
	var t := get_tree().create_timer(text.length() * 0.028 + 3.2 + text.length() * 0.025)
	t.timeout.connect(_auto_advance.bind(_line_id))
	await advanced
	_box.visible = false


func _auto_advance(id: int) -> void:
	if id == _line_id and _box.visible:
		_typing = false
		advanced.emit()


func hide_box() -> void:
	_box.visible = false


## Presentación del jefe: franja diagonal, destello y nombre gigante.
func splash(title: String, subtitle: String, small: String) -> void:
	if skipped:
		return
	_skip_btn.visible = false
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	var vp := get_viewport().get_visible_rect().size
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(0, vp.y * 0.38), Vector2(vp.x, vp.y * 0.22), Vector2(vp.x, vp.y * 0.62), Vector2(0, vp.y * 0.78)])
	band.color = Color(0.95, 0.45, 0.1, 0.92)
	holder.add_child(band)
	var band2 := Polygon2D.new()
	band2.polygon = PackedVector2Array([Vector2(0, vp.y * 0.74), Vector2(vp.x, vp.y * 0.58), Vector2(vp.x, vp.y * 0.64), Vector2(0, vp.y * 0.8)])
	band2.color = Color(0.1, 0.35, 0.9, 0.95)
	holder.add_child(band2)
	band.position.x = vp.x
	band2.position.x = -vp.x
	var big := UiKit.label(title, 150, Color(1, 1, 1))
	big.add_theme_constant_override("outline_size", 30)
	big.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02))
	holder.add_child(big)
	big.position = Vector2(vp.x * 0.45 + vp.x, vp.y * 0.3)
	var sub := UiKit.label(subtitle, 40, Color(1, 0.95, 0.8))
	holder.add_child(sub)
	sub.position = Vector2(vp.x * 0.47 + vp.x, vp.y * 0.3 + 170)
	var tiny := UiKit.label(small, 22, Color(0.8, 0.9, 1.0))
	holder.add_child(tiny)
	tiny.position = Vector2(vp.x * 0.47, vp.y * 0.3 + 225)
	tiny.modulate.a = 0.0
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(flash)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	tw.tween_property(band, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(band2, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(big, "position:x", vp.x * 0.45, 0.35).set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "position:x", vp.x * 0.47, 0.35).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(tiny, "modulate:a", 1.0, 0.3).set_delay(0.5)
	await get_tree().create_timer(2.8).timeout
	tw = create_tween().set_parallel(true)
	tw.tween_property(holder, "modulate:a", 0.0, 0.3)
	await tw.finished
	holder.queue_free()
	_skip_btn.visible = true


func close() -> void:
	_box.visible = false
	_skip_btn.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_top, "offset_bottom", 0.0, 0.4)
	tw.tween_property(_top, "offset_top", -90.0, 0.4)
	tw.tween_property(_bottom, "offset_top", 0.0, 0.4)
	tw.tween_property(_bottom, "offset_bottom", 90.0, 0.4)
	await tw.finished
	queue_free()
