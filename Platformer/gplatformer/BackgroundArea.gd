extends Area2D

func _on_body_exited(body):
	if body.name == "Player":
		body.respawn()
