@tool
extends BaseCard

func _ready():
	super()
	Global.statistic_changed.connect(func(statistic, _new_value, _old_value):
		if statistic == Global.Statistic.FIRE_SIZE:
			_sync_front_visuals()
	)

func on_play():
	Global.change_statistic(Global.Statistic.FIRE_SIZE, 3)

func is_playable() -> bool:
	if !(Global.statistics[Global.Statistic.FIRE_SIZE] < Global.max_statistic_values[Global.Statistic.FIRE_SIZE]):
		return false
	return super()