extends Node2D

func _ready() -> void:
	pass

# Change track between "Forest", "Night", "Lobby", "Industrial". This fades out a track, pauses, then fades into the new track. If the new track is the same as the old track, this does nothing.
func change_track(track: String) -> void:
	pass

# Change intensity of the current track. Value between 0 and 3. This cross-fades between the different intensity versions of the same track, at the same point
func change_intensity(intensity: int) -> void:
	pass