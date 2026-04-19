@tool
extends AnimatedSprite2D

@export var self_modulations: Array[Color] = []
@export var should_flip: bool = true
@export var scale_for_distance: = false
@export var max_distance_scale: Vector2 = Vector2.ONE * 0.4
@export var min_distance_y: int = 700
@export var max_distance_y: int = 300
@export var colour_for_distance: = false
@export var min_distance_modulation: Color = Color.WHITE
@export var max_distance_modulation: Color = Color.GRAY
@export var play_on_load: = false
@export var min_speed: float = 0.9
@export var max_speed: float = 1.1

func _ready():
	frame = randi_range(0, sprite_frames.get_frame_count("default") - 1)
	if self_modulations.size() > 0:
		self_modulate = self_modulations[randi_range(0,self_modulations.size() - 1)]
	if should_flip:
		flip_h = (randi() % 2) == 1
	if scale_for_distance:
		var weight = (self.global_position.y - max_distance_y) / (min_distance_y - max_distance_y)
		weight = clamp(weight, 0, 1)
		self.scale = lerp(max_distance_scale, Vector2.ONE, weight)
	if colour_for_distance:
		var weight = (self.global_position.y - max_distance_y) / (min_distance_y - max_distance_y)
		weight = clamp(weight, 0, 1)
		modulate = lerp(max_distance_modulation, min_distance_modulation, weight)
	if play_on_load:
		speed_scale = randf_range(min_speed, max_speed)
