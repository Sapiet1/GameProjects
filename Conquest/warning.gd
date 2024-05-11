extends Window

@onready var text = $Contents/Background/Container/Text

func _on_close_requested():
	visible = false

func popup_message(message):
	text.text = message
	popup()
