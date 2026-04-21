extends AudioStreamPlayer2D

@export var min_pitch: float = 0.8
@export var max_pitch: float = 1.2

func play_rand():
	self.pitch_scale = randf_range(min_pitch, max_pitch)
	self.play()
