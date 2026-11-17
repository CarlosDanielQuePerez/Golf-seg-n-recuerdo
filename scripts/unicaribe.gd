extends RefCounted
## Modelos 3D procedurales del campus: palmeras, edificios, iguanas, coatíes,
## murciélagos, cangrejos, ibis, águila pescadora, hongos luminosos y manglares.

const B = preload("res://scripts/build.gd")


static func palm(parent: Node, pos: Vector3, s := 1.0) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	p.scale = Vector3.ONE * s
	p.rotation.y = randf() * TAU
	parent.add_child(p)
	var bark := B.mat(Color(0.55, 0.42, 0.28))
	var lean := randf_range(0.05, 0.12)
	for i in 6:
		B.add_mesh(p, B.cyl_mesh(0.13 - i * 0.008, 0.16 - i * 0.008, 0.6, 8), bark if i % 2 == 0 else B.mat(Color(0.5, 0.37, 0.24)), Vector3(i * i * lean * 0.12, 0.3 + i * 0.55, 0), Vector3(0, 0, -i * lean * 0.5))
	var top := Vector3(25 * lean * 0.12, 3.5, 0)
	var leaf := B.mat(Color(0.2, 0.62, 0.25))
	var leaf2 := B.mat(Color(0.16, 0.52, 0.2))
	for k in 7:
		var a := k * TAU / 7
		var l := Node3D.new()
		l.position = top
		l.rotation = Vector3(0, a, 0)
		p.add_child(l)
		B.add_mesh(l, B.box_mesh(Vector3(0.35, 0.05, 1.6)), leaf if k % 2 == 0 else leaf2, Vector3(0, -0.25, 0.8), Vector3(0.45, 0, 0))
	for k in 3:
		B.add_mesh(p, B.sphere_mesh(0.13, 8), B.mat(Color(0.45, 0.3, 0.12)), top + Vector3(cos(k * 2.1) * 0.18, -0.2, sin(k * 2.1) * 0.18))
	return p


## Edificio genérico de campus con ventanas, franja de color y su nombre.
static func building(parent: Node, pos: Vector3, size: Vector3, title: String, rot_y := 0.0, accent := Color(0.1, 0.45, 0.75)) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = rot_y
	parent.add_child(b)
	# base de pasto flotante
	B.add_mesh(b, B.box_mesh(Vector3(size.x + 2.0, 0.5, size.z + 2.0)), B.mat(Color(0.3, 0.66, 0.28)), Vector3(0, -0.25, 0))
	B.add_mesh(b, B.box_mesh(Vector3(size.x + 1.6, 2.0, size.z + 1.6)), B.mat(Color(0.45, 0.3, 0.18)), Vector3(0, -1.5, 0))
	B.add_mesh(b, B.box_mesh(size), B.mat(Color(0.93, 0.91, 0.86)), Vector3(0, size.y / 2, 0))
	B.add_mesh(b, B.box_mesh(Vector3(size.x + 0.2, 0.3, size.z + 0.2)), B.mat(accent), Vector3(0, size.y + 0.15, 0))
	B.add_mesh(b, B.box_mesh(Vector3(size.x + 0.05, 0.25, size.z + 0.05)), B.mat(accent), Vector3(0, 0.9, 0))
	var glass := B.mat(Color(0.35, 0.6, 0.85), 0.15, 0.3)
	var floors := int((size.y - 1.2) / 1.3)
	var cols := int(size.x / 1.3)
	for f in floors:
		for c in cols:
			var x := -size.x / 2 + 0.65 + c * (size.x - 1.3) / maxf(1.0, cols - 1)
			B.add_mesh(b, B.box_mesh(Vector3(0.7, 0.7, 0.05)), glass, Vector3(x, 1.7 + f * 1.3, size.z / 2 + 0.02))
	B.add_mesh(b, B.box_mesh(Vector3(1.0, 1.4, 0.06)), B.mat(Color(0.3, 0.22, 0.15)), Vector3(0, 0.7, size.z / 2 + 0.03))
	var l := Label3D.new()
	l.text = title
	l.font_size = 96
	l.pixel_size = 0.008
	l.outline_size = 16
	l.modulate = Color(1, 1, 1)
	l.outline_modulate = accent.darkened(0.4)
	l.position = Vector3(0, size.y + 0.8, size.z / 2)
	b.add_child(l)
	return b


