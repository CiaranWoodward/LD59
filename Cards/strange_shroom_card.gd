@tool
extends BaseCard

func on_play():
	Global.change_statistic(Global.Statistic.INSANITY, 2)
