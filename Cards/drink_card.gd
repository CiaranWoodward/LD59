@tool
extends BaseCard

func on_play():
	var table = Global.table
	if Global.is_insane():
		Global.change_statistic(Global.Statistic.HEALTH, 1)
		Global.change_statistic(Global.Statistic.INSANITY, -1)

	else:
		Global.change_statistic(Global.Statistic.HEALTH, -1)
		Global.table.draw_cards();
