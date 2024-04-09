extends ColorRect

const PLAYER_DIED = "player_died"

@onready var player = $"../../Player"

func _ready():
	hide()
	player.connect(PLAYER_DIED, Callable(self, "_on_player_death"))

func _on_player_death():
	show()

func _unhandled_input(event):
	if not visible:
		return

	if not event.is_action_released("ui_accept"):
		return

	get_tree().reload_current_scene()
