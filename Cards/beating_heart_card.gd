@tool
extends BaseCard

func on_play():
	Global.set_statistic_max(Global.Statistic.HEALTH, Global.statistics[Global.Statistic.HEALTH] + 1)
	Global.change_statistic(Global.Statistic.HEALTH, -1)
