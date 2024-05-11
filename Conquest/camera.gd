extends CharacterBody2D

var SPEED = 1
var TARGET_DISTANCE = 150

var LIMIT_LEFT = 0
var LIMIT_TOP = 0
var LIMIT_RIGHT = 16 * 200
var LIMIT_BOTTOM = 16 * 200

@onready var zoom = $Eye.zoom


func normalize_position():
	var viewport = get_viewport()
	var offset_x = viewport.size.x / 2
	var offset_y = viewport.size.y / 2
	
	var camera_offset_x = offset_x / zoom.x
	var camera_offset_y = offset_y / zoom.y
	
	if position.x < LIMIT_LEFT + camera_offset_x:
		position.x = LIMIT_LEFT + camera_offset_x
	elif position.x > LIMIT_RIGHT - camera_offset_x:
		position.x = LIMIT_RIGHT - camera_offset_x
	if position.y < LIMIT_TOP + camera_offset_y:
		position.y = LIMIT_TOP + camera_offset_y
	elif position.y > LIMIT_BOTTOM - camera_offset_y:
		position.y = LIMIT_BOTTOM - camera_offset_y

func _physics_process(_delta):
	var viewport = get_viewport()
	var offset_x = viewport.size.x / 2
	var offset_y = viewport.size.y / 2
	
	var target = viewport.get_mouse_position()
	target.x -= offset_x
	target.y -= offset_y
	
	var movable = target.length() > TARGET_DISTANCE and -offset_x <= target.x and target.x < offset_x and -offset_y <= target.y and target.y < offset_y
	if not movable:
		return
	
	velocity = target * SPEED
	move_and_slide()
	
	normalize_position()
