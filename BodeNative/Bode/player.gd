extends CharacterBody3D

const JUMP_IMPULSE = 20
const SPEED = 14
const ROTATION_SPEED = 1.0
const FALL_HEIGHT = -10
const FALL_TIMER = 3.5
const BLOCKS_SCENE_NAME = "block"
const BLOCKS_HEIGHT = 30
const MOVING_ANIMATION_SPEED = 3
const MOB_CLASS_NAME = "Mob"

var target_velocity = Vector3.ZERO
var target_rotation = Quaternion.IDENTITY
var score = 0
var off_screen_at = null
var nearby_blocks = {}
var type = "Player"

@onready var pivot = $Pivot
@onready var camera_pivot = $CameraPivot
@onready var blocks = $Blocks
@onready var animation = $AnimationPlayer

func block_is_nearby():
	return !nearby_blocks.is_empty()

signal score_changed
signal player_died

func kill():
	player_died.emit()
	
func handle_input(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1

	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		
	if direction != Vector3.ZERO and is_on_floor():
		animation.speed_scale = MOVING_ANIMATION_SPEED
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		direction = camera_pivot.basis * direction
		pivot.basis = Basis.looking_at(direction)
		target_rotation = Basis.looking_at(direction).get_rotation_quaternion()
	else:
		animation.speed_scale = 1

	pivot.rotation.x = PI / 6 * velocity.y / JUMP_IMPULSE

	target_velocity.x = direction.x * SPEED
	target_velocity.z = direction.z * SPEED
		
	if !block_is_nearby() && Input.is_action_just_pressed("action"):
		var block = blocks.get_resource(BLOCKS_SCENE_NAME).instantiate()
		block.position = position
		block.position.y = BLOCKS_HEIGHT
		block.initialize(self)
		get_tree().current_scene.add_child(block)
	elif block_is_nearby() && is_on_floor():
		target_velocity.y = JUMP_IMPULSE if Input.is_action_just_pressed("action") else 0

	camera_pivot.rotation = Quaternion.from_euler(camera_pivot.rotation).slerp(target_rotation, ROTATION_SPEED * delta).get_euler()
	velocity = target_velocity
	move_and_slide()

func handle_collisions():
	for index in get_slide_collision_count():
		var collision = get_slide_collision(index)
		var mob = collision.get_collider()
		
		if not mob.is_class("CharacterBody3D"):
			continue
		if not mob.type == MOB_CLASS_NAME:
			continue

		if Vector3.UP.dot(collision.get_normal()) > 0.25:
			mob.kill(self)
			target_velocity.y = JUMP_IMPULSE
		else:
			kill()

		break

func _physics_process(delta):
	if !is_on_floor():
		target_velocity.y = target_velocity.y - Global.fall_acceleration * delta
	
	if off_screen_at:
		move_and_slide()
	else:
		handle_input(delta)
		handle_collisions()

func _process(_delta):
	if off_screen_at:
		camera_pivot.global_position = off_screen_at
		return

	if global_position.y < FALL_HEIGHT:
		off_screen_at = camera_pivot.global_position
		await get_tree().create_timer(FALL_TIMER).timeout
		kill()