static func iguana(parent: Node) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var skin := B.mat(Color(0.35, 0.6, 0.25))
	var dark := B.mat(Color(0.22, 0.42, 0.16))
	B.add_mesh(n, B.box_mesh(Vector3(0.75, 0.28, 0.34)), skin, Vector3(0, 0.25, 0))
	B.add_mesh(n, B.box_mesh(Vector3(0.32, 0.22, 0.26)), skin, Vector3(0.5, 0.3, 0))
	B.add_mesh(n, B.box_mesh(Vector3(0.12, 0.12, 0.14)), B.mat(Color(0.85, 0.75, 0.3)), Vector3(0.42, 0.17, 0))  # papada
	for sz in [-0.09, 0.09]:
		B.add_mesh(n, B.sphere_mesh(0.045, 6), B.mat(Color(0.95, 0.75, 0.1)), Vector3(0.58, 0.36, sz))
		B.add_mesh(n, B.sphere_mesh(0.022, 4), B.mat(Color(0, 0, 0)), Vector3(0.61, 0.37, sz))
	for i in 5:
		var s := 1.0 - i * 0.17
		B.add_mesh(n, B.box_mesh(Vector3(0.3, 0.14 * s, 0.14 * s)), dark if i % 2 else skin, Vector3(-0.5 - i * 0.28, 0.2 - i * 0.02, 0))
	for i in 5:
		B.add_mesh(n, B.cyl_mesh(0.0, 0.04, 0.12, 4), dark, Vector3(0.25 - i * 0.14, 0.45, 0))
	for sx in [0.25, -0.25]:
		for sz in [-1, 1]:
			B.add_mesh(n, B.box_mesh(Vector3(0.1, 0.2, 0.1)), dark, Vector3(sx, 0.1, sz * 0.2), Vector3(sz * 0.4, 0, 0))
	# lentes de sol, porque camina por el campus como si fuera suyo
	B.add_mesh(n, B.box_mesh(Vector3(0.05, 0.07, 0.3)), B.mat(Color(0.05, 0.05, 0.05), 0.2), Vector3(0.64, 0.37, 0))
	return n


static func bat(parent: Node) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var fur := B.mat(Color(0.18, 0.13, 0.12))
	var wing_m := B.mat(Color(0.28, 0.2, 0.2))
	B.add_mesh(n, B.sphere_mesh(0.16, 8), fur, Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.9, 1.2))
	for sx in [-0.07, 0.07]:
		B.add_mesh(n, B.cyl_mesh(0.0, 0.05, 0.12, 4), fur, Vector3(sx, 0.17, 0.05))
		B.add_mesh(n, B.sphere_mesh(0.025, 4), B.mat(Color(1, 0.85, 0.3), 1.0, 2.0), Vector3(sx, 0.05, 0.16))
	for side in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(side * 0.12, 0, 0)
		n.add_child(w)
		B.add_mesh(w, B.box_mesh(Vector3(0.45, 0.02, 0.28)), wing_m, Vector3(side * 0.22, 0, 0))
		B.add_mesh(w, B.box_mesh(Vector3(0.25, 0.02, 0.18)), wing_m, Vector3(side * 0.5, 0, -0.05), Vector3(0, 0, side * 0.2))
		var tw := w.create_tween().set_loops()
		var t := randf_range(0.11, 0.15)
		tw.tween_property(w, "rotation:z", side * 0.7, t)
		tw.tween_property(w, "rotation:z", -side * 0.5, t)
	return n


