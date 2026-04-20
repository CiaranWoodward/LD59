@tool
extends BaseCard

func on_play():
	Global.change_statistic(Global.Statistic.FIRE_SIZE, 3)
