extends CharacterBody3D

const MIN_SPEED = 12
const MAX_SPEED = 20
const MOVING_ANIMATION_SPEED = 2

var target_velocity = Vector3.ZERO
var visibility_notifier = null
var animation = null
var type = "Mob"

func initialize(start_position, player):
	visibility_notifier = $VisibilityNotifier
	animation = $AnimationPlayer
	
	var player_position = player.position
	player_position.y = 0
	look_at_from_position(start_position, player_position, Vector3.UP)
	
	var random_angle = randf_range(-PI / 4, PI / 4)
	rotate_y(random_angle)
	
	var random_speed = randf_range(MIN_SPEED, MAX_SPEED)
	animation.speed_scale = random_speed / MAX_SPEED * MOVING_ANIMATION_SPEED

	target_velocity = Vector3.FORWARD * random_speed
	target_velocity = target_velocity.rotated(Vector3.UP, rotation.y)

func kill(player = null):
	queue_free()


	if player:
		player.score += 1
		player.score_changed.emit()

func _ready():
	visibility_notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

func _on_screen_exited():
	kill()

func _physics_process(delta):
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (Global.fall_acceleration * delta)

	velocity = target_velocity
	move_and_slide()
