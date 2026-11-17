extends Node
## Prueba automática (solo desarrollo): godot --headless --path . -- --autotest

var main: Node


func _w(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _put(lv, pos: Vector3, vel := Vector3.ZERO) -> void:
	lv.state = 1
	lv.moving_time = 0.0
	lv.still_time = 0.0
	await lv.ball.teleport(pos, vel)


func _p(v: Vector3) -> Vector3:
	return v.snapped(Vector3.ONE * 0.01)


func _wait_aim(lv, t := 12.0) -> void:
	var e := 0.0
	while e < t and lv.state != 0:
		await _w(0.1)
		e += 0.1


func _win(lv) -> void:
	await _wait_aim(lv)
	await _put(lv, lv.hole_pos + lv.up_dir() * 0.8)
	await _w(4.5)
	print("   victoria: estado=%d (3=ganado)" % lv.state)


func _ready() -> void:
	main.show_menu()
	await _w(3.0)
	print("MENU OK")
	main.start_run()
	# ---------- Hoyo 1 ----------
	await _w(5.0)
	var lv = main.current
	print("H1 %s  hoyo=%s" % [lv.info.name, lv.hole_pos])
	for k in 2:
		await _wait_aim(lv)
		await _put(lv, lv.hole_pos + Vector3(0, 0.3, 3.0), Vector3(0, 0, -4))
		await _w(3.5)
		print("   huida %d -> hoyo=%s  tramos construidos, estado=%d" % [k + 1, _p(lv.hole_pos), lv.state])
	# ibis: empujón corto
	await _wait_aim(lv)
	var t0: float = lv.time_left
	await _put(lv, Vector3(-4.5, 0.3, -27.0), Vector3(0, 0, 3))
	await _w(1.5)
	print("   ibis: pos=%s  tiempo %.1f -> %.1f (no debe bajar por el ibis)" % [_p(lv.ball.global_position), t0, lv.time_left])
	# iguana: bomba quieta en su radio
	await _wait_aim(lv)
	lv.state = 0
	await lv.ball.teleport(Vector3(2.0, 0.3, -42.0))
	lv.state = 0
	var c0: int = Game.stats.iguanas
	await _w(7.5)
	print("   iguana: atrapadas %d -> %d" % [c0, Game.stats.iguanas])
	lv.time_left = 50.0
	await _win(lv)
	lv.next_level()
	# ---------- Hoyo 2 ----------
	await _w(5.2)
	lv = main.current
	print("H2 %s" % lv.info.name)
	await _put(lv, Vector3(-1.5, 0.3, -4.5))
	var d0: float = lv.ball.global_position.distance_to(Vector3(-4.3, 0.3, -4.5))
	await _w(0.6)
	print("   cangrejo rojo: distancia %.2f -> %.2f en 0.6 s" % [d0, lv.ball.global_position.distance_to(Vector3(-4.3, 0.3, -4.5))])
	await _w(1.0)
	await _wait_aim(lv)
	lv.state = 0
	await lv.ball.teleport(Vector3(1.8, 0.3, -20.0))
	lv.state = 0
	var b0: int = Game.stats.bees
	await _w(6.0)
	print("   abejas: atrapadas %d -> %d" % [b0, Game.stats.bees])
	await _win(lv)
	lv.next_level()
	# ---------- Hoyo 3 ----------
	await _w(5.2)
	lv = main.current
	print("H3 %s" % lv.info.name)
	await _w(4.0)
	print("   en la luz del hongo (salida): oscuridad=%.1f" % lv.custom.dark_t)
	await _put(lv, Vector3(-2.0, 0.3, -9.5))
	var bt0: int = Game.stats.bats
	await _w(14.0)
	print("   murciélagos: atrapadas %d -> %d" % [bt0, Game.stats.bats])
	await _wait_aim(lv)
	await _put(lv, Vector3(0, 0.25, -4), Vector3(0, 0, -7))
	await _w(3.0)
	print("   gravedad invertida=%s" % lv.flipped)
	lv.set_flip(false, true)
	await _win(lv)
	lv.next_level()
	# ---------- Hoyo 4 ----------
	await _w(5.2)
	lv = main.current
	print("H4 %s" % lv.info.name)
	await _put(lv, Vector3(0, 0.3, -24.0))
	await _w(4.5)
	print("   ráfaga del águila: pos x=%.2f (empujada si > 0)" % lv.ball.global_position.x)
	await _wait_aim(lv)
	await _put(lv, Vector3(2.0, 1.5, -10.0))
	await _w(5.0)
	print("   agua del manglar: cocodrilos=%d" % Game.stats.crocs)
	await _wait_aim(lv)
	lv.state = 0
	await lv.ball.teleport(Vector3(3.3, 0.3, -20.0))
	lv.state = 0
	var e0: int = Game.stats.eagles
	await _w(14.0)
	print("   águila en picada: atrapadas %d -> %d" % [e0, Game.stats.eagles])
	await _win(lv)
	lv.next_level()
	await _w(3.0)
	print("TARJETA estrellas=%s escena=%s" % [Game.run_stars, main.current.get_script().resource_path])
	print("AUTOTEST TERMINADO")
	get_tree().quit()
