@tool
extends BaseCard

func on_play():
	Global.set_statistic_max(Global.Statistic.ACTION_POINTS, Global.statistics[Global.Statistic.ACTION_POINTS] + 1)
