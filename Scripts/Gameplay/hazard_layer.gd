class_name HazardLayer
extends TileMapLayer
# Capa de tiles que avisa cuando la bomba entra o sale (arena, agua...).
# Se pinta como cualquier TileMapLayer; al iniciar el nivel se crea un Area2D
# con un rectángulo por cada celda pintada y se emiten estas señales.

signal bomb_entered(bomb: Bomb)
signal bomb_exited(bomb: Bomb)

const BOMB_PHYSICS_LAYER := 2   # capa de física "Bomba" (ver Project Settings > Layer Names)

@export var shape_margin := 0.0   # encoge cada celda (px) para que la bomba tenga que entrar más


func _ready() -> void:
	var area := Area2D.new()
	area.name = "Zone"
	area.collision_layer = 0
	area.collision_mask = BOMB_PHYSICS_LAYER
	area.monitorable = false
	var cell_size := Vector2(tile_set.tile_size) - Vector2.ONE * shape_margin * 2.0
	for cell in get_used_cells():
		var rect := RectangleShape2D.new()
		rect.size = cell_size
		var shape := CollisionShape2D.new()
		shape.shape = rect
		shape.position = map_to_local(cell)
		area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Bomb:
		bomb_entered.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body is Bomb:
		bomb_exited.emit(body)
