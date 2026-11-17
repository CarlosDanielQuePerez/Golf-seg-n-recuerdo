extends Node3D
## El cocodrilo. Sale del agua (o de la lava), se traga la pelota, eructa humo y se hunde.

const B = preload("res://scripts/build.gd")

var lava := false
var upper_jaw: Node3D
var lower_jaw: Node3D
var head: Node3D
var mouth_point: Node3D
var eyes: Array[Node3D] = []
var tail: Node3D


func _init(is_lava := false) -> void:
	lava = is_lava


func _ready() -> void:
	var skin := Color(0.22, 0.48, 0.2) if not lava else Color(0.35, 0.3, 0.12)
	var dark := skin.darkened(0.35)
	var belly := Color(0.75, 0.8, 0.45) if not lava else Color(0.9, 0.6, 0.3)
	var m_skin := B.mat(skin)
	var m_dark := B.mat(dark)
	var white := B.mat(Color(0.98, 0.97, 0.9), 0.4)
	var black := B.mat(Color(0.05, 0.05, 0.05), 0.2)

	var body := Node3D.new()
	add_child(body)
	# cuerpo y escamas del lomo
	B.add_mesh(body, B.box_mesh(Vector3(0.95, 0.55, 2.2)), m_skin, Vector3(0, 0, -0.2))
	B.add_mesh(body, B.box_mesh(Vector3(0.8, 0.12, 2.0)), B.mat(belly), Vector3(0, -0.3, -0.2))
	for i in 7:
		B.add_mesh(body, B.box_mesh(Vector3(0.18, 0.18, 0.18)), m_dark, Vector3(-0.2, 0.3, 0.7 - i * 0.3), Vector3(0.785, 0, 0.785))
		B.add_mesh(body, B.box_mesh(Vector3(0.18, 0.18, 0.18)), m_dark, Vector3(0.2, 0.3, 0.55 - i * 0.3), Vector3(0.785, 0, 0.785))
	# cola
	tail = Node3D.new()
	tail.position = Vector3(0, -0.05, -1.3)
	body.add_child(tail)
	for i in 4:
		var s := 1.0 - i * 0.2
		B.add_mesh(tail, B.box_mesh(Vector3(0.7 * s, 0.4 * s, 0.6)), m_skin, Vector3(0, 0, -0.3 - i * 0.55))
		B.add_mesh(tail, B.box_mesh(Vector3(0.12, 0.15, 0.12)), m_dark, Vector3(0, 0.22 * s, -0.3 - i * 0.55), Vector3(0.785, 0, 0.785))
	# patas
	for sx in [-1, 1]:
		for sz in [0.5, -0.8]:
			B.add_mesh(body, B.box_mesh(Vector3(0.3, 0.35, 0.3)), m_dark, Vector3(sx * 0.55, -0.25, sz), Vector3(0, 0, sx * 0.4))

	# cabeza con mandíbulas articuladas
	head = Node3D.new()
	head.position = Vector3(0, 0.05, 0.9)
	body.add_child(head)
	upper_jaw = Node3D.new()
	head.add_child(upper_jaw)
	B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.85, 0.3, 0.6)), m_skin, Vector3(0, 0.08, 0.25))
	B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.6, 0.22, 1.1)), m_skin, Vector3(0, 0.02, 1.0))
	B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.62, 0.05, 1.05)), B.mat(Color(0.9, 0.4, 0.45)), Vector3(0, -0.1, 0.95))
	# fosas nasales
	for sx in [-0.12, 0.12]:
		B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.08, 0.06, 0.08)), black, Vector3(sx, 0.14, 1.45))
	# dientes de arriba
	for i in 6:
		for sx in [-0.27, 0.27]:
			B.add_mesh(upper_jaw, B.cyl_mesh(0.0, 0.05, 0.14, 4), white, Vector3(sx, -0.16, 0.55 + i * 0.17), Vector3(PI, 0, 0))
	# ojos saltones
	for sx in [-0.25, 0.25]:
		var eye := Node3D.new()
		eye.position = Vector3(sx, 0.32, 0.2)
		upper_jaw.add_child(eye)
		B.add_mesh(eye, B.sphere_mesh(0.16, 10), m_skin, Vector3(0, -0.03, 0))
		B.add_mesh(eye, B.sphere_mesh(0.13, 10), white, Vector3(0, 0.03, 0.06))
		B.add_mesh(eye, B.sphere_mesh(0.065, 8), black, Vector3(0, 0.05, 0.17))
		eyes.append(eye)
	if lava:
		# Don Coco usa lentes de sol. Obviamente.
		B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.75, 0.14, 0.05)), black, Vector3(0, 0.37, 0.33))
		B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.9, 0.04, 0.04)), black, Vector3(0, 0.43, 0.33))
		B.add_mesh(upper_jaw, B.box_mesh(Vector3(0.3, 0.2, 0.18)), B.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.55, 0.0))  # sombrerito
		B.add_mesh(upper_jaw, B.cyl_mesh(0.3, 0.3, 0.03, 12), B.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.46, 0.0))
	lower_jaw = Node3D.new()
	lower_jaw.position = Vector3(0, -0.12, 0)
	head.add_child(lower_jaw)
	B.add_mesh(lower_jaw, B.box_mesh(Vector3(0.75, 0.18, 0.6)), m_skin, Vector3(0, -0.05, 0.25))
	B.add_mesh(lower_jaw, B.box_mesh(Vector3(0.56, 0.16, 1.1)), m_skin, Vector3(0, -0.05, 1.0))
	B.add_mesh(lower_jaw, B.box_mesh(Vector3(0.5, 0.04, 1.0)), B.mat(Color(0.75, 0.25, 0.3)), Vector3(0, 0.04, 0.95))
	for i in 6:
		for sx in [-0.23, 0.23]:
			B.add_mesh(lower_jaw, B.cyl_mesh(0.0, 0.045, 0.12, 4), white, Vector3(sx, 0.09, 0.6 + i * 0.17))
	mouth_point = Node3D.new()
	mouth_point.position = Vector3(0, -0.02, 1.05)
	head.add_child(mouth_point)


