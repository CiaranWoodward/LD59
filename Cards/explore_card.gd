@tool
extends BaseCard

func _ready():
	super()
	Global.statistic_changed.connect(func(statistic, _new_value, _old_value):
		if statistic == Global.Statistic.PATHFINDING:
			_sync_front_visuals()
	)

func is_playable() -> bool:
	if !(Global.statistics[Global.Statistic.PATHFINDING] < Global.max_statistic_values[Global.Statistic.PATHFINDING]):
		return false
	return super()

func on_play():
	Global.change_statistic(Global.Statistic.PATHFINDING, 1)

	if !Global.is_insane():
		Global.change_statistic(Global.Statistic.HEALTH, -1)