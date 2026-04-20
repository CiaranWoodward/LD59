@tool
extends BaseCard

func on_post_draw():
	Global.change_statistic(Global.Statistic.ACTION_POINTS, -1)
	await TweenCan.pulse_tween($CardFront, 1.0).finished

func on_pre_burn():
	if _in_hand:
		Global.change_statistic(Global.Statistic.ACTION_POINTS, 1)
		await TweenCan.pulse_tween($CardFront, 1.0).finished
