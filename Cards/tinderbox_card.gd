
@tool
extends BaseCard

func _ready():
	super()
	Global.statistic_changed.connect(func(statistic, _new_value, _old_value):
		if statistic == Global.Statistic.FIRE_LIT:
			_sync_front_visuals()
	)

func on_play():
	Global.change_statistic(Global.Statistic.FIRE_LIT, 1)

func is_playable() -> bool:
	if !(Global.statistics[Global.Statistic.FIRE_LIT] < Global.max_statistic_values[Global.Statistic.FIRE_LIT]):
		return false
	return super()