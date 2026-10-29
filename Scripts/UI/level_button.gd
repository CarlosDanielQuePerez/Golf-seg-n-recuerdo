extends HBoxContainer
# Fila del menú principal: botón del nivel + mejores estrellas.

@onready var button: Button = $Button
@onready var star_icons: Array[Node] = $Stars.get_children()


func setup(level_id: int) -> void:
	var unlocked := GameManager.is_unlocked(level_id)
	var title := GameManager.level_title(level_id)
	button.text = title if unlocked else title + "  (bloqueado)"
	button.disabled = not unlocked
	var best := GameManager.get_best_stars(level_id)
	for i in star_icons.size():
		star_icons[i].filled = i < best
	button.pressed.connect(GameManager.go_to_level.bind(level_id))
	GameManager.add_click_sound(button)
