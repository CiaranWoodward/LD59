extends Node2D

@export var pip_type: Global.Statistic = Global.Statistic.HEALTH
@export var pip_threshold: int = 1
@export var pip_inital_delay_multiplier: float = 0.4

@onready var animationTree = $States/AnimationTree["parameters/playback"] as AnimationNodeStateMachinePlayback

func _ready() -> void:
    # Initial state
    animationTree.start("Start")
    if Global.statistics[pip_type] >= pip_threshold:
        await get_tree().create_timer(pip_inital_delay_multiplier * pip_threshold).timeout
        _turn_on()
    # Listener for future changes
    Global.statistic_changed.connect(func(stat, new_value, _old_value):
        if stat == pip_type:
            if new_value >= pip_threshold and _old_value < pip_threshold:
                _turn_on()
            elif new_value < pip_threshold and _old_value >= pip_threshold:
                _turn_off()
    )


func _turn_on():
    animationTree.travel("Filling")

func _turn_off():
    animationTree.travel("Emptying")
