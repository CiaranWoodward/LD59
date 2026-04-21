@tool
extends BaseCard

func _ready():
	super()
	Global.statistic_changed.connect(func(statistic, _new_value, _old_value):
		if statistic == Global.Statistic.FIRE_SIZE || statistic == Global.Statistic.FIRE_LIT:
			maybe_burn()
	)

func maybe_burn():
	if Global.is_smoking() && _in_hand:
		Global.table.burn_card(self)

func on_post_draw():
	maybe_burn()

func on_pre_discard():
	Global.change_statistic(Global.Statistic.INSANITY, -1)
	Global.change_statistic(Global.Statistic.HEALTH, -1)
	await TweenCan.pulse_tween($CardFront, 1.0).finished
	_do_burn()
