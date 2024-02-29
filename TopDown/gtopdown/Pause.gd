extends Node

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		var process_mode = get_tree().current_scene.process_mode
		if process_mode == Node.PROCESS_MODE_INHERIT:
			get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		elif process_mode == Node.PROCESS_MODE_DISABLED:
			get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT
