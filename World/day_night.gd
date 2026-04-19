extends AnimationPlayer

func _ready() -> void:
	self.play("DayNightCycle")
	self.pause()
	self.seek(0, true)
	self.get_animation("DayNightCycle").loop_mode = Animation.LOOP_NONE
	self._play_until_current()
	Global.statistic_changed.connect(func(stat, _new_value, _old_value):
		if stat == Global.Statistic.ROUND:
			_play_until_current())

# See markers on animation to see how it is split up
func _play_until_current() -> void:
	var target_time = _get_target_time_in_day_night_cycle()
	var diff = _get_diff_to_target_time(target_time)
	if diff < 0:
		# Just seek, probably an error
		self.seek(target_time, true)
	else:
		self.play("DayNightCycle", -1, 1.0, false)
		# Wait until we reach the target time, then pause
		var timer = get_tree().create_timer(diff / self.speed_scale)
		print("Playing day/night cycle for " + str(diff) + " seconds until we reach target time of " + str(target_time))
		await timer.timeout
		self.pause()
		self.seek(target_time, true)

func _get_target_time_in_day_night_cycle() -> float:
	var round_no = Global.statistics[Global.Statistic.ROUND]
	var max_round = Global.max_statistic_values[Global.Statistic.ROUND]
	var half_day = max_round / 2.0
	var is_daytime = Global.is_daytime()
	if !is_daytime:
		round_no -= half_day
	var time_into_cycle = (round_no / half_day) * 0.6

	if is_daytime:
		return 0.2 + time_into_cycle
	else:
		return 1.2 + time_into_cycle

func _get_diff_to_target_time(target_time: float) -> float:
	# include looping around the animation
	var current_time = self.current_animation_position
	var diff = target_time - current_time
	if diff < -0.1:
		diff += self.current_animation_length
		self.get_animation("DayNightCycle").loop_mode = Animation.LOOP_LINEAR
	else:
		self.get_animation("DayNightCycle").loop_mode = Animation.LOOP_NONE
	return diff
