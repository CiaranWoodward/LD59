extends BaseCard

func on_pre_discard():
	Global.change_statistic(Global.Statistic.INSANITY, -1)
	await TweenCan.pulse_tween($CardFront, 1.0).finished
	_do_burn()