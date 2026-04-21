@tool
extends BaseCard

func _ready():
	super()
	Global.statistic_changed.connect(func(statistic, _new_value, _old_value):
		if statistic == Global.Statistic.FIRE_LIT:
			_sync_front_visuals()
	)

func on_play():
	var table = Global.table
	if Global.is_smoking():
		table.get_encounter_screen().activate_random_encounter()

func is_playable() -> bool:
	if !Global.is_smoking():
		return false
	return super()