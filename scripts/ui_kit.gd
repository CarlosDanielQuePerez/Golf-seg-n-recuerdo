extends RefCounted
## Botones y estilos de interfaz con "jugo" (rebote al pasar el mouse, sonidos).


static func style(color: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(4)
	sb.border_color = border
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 5)
	return sb


static func button(text: String, cb: Callable, size := 30, color := Color(0.98, 0.45, 0.25)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 62)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.85))
	b.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.1))
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_stylebox_override("normal", style(color, Color(0.2, 0.08, 0.12)))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.18), Color(1, 0.95, 0.6)))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.2), Color(1, 0.95, 0.6)))
	b.add_theme_stylebox_override("focus", style(color.lightened(0.1), Color(1, 1, 1)))
	b.add_theme_stylebox_override("disabled", style(Color(0.4, 0.4, 0.45), Color(0.2, 0.2, 0.25)))
	b.mouse_entered.connect(func():
		Sfx.play("hover", 0.1)
		b.pivot_offset = b.size / 2
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.07, 1.07), 0.12).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(b, "rotation", randf_range(-0.04, 0.04), 0.12))
	b.mouse_exited.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.12)
		tw.parallel().tween_property(b, "rotation", 0.0, 0.12))
	b.pressed.connect(func():
		Sfx.play("click", 0.05)
		cb.call())
	return b


static func label(text: String, size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.12))
	l.add_theme_constant_override("outline_size", max(6, size / 5))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 4)
	return l


static func panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.22, 0.93)
	sb.set_corner_radius_all(26)
	sb.set_border_width_all(5)
	sb.border_color = Color(1, 0.85, 0.3)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 16
	return sb