## Ventana flotante de "SIGMAA" (parodia).
static func ui_window(parent: Node, pos: Vector3, size: Vector2, title: String, body: String, accent: Color, rot_y := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	B.add_mesh(n, B.box_mesh(Vector3(size.x, size.y, 0.15)), B.mat(Color(0.94, 0.96, 0.99), 0.6, 0.15))
	B.add_mesh(n, B.box_mesh(Vector3(size.x, 0.4, 0.17)), B.mat(accent, 0.5, 0.6), Vector3(0, size.y / 2 - 0.2, 0))
	var dots := [Color(1, 0.35, 0.3), Color(1, 0.8, 0.2), Color(0.3, 0.85, 0.4)]
	for i in 3:
		B.add_mesh(n, B.sphere_mesh(0.08, 6), B.mat(dots[i], 0.5, 1.0), Vector3(size.x / 2 - 0.25 - i * 0.22, size.y / 2 - 0.2, 0.1))
	var t := Label3D.new()
	t.text = title
	t.font_size = 52
	t.pixel_size = 0.006
	t.outline_size = 0
	t.modulate = Color(1, 1, 1)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.position = Vector3(-size.x / 2 + 0.15 + (size.x * 0.35), size.y / 2 - 0.2, 0.1)
	n.add_child(t)
	var b := Label3D.new()
	b.text = body
	b.font_size = 44
	b.pixel_size = 0.006
	b.outline_size = 0
	b.modulate = Color(0.12, 0.15, 0.3)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.width = (size.x - 0.4) / 0.006
	b.position = Vector3(0, -0.2, 0.09)
	n.add_child(b)
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "position:y", pos.y + 0.35, randf_range(1.6, 2.4)).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position:y", pos.y, randf_range(1.6, 2.4)).set_trans(Tween.TRANS_SINE)
	return n


static func crab(parent: Node, red: bool) -> Dictionary:
	var n := Node3D.new()
	parent.add_child(n)
	var col := Color(0.9, 0.2, 0.15) if red else Color(0.2, 0.45, 0.95)
	var shell := B.mat(col, 0.5)
	var dark := B.mat(col.darkened(0.35))
	B.add_mesh(n, B.sphere_mesh(0.5, 14), shell, Vector3(0, 0.35, 0), Vector3.ZERO, Vector3(1.3, 0.55, 1.0))
	for sx in [-0.18, 0.18]:
		B.add_mesh(n, B.cyl_mesh(0.035, 0.035, 0.3, 6), dark, Vector3(sx, 0.62, 0.32))
		B.add_mesh(n, B.sphere_mesh(0.09, 8), B.mat(Color(1, 1, 1), 0.3), Vector3(sx, 0.8, 0.32))
		B.add_mesh(n, B.sphere_mesh(0.045, 6), B.mat(Color(0, 0, 0)), Vector3(sx, 0.81, 0.4))
	for side in [-1.0, 1.0]:
		for k in 3:
			B.add_mesh(n, B.box_mesh(Vector3(0.45, 0.06, 0.07)), dark, Vector3(side * 0.62, 0.18, -0.25 + k * 0.2), Vector3(0, 0, side * -0.6))
	var claws: Array = []
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.55, 0.38, 0.4)
		n.add_child(arm)
		B.add_mesh(arm, B.box_mesh(Vector3(0.12, 0.12, 0.35)), dark, Vector3(0, 0, 0.15))
		B.add_mesh(arm, B.sphere_mesh(0.2, 10), shell, Vector3(0, 0.05, 0.42), Vector3.ZERO, Vector3(0.9, 0.8, 1.2))
		var pincer := Node3D.new()
		pincer.position = Vector3(0, 0.05, 0.55)
		arm.add_child(pincer)
		B.add_mesh(pincer, B.box_mesh(Vector3(0.08, 0.06, 0.28)), shell, Vector3(0, 0.07, 0.12))
		B.add_mesh(pincer, B.box_mesh(Vector3(0.08, 0.06, 0.28)), shell, Vector3(0, -0.07, 0.12))
		claws.append(pincer)
		var tw := pincer.create_tween().set_loops()
		var t := randf_range(0.25, 0.4)
		tw.tween_property(pincer, "rotation:x", 0.35, t)
		tw.tween_property(pincer, "rotation:x", -0.1, t)
	return {"node": n, "claws": claws}


