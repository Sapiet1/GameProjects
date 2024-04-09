extends RigidBody3D

const PLAYER_CLASS_NAME = "Player"
const MOB_CLASS_NAME = "Mob"

var player = null
var block_id: int = new_id()

@onready var despawn_area = $Despawn

func new_id():
	var temporary = Global.id
	Global.id += 1
	return temporary

func initialize(_player):
	player = _player

func _ready():
	despawn_area.connect("body_entered", Callable(self, "_on_despawn_body_entered"))
	despawn_area.connect("body_exited", Callable(self, "_on_despawn_body_exited"))
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_despawn_body_entered(body):
	if body.is_class("CharacterBody3D") and body.type == PLAYER_CLASS_NAME:
		body.nearby_blocks[block_id] = null

func _on_despawn_body_exited(body):
	if body.is_class("CharacterBody3D") and body.type == PLAYER_CLASS_NAME:
		body.nearby_blocks.erase(block_id)
		queue_free()

func _on_body_entered(body):
	if body.is_class("CharacterBody3D") and body.type == PLAYER_CLASS_NAME:
		body.kill()
	elif body.is_class("CharacterBody3D") and body.type == MOB_CLASS_NAME:
		body.kill(player)

