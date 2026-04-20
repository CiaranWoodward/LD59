extends Node2D

@export var FADE_TIME := 1.0
@export var PAUSE_TIME := 0.5
@export var MIN_DB := -60.0
@export var MAX_DB := 0.0

var current_track: String = ""
var current_intensity: int = 0
var _tween: Tween

func _ready() -> void:
	for track_node in get_children():
		for player in track_node.get_children():
			if player is AudioStreamPlayer:
				player.volume_db = MIN_DB
	change_track("Forest")
	
	Global.statistic_changed.connect(func(statistic, new_value, _old_value):
		if statistic == Global.Statistic.INSANITY:
			if new_value < 2:
				change_intensity(2)
			elif new_value < 4:
				change_intensity(1)
			else:
				change_intensity(0)
		if statistic == Global.Statistic.ROUND:
			if Global.is_daytime():
				if Global.statistics[Global.Statistic.LEVEL] == 0:
					change_track("Forest")
				elif Global.statistics[Global.Statistic.LEVEL] == 1:
					change_track("Lobby")
				else:
					change_track("Industrial")
			else:
				change_track("Night")
	)

func _get_player(track: String, intensity: int) -> AudioStreamPlayer:
	var track_node := get_node_or_null(track)
	if track_node:
		return track_node.get_node_or_null("Level" + str(intensity))
	return null

# Change track between "Forest", "Night", "Lobby", "Industrial". This fades out a track, pauses, then fades into the new track. If the new track is the same as the old track, this does nothing.
func change_track(track: String) -> void:
	if track == current_track:
		return

	if _tween:
		_tween.kill()
	_tween = create_tween()

	# Fade out old track
	if current_track != "":
		var old_node := get_node(current_track)
		for player in old_node.get_children():
			if player is AudioStreamPlayer:
				_tween.parallel().tween_property(player, "volume_db", MIN_DB, FADE_TIME)
		_tween.tween_callback(func():
			for p in old_node.get_children():
				if p is AudioStreamPlayer:
					p.stop()
		)
		_tween.tween_interval(PAUSE_TIME)

	# Start all levels of new track simultaneously (synced), only active intensity audible
	var new_node := get_node(track)
	_tween.tween_callback(func():
		for player in new_node.get_children():
			if player is AudioStreamPlayer:
				player.volume_db = MIN_DB
				player.play()
	)

	var active_player := _get_player(track, current_intensity)
	if active_player:
		_tween.tween_property(active_player, "volume_db", MAX_DB, FADE_TIME)

	current_track = track

# Change intensity of the current track. Value between 0 and 2. This cross-fades between the different intensity versions of the same track, at the same point
func change_intensity(intensity: int) -> void:
	intensity = clampi(intensity, 0, 2)
	if intensity == current_intensity or current_track == "":
		return

	if _tween:
		_tween.kill()
	_tween = create_tween()

	var old_player := _get_player(current_track, current_intensity)
	var new_player := _get_player(current_track, intensity)

	if old_player:
		_tween.parallel().tween_property(old_player, "volume_db", MIN_DB, FADE_TIME)
	if new_player:
		_tween.parallel().tween_property(new_player, "volume_db", MAX_DB, FADE_TIME)

	current_intensity = intensity