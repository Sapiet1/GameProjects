extends Coin

signal collect(coin)

func _on_body_entered(body):
	if body.name == "Player":
		var body_position = body.get_position()
		body.set_spawn_location(body_position)
		
		if not collected:
			body.air_jumps += 1
			collected = true
