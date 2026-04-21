extends Node2D

func _ready():
	_update_visuals()
	Global.statistic_changed.connect(func(stat, _new_value, _old_value):
		if stat == Global.Statistic.FIRE_SIZE or stat == Global.Statistic.FIRE_LIT:
			_update_visuals()
	)
	Global.travel_requested.connect(func():
		$Ash.visible = false
	)

func _update_visuals():
	var fire_size = Global.statistics[Global.Statistic.FIRE_SIZE]
	var fire_lit = Global.statistics[Global.Statistic.FIRE_LIT]

	if fire_size <= 0:
		$Logs.visible = false
	else:
		$Logs.visible = true
		$Logs.frame = fire_size-1

	if fire_lit > 0:
		$FireCrackle.play()
		$Sparks.visible = true
		$Ash.visible = true
		$SmallFire.visible = fire_size > 0
		$MidFire.visible = fire_size > 1
		$BigFire.visible = fire_size > 2
		$Smoke.visible = Global.is_smoking()
	else:
		$FireCrackle.stop()
		$Sparks.visible = false
		$SmallFire.visible = false
		$MidFire.visible = false
		$BigFire.visible = false
		$Smoke.visible = false
