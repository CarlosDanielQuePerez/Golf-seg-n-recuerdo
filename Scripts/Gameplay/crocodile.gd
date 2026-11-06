class_name Crocodile
extends Node2D
## Secuencia animada del cocodrilo cuando la bomba cae al agua:
## 1. Emerge del agua (splash)
## 2. Abre sus fauces y se traga la bomba (chomp)
## 3. Disfruta un instante y luego entra en pánico al notar que era una bomba
## 4. Se infla y la bomba explota dentro de él
## 5. Queda aturdido (chamuscado con ojos en X) y se hunde sacando burbujas

signal finished

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var splash_sound: AudioStreamPlayer = $SplashSound
@onready var chomp_sound: AudioStreamPlayer = $ChompSound
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var glug_sound: AudioStreamPlayer = $GlugSound

var _target_bomb: Node2D = null


func start_sequence(target_bomb: Node2D) -> void:
	_target_bomb = target_bomb
	if _target_bomb:
		if _target_bomb.has_method("stop"):
			_target_bomb.stop()
		_target_bomb.set_physics_process(false)
		if "collision_layer" in _target_bomb:
			_target_bomb.collision_layer = 0
		if "collision_mask" in _target_bomb:
			_target_bomb.collision_mask = 0
	
	animation_player.play("eat_and_explode")
	await animation_player.animation_finished
	finished.emit()


func hide_bomb() -> void:
	if _target_bomb:
		_target_bomb.visible = false


func play_splash() -> void:
	splash_sound.play()


func play_chomp() -> void:
	chomp_sound.play()
	hide_bomb()


func play_explosion() -> void:
	explosion_sound.play()


func play_glug() -> void:
	glug_sound.play()
