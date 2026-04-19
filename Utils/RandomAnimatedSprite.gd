extends AnimatedSprite2D

@export var self_modulations: Array[Color] = []
@export var should_flip: bool = true

func _ready():
	frame = randi_range(0, sprite_frames.get_frame_count("default") - 1)
	if should_flip:
		flip_h = (randi() % 2) == 1
	if self_modulations.size() > 0:
		self_modulate = self_modulations[randi_range(0,self_modulations.size() - 1)]
