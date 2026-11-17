extends CanvasLayer
## Tarjeta final: tiempo y estrellas por hoyo.

const UiKit = preload("res://scripts/ui_kit.gd")
const Stars = preload("res://scripts/stars.gd")

var main: Node
var bg: ColorRect
var _t := 0.0


func _ready() -> void:
	Sfx.music("victory")
	Sfx.play("cheer")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.08, 0.25)
	root.add_child(bg)
	for c in [Color(1, 0.2, 0.3), Color(1, 0.85, 0.1), Color(0.2, 0.6, 1), Color(0.3, 1, 0.4), Color(1, 0.4, 0.9)]:
		var p := CPUParticles2D.new()
		p.amount = 40
		p.lifetime = 5.0
		p.position = Vector2(640, -20)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(900, 10)
		p.direction = Vector2(0, 1)
		p.gravity = Vector2(0, 60)
		p.initial_velocity_min = 40
		p.initial_velocity_max = 120
		p.angular_velocity_min = -300
		p.angular_velocity_max = 300
		p.scale_amount_min = 6
		p.scale_amount_max = 12
		p.color = c
		root.add_child(p)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	cc.add_child(vb)
	var title := UiKit.label("TARJETA DE PUNTUACIÓN", 60, Color(1, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	vb.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(grid)
	for h in ["Hoyo", "Tiempo", "Golpes", "Estrellas"]:
		grid.add_child(UiKit.label(h, 28, Color(1, 0.85, 0.3)))
	for i in Game.PLAYABLE:
		var lv: Dictionary = Game.LEVELS[i]
		var s: int = Game.run_stars[i]
		grid.add_child(UiKit.label(String(lv.name).get_slice(":", 1).strip_edges(), 24))
		grid.add_child(UiKit.label("¡BOOM!" if s == 0 else Game.fmt_time(Game.run_times[i]), 24, Color(1, 0.5, 0.4) if s == 0 else Color(1, 1, 1)))
		grid.add_child(UiKit.label(str(Game.run_strokes[i]), 24))
		var st = Stars.new()
		st.setup(s, 28.0)
		grid.add_child(st)
	var total: int = Game.total_stars(Game.run_stars)
	var big := HBoxContainer.new()
	big.alignment = BoxContainer.ALIGNMENT_CENTER
	big.add_theme_constant_override("separation", 16)
	big.add_child(UiKit.label("TOTAL: %d / %d" % [total, Game.PLAYABLE * 3], 40, Color(1, 0.85, 0.3)))
	vb.add_child(big)
	var rank := "Patrocinador Oficial de Cocodrilos"
	var mx := Game.PLAYABLE * 3
	if total >= mx:
		rank = "Leyenda Explosiva"
	elif total >= int(mx * 0.8):
		rank = "Artificiero Profesional"
	elif total >= int(mx * 0.5):
		rank = "Golfista con Mecha Corta"
	elif total >= int(mx * 0.25):
		rank = "Amigo de los Cocodrilos"
	var r := UiKit.label("Rango: " + rank, 36, Color(0.6, 1, 0.8))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(r)
	var stt := Game.stats
	var s2 := UiKit.label("Atrapadas por la fauna: %d · Explosiones: %d" % [Game.animal_catches(), stt.booms], 20, Color(1, 1, 1, 0.8))
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s2)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	hb.add_child(UiKit.button("Jugar otra vez", func(): main.start_run(), 28, Color(0.2, 0.75, 0.35)))
	hb.add_child(UiKit.button("Menú", func(): main.show_menu(), 28, Color(0.5, 0.5, 0.6)))
	vb.add_child(hb)
	Game.in_run = false


func _process(delta: float) -> void:
	_t += delta
	bg.color = Color.from_hsv(fmod(0.72 + sin(_t * 0.2) * 0.06, 1.0), 0.6, 0.25)
