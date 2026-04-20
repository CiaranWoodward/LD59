@tool
extends BaseCard

func on_play():
	Global.change_statistic(Global.Statistic.PATHFINDING, 1)

	if !Global.is_insane():
		Global.change_statistic(Global.Statistic.HEALTH, -1)