## Secuencia completa. `ball` es la pelota (congelada), `surface` la altura del líquido.
func eat(ball: Node3D) -> void:
	var tw: Tween
	var surface := global_position.y
	var base := global_position
	# 1) espera bajo el agua y asoma los ojos
	global_position = base + Vector3(0, -1.6, 0)
	tw = create_tween()
	tw.tween_property(self, "global_position:y", surface - 0.35, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Sfx.play("bubbles")
	await tw.finished
	# parpadeo sospechoso
	for e in eyes:
		var t2 := create_tween()
		t2.tween_property(e, "scale:y", 0.1, 0.07)
		t2.tween_property(e, "scale:y", 1.0, 0.07)
	await get_tree().create_timer(0.35).timeout
	Sfx.play("growl", 0.05)
	# 2) se lanza con la boca abierta
	tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position:y", surface + 0.05, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation:x", -0.35, 0.22)
	tw.tween_property(upper_jaw, "rotation:x", -0.95, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lower_jaw, "rotation:x", 0.35, 0.2)
	await tw.finished
	Sfx.play("splash", 0.1, -4.0)
	B.burst(get_parent(), Vector3(base.x, surface, base.z), Color(0.7, 0.9, 1.0) if not lava else Color(1, 0.5, 0.1), 26, 5.0, -12.0, 0.1, 0.8, 50.0)
	# 3) ¡ÑAM!
	if is_instance_valid(ball):
		var t3 := create_tween()
		t3.tween_property(ball, "global_position", mouth_point.global_position, 0.12)
		await t3.finished
	tw = create_tween().set_parallel(true)
	tw.tween_property(upper_jaw, "rotation:x", 0.0, 0.07)
	tw.tween_property(lower_jaw, "rotation:x", 0.0, 0.07)
	await tw.finished
	if is_instance_valid(ball):
		ball.visible = false
	Sfx.play("chomp", 0.05)
	get_parent().call("add_shake", 0.45)
	# 4) mastica
	for i in 2:
		tw = create_tween()
		tw.tween_property(upper_jaw, "rotation:x", -0.18, 0.09)
		tw.parallel().tween_property(self, "scale", Vector3(1.08, 0.92, 1.0), 0.09)
		tw.tween_property(upper_jaw, "rotation:x", 0.0, 0.09)
		tw.parallel().tween_property(self, "scale", Vector3.ONE, 0.09)
		await tw.finished
	await get_tree().create_timer(0.3).timeout
	# 4b) la bomba explota... adentro. Se infla un poco.
	Sfx.play("muffled", 0.05)
	get_parent().call("add_shake", 0.5)
	tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.35, 1.45, 1.2), 0.08)
	tw.tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)
	await get_tree().create_timer(0.35).timeout
	# 5) solo sale humo de la boca...
	tw = create_tween()
	tw.tween_property(upper_jaw, "rotation:x", -0.3, 0.15)
	await tw.finished
	Sfx.play("poof", 0.05)
	var fwd := -global_transform.basis.z * -1.0
	B.smoke(get_parent(), mouth_point.global_position, 45, (fwd + Vector3.UP).normalized(),
		Color(0.35, 0.35, 0.37) if not lava else Color(0.2, 0.18, 0.17))
	await get_tree().create_timer(0.7).timeout
	tw = create_tween()
	tw.tween_property(upper_jaw, "rotation:x", 0.0, 0.2)
	await tw.finished
	# 6) ...y se sumerge, satisfecho
	Sfx.play("bubbles", 0.1, -3.0)
	tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position:y", surface - 2.2, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(head, "rotation:x", 0.25, 1.0)
	tw.tween_property(tail, "rotation:y", 0.6, 0.4)
	B.burst(get_parent(), Vector3(base.x, surface, base.z), Color(0.85, 0.95, 1.0, 0.8) if not lava else Color(1, 0.4, 0.05), 14, 1.5, 3.0, 0.09, 1.4, 40.0)
	await tw.finished
	queue_free()
