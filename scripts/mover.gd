extends AnimatableBody3D
## Obstáculo móvil genérico: gira (aspas, barras) o se desliza (plataformas, troncos).

var mode := "spin"           # "spin" | "slide"
var axis := Vector3.UP
var speed := 1.5             # rad/s para spin
var offset := Vector3(4, 0, 0)
var period := 4.0            # segundos de ida y vuelta para slide
var phase := 0.0
var vel := Vector3.ZERO      # velocidad actual (para saber si la pelota va "parada" encima)
var _origin: Transform3D
var _t := 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = transform
	_t = phase
	set_meta("moving", true)


func _physics_process(delta: float) -> void:
	_t += delta
	if mode == "spin":
		transform = _origin * Transform3D(Basis(axis.normalized(), _t * speed), Vector3.ZERO)
		vel = Vector3.ZERO
	else:
		var prev := position
		var k := (sin(_t / period * TAU) + 1.0) * 0.5
		position = _origin.origin + offset * (k - 0.5) * 2.0
		vel = (position - prev) / maxf(delta, 0.0001)
