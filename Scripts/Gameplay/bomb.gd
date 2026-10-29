class_name Bomb
extends CharacterBody2D
# La bomba (la "pelota"). Se mueve con su propia física; el nivel decide si gana o pierde.
# Arte: pon la textura en $Sprite y oculta $Body (círculo de placeholder).
# Sonido: arrastra los audios a BounceSound, ExplosionSound y SplashSound (ya conectados por señales).
# Animación: "explode" en $AnimationPlayer se reproduce al explotar.

signal bounced               # chocó contra una pared
signal splashed              # tocó el agua (justo antes de explotar)
signal exploded              # empieza la explosión
signal explosion_finished    # terminó la animación de explosión

@export var friction := 0.4          # velocidad que conserva por segundo (menor = frena más)
@export var sand_friction := 0.05    # lo mismo pero dentro de la arena
@export var bounce_damping := 0.8    # velocidad que conserva al rebotar
@export var stop_speed := 10.0       # por debajo de esta velocidad se detiene

var is_exploded := false
var _sand_zones := 0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func is_moving() -> bool:
	return velocity != Vector2.ZERO


func shoot(impulse: Vector2) -> void:
	velocity = impulse


func stop() -> void:
	velocity = Vector2.ZERO


func enter_sand() -> void:
	_sand_zones += 1


func exit_sand() -> void:
	_sand_zones = maxi(_sand_zones - 1, 0)


func explode(in_water := false) -> void:
	if is_exploded:
		return
	is_exploded = true
	stop()
	if in_water:
		splashed.emit()
	exploded.emit()
	if animation_player.has_animation("explode"):
		animation_player.play("explode")
		await animation_player.animation_finished
	explosion_finished.emit()


func _physics_process(delta: float) -> void:
	if is_exploded or velocity == Vector2.ZERO:
		return
	var hit := move_and_collide(velocity * delta)
	if hit:
		velocity = velocity.bounce(hit.get_normal()) * bounce_damping
		bounced.emit()
	velocity *= pow(sand_friction if _sand_zones > 0 else friction, delta)
	if velocity.length() < stop_speed:
		velocity = Vector2.ZERO
