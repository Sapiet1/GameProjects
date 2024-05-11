extends Control

@onready var list = $Background/Container/List

func change_list(names):
	list.text = ""
	
	for name in names:
		list.text += name
		list.text += "\n"
