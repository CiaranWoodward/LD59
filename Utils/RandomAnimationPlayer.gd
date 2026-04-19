@tool
extends AnimationPlayer

@export var random_speed: = false
@export var min_speed: float = 1
@export var max_speed: float = 2

func _ready():
	if random_speed:
		speed_scale = randf_range(min_speed, max_speed)
