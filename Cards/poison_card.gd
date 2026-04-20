@tool
extends BaseCard

func on_post_draw():
	Global.change_statistic(Global.Statistic.HEALTH, -1)
	await TweenCan.pulse_tween($CardFront, 1.0).finished
