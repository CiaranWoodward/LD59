extends Node2D

@export var pip_type: Global.Statistic = Global.Statistic.HEALTH
@export var pip_threshold: int = 1
@export var pip_inital_delay_multiplier: float = 0.4
@export var pip_turn_off_delay_multiplier: float = 0

@onready var animationTree = $States/AnimationTree["parameters/playback"] as AnimationNodeStateMachinePlayback

var _turned_on: bool = false

func _ready() -> void:
	# Initial state
	animationTree.start("Start")
	self.visible = Global.max_statistic_values[pip_type] >= pip_threshold
	if Global.statistics[pip_type] >= pip_threshold:
		await get_tree().create_timer(pip_inital_delay_multiplier * pip_threshold).timeout
		_turn_on()
	# Listener for future changes
	Global.statistic_changed.connect(func(stat, new_value, _old_value):
		if stat == pip_type:
			self.visible = Global.max_statistic_values[pip_type] >= pip_threshold
			if new_value >= pip_threshold and not _turned_on:
				_turn_on()
			elif new_value < pip_threshold and _turned_on:
				if pip_turn_off_delay_multiplier > 0:
					await get_tree().create_timer(pip_turn_off_delay_multiplier * pip_threshold).timeout
				_turn_off()
	)


func _turn_on():
	_turned_on = true
	animationTree.travel("Filling")

func _turn_off():
	_turned_on = false
	animationTree.travel("Emptying")
