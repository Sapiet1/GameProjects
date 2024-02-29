extends Area2D

var FRAMES = 11
var FPS = 12
var DURATION = FRAMES / FPS
var DAMAGE = 20

func _ready():
	await get_tree().create_timer(DURATION).timeout
	queue_free()

func _on_area_entered(area):
	if area.name == "GoblinHitbox":
		var goblin: Goblin = area.get_parent()
		goblin.health -= DAMAGE
		
		if goblin.get_health() <= 0:
			goblin.sprite.process_mode = Node.PROCESS_MODE_PAUSABLE
			goblin.process_mode = Node.PROCESS_MODE_DISABLED
			goblin.sprite.animation = "Die"
			goblin.sprite.play()

		queue_free()
