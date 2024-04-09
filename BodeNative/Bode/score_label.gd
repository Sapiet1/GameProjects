extends Label

const SCORE_CHANGED = "score_changed"

@onready var player = $"../../Player"

func _ready():
	player.connect(SCORE_CHANGED, Callable(self, "_on_score_changed"))

func _on_score_changed():
	text = "Score: {score}".format({"score": player.score})