static func ibis(parent: Node) -> Dictionary:
	var n := Node3D.new()
	parent.add_child(n)
	var white := B.mat(Color(0.97, 0.97, 0.95), 0.6)
	var red := B.mat(Color(0.95, 0.35, 0.25))
	var pink := B.mat(Color(0.95, 0.5, 0.45))
	var body := Node3D.new()
	body.position = Vector3(0, 0.75, 0)
	n.add_child(body)
	B.add_mesh(body, B.sphere_mesh(0.28, 12), white, Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 0.8, 1.35))
	for sx in [-0.2, 0.2]:
		B.add_mesh(body, B.box_mesh(Vector3(0.05, 0.12, 0.25)), B.mat(Color(0.1, 0.1, 0.1)), Vector3(sx, 0.05, -0.35))
	B.add_mesh(body, B.cyl_mesh(0.05, 0.07, 0.4, 6), white, Vector3(0, 0.3, 0.3), Vector3(0.6, 0, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.5, 0.45)
	body.add_child(head)
	B.add_mesh(head, B.sphere_mesh(0.11, 10), red)
	B.add_mesh(head, B.sphere_mesh(0.03, 6), B.mat(Color(0.1, 0.3, 0.6)), Vector3(0.08, 0.03, 0.04))
	B.add_mesh(head, B.sphere_mesh(0.03, 6), B.mat(Color(0.1, 0.3, 0.6)), Vector3(-0.08, 0.03, 0.04))
	# pico largo y curvo
	B.add_mesh(head, B.cyl_mesh(0.012, 0.035, 0.28, 6), red, Vector3(0, -0.05, 0.2), Vector3(1.9, 0, 0))
	B.add_mesh(head, B.cyl_mesh(0.008, 0.015, 0.2, 6), red, Vector3(0, -0.17, 0.37), Vector3(2.4, 0, 0))
	var legs: Array = []
	for sx in [-0.08, 0.08]:
		var leg := Node3D.new()
		leg.position = Vector3(sx, 0.55, 0)
		n.add_child(leg)
		B.add_mesh(leg, B.cyl_mesh(0.02, 0.02, 0.55, 6), pink, Vector3(0, -0.27, 0))
		B.add_mesh(leg, B.box_mesh(Vector3(0.1, 0.02, 0.14)), pink, Vector3(0, -0.54, 0.04))
		legs.append(leg)
	return {"node": n, "body": body, "head": head, "legs": legs}


static func osprey(parent: Node) -> Dictionary:
	var n := Node3D.new()
	parent.add_child(n)
	var brown := B.mat(Color(0.35, 0.24, 0.16))
	var white := B.mat(Color(0.96, 0.95, 0.92))
	B.add_mesh(n, B.sphere_mesh(0.35, 12), white, Vector3.ZERO, Vector3.ZERO, Vector3(0.85, 0.9, 1.3))
	B.add_mesh(n, B.sphere_mesh(0.3, 12), brown, Vector3(0, 0.12, -0.05), Vector3.ZERO, Vector3(0.95, 0.6, 1.3))
	var head := Node3D.new()
	head.position = Vector3(0, 0.3, 0.42)
	n.add_child(head)
	B.add_mesh(head, B.sphere_mesh(0.17, 10), white)
	for sx in [-0.1, 0.1]:
		B.add_mesh(head, B.box_mesh(Vector3(0.04, 0.05, 0.22)), B.mat(Color(0.15, 0.1, 0.07)), Vector3(sx * 1.4, 0.02, -0.02))
		B.add_mesh(head, B.sphere_mesh(0.035, 6), B.mat(Color(1, 0.85, 0.2), 0.3), Vector3(sx, 0.04, 0.12))
	B.add_mesh(head, B.cyl_mesh(0.0, 0.05, 0.15, 6), B.mat(Color(0.15, 0.15, 0.15)), Vector3(0, -0.02, 0.2), Vector3(PI / 2 + 0.4, 0, 0))
	B.add_mesh(n, B.box_mesh(Vector3(0.3, 0.05, 0.35)), brown, Vector3(0, 0, -0.55), Vector3(-0.2, 0, 0))
	var wings: Array = []
	for side in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(side * 0.25, 0.15, 0)
		n.add_child(w)
		B.add_mesh(w, B.box_mesh(Vector3(0.9, 0.05, 0.45)), brown, Vector3(side * 0.45, 0, 0))
		B.add_mesh(w, B.box_mesh(Vector3(0.45, 0.05, 0.3)), brown, Vector3(side * 1.05, 0, -0.08), Vector3(0, side * 0.2, 0))
		B.add_mesh(w, B.box_mesh(Vector3(0.6, 0.06, 0.12)), white, Vector3(side * 0.4, -0.02, 0.15))
		wings.append(w)
	var talons: Array = []
	for sx in [-0.12, 0.12]:
		var t := B.add_mesh(n, B.cyl_mesh(0.03, 0.04, 0.25, 6), B.mat(Color(0.85, 0.75, 0.4)), Vector3(sx, -0.35, 0.05))
		talons.append(t)
	return {"node": n, "wings": wings, "head": head}


static func mushroom(parent: Node, pos: Vector3, radius: float, upside_down := false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	if upside_down:
		n.rotation.z = PI
	parent.add_child(n)
	var glow := Color(0.35, 1.0, 0.85)
	B.add_mesh(n, B.cyl_mesh(0.12, 0.18, 0.7, 8), B.mat(Color(0.85, 0.95, 0.9), 0.5, 0.6), Vector3(0, 0.35, 0))
	B.add_mesh(n, B.sphere_mesh(0.55, 14), B.mat(glow, 0.4, 2.5), Vector3(0, 0.75, 0), Vector3.ZERO, Vector3(1, 0.5, 1))
	for k in 5:
		var a := k * TAU / 5
		B.add_mesh(n, B.sphere_mesh(0.07, 6), B.mat(Color(1, 1, 1), 0.4, 3.0), Vector3(cos(a) * 0.3, 0.95, sin(a) * 0.3))
	for k in 2:
		var a := randf() * TAU
		B.add_mesh(n, B.cyl_mesh(0.06, 0.09, 0.35, 6), B.mat(Color(0.85, 0.95, 0.9), 0.5, 0.6), Vector3(cos(a) * 0.5, 0.17, sin(a) * 0.5))
		B.add_mesh(n, B.sphere_mesh(0.22, 10), B.mat(glow, 0.4, 2.5), Vector3(cos(a) * 0.5, 0.38, sin(a) * 0.5), Vector3.ZERO, Vector3(1, 0.5, 1))
	var l := OmniLight3D.new()
	l.light_color = glow
	l.omni_range = radius * 1.6
	l.light_energy = 2.2
	l.position = Vector3(0, 1.0, 0)
	n.add_child(l)
	# círculo de luz: zona segura
	var disc := B.add_mesh(n, B.cyl_mesh(radius, radius, 0.02, 32), B.shader_mat("res://shaders/pad.gdshader", {"color": glow * 0.5}), Vector3(0, 0.03, 0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "light_energy", 1.6, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l, "light_energy", 2.4, 1.2).set_trans(Tween.TRANS_SINE)
	return n


static func mangrove(parent: Node, pos: Vector3, s := 1.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * s
	n.rotation.y = randf() * TAU
	parent.add_child(n)
	var bark := B.mat(Color(0.42, 0.33, 0.25))
	# raíces en arco que salen del agua
	for k in 7:
		var a := k * TAU / 7
		var r := Node3D.new()
		r.rotation.y = a
		n.add_child(r)
		B.add_mesh(r, B.cyl_mesh(0.07, 0.09, 1.6, 6), bark, Vector3(0.75, 0.6, 0), Vector3(0, 0, 0.75))
		B.add_mesh(r, B.cyl_mesh(0.06, 0.07, 0.9, 6), bark, Vector3(1.25, 0.3, 0), Vector3(0, 0, -0.2))
	B.add_mesh(n, B.cyl_mesh(0.18, 0.24, 2.4, 8), bark, Vector3(0, 2.2, 0))
	var greens := [Color(0.16, 0.45, 0.22), Color(0.2, 0.52, 0.25), Color(0.13, 0.4, 0.2)]
	for k in 5:
		B.add_mesh(n, B.sphere_mesh(randf_range(0.9, 1.3), 10), B.mat(greens[k % 3]), Vector3(randf_range(-0.9, 0.9), 3.6 + randf() * 0.6, randf_range(-0.9, 0.9)), Vector3.ZERO, Vector3(1, 0.7, 1))
	return n


## La tortuga de SIGMAA: pequeña, mayor (con lentes) y con caparazón de servidor.
static func sigmaa_turtle(parent: Node) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var skin := B.mat(Color(0.45, 0.62, 0.42))
	var shell := B.mat(Color(0.12, 0.22, 0.45), 0.4)
	var blue := B.mat(Color(0.35, 0.75, 1.0), 0.4, 2.5)
	B.add_mesh(n, B.sphere_mesh(0.42, 16), shell, Vector3(0, 0.38, 0), Vector3.ZERO, Vector3(1.0, 0.7, 1.15))
	B.add_mesh(n, B.cyl_mesh(0.44, 0.46, 0.08, 16), B.mat(Color(0.85, 0.75, 0.55)), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(1, 1, 1.15))
	for k in 6:
		var a := k * TAU / 6
		B.add_mesh(n, B.box_mesh(Vector3(0.18, 0.02, 0.04)), blue, Vector3(cos(a) * 0.22, 0.62, sin(a) * 0.26), Vector3(0, -a, 0))
	B.add_mesh(n, B.cyl_mesh(0.07, 0.07, 0.03, 6), blue, Vector3(0, 0.67, 0))
	for sx in [-0.28, 0.28]:
		for sz in [-0.28, 0.28]:
			B.add_mesh(n, B.cyl_mesh(0.07, 0.08, 0.2, 8), skin, Vector3(sx, 0.1, sz))
	var head := Node3D.new()
	head.position = Vector3(0, 0.4, 0.5)
	n.add_child(head)
	B.add_mesh(head, B.sphere_mesh(0.16, 12), skin, Vector3(0, 0.05, 0.05), Vector3.ZERO, Vector3(1, 0.9, 1.15))
	for sx in [-0.07, 0.07]:
		B.add_mesh(head, B.sphere_mesh(0.035, 6), B.mat(Color(0.05, 0.05, 0.05)), Vector3(sx, 0.1, 0.19))
		var tor := TorusMesh.new()
		tor.inner_radius = 0.045
		tor.outer_radius = 0.06
		B.add_mesh(head, tor, B.mat(Color(0.85, 0.7, 0.2), 0.3, 0.0, 0.9), Vector3(sx, 0.1, 0.2), Vector3(PI / 2, 0, 0))
	B.add_mesh(head, B.box_mesh(Vector3(0.05, 0.015, 0.015)), B.mat(Color(0.85, 0.7, 0.2), 0.3, 0.0, 0.9), Vector3(0, 0.1, 0.21))
	B.add_mesh(n, B.cyl_mesh(0.0, 0.06, 0.15, 6), skin, Vector3(0, 0.25, -0.5), Vector3(-PI / 2, 0, 0))
	return n
