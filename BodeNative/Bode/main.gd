extends Node3D

const MOB_SCENE_NAME = "mob"

@onready var mobs = $Mobs
@onready var mob_timer = $MobTimer
@onready var spawn_location = $"SpawnPath/SpawnLocation"
@onready var player = $Player

func _ready():
	mob_timer.connect("timeout", Callable(self, "_on_mobs_timeout"))

func _on_mobs_timeout():
	spawn_location.progress_ratio = randf()
	var mob = mobs.get_resource(MOB_SCENE_NAME).instantiate()
	mob.initialize(spawn_location.position, player)
	add_child(mob)
