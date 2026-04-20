extends Node2D

enum Direction {
	BECOMING_INSANE,
	BECOMING_SANE,
}

## The node to make visible when sane
@export var sane_node: NodePath = ^"Sane"
## The node to make visible when insane
@export var insane_node: NodePath = ^"Insane"
## The node to change color
@export var modulate_node: NodePath
## The color to modulate the modulate_node with when sane
@export var sane_color: Color = Color(0.8, 0.8, 0.8)
## The color to modulate the modulate_node with when insane
@export var insane_color: Color = Color(1, 1, 1)

## Insanity level at which the flicker effect will always be sane (and not flicker)
@export var always_sane_threshold: int = 0
## Insanity level at which the flicker effect will always be insane (and not flicker)
@export var always_insane_threshold: int = 5
## Chance that the flicker effect will occur when insanity changes in the relevant direction
@export var chance_to_flicker: float = 0.2
## Chance that the flicker effect will end in the new state instead of reverting to the old state (regardless of threshold)
@export var chance_to_stick_early: float = 0.2
## Time it takes to complete the flicker effect (on and off cycles)
@export var flicker_time: float = 2.0
## Time after the flicker finishes during which the sprite will remain visible
@export var post_flicker_visible_time: float = 0.5
## Random delay before the flicker starts
@export var random_delay_max: float = 0.5

var _sane_node: Node2D
var _insane_node: Node2D
var _modulate_node: Node2D
var _currently_insane: bool = true

func _ready() -> void:
	_sane_node = get_node_or_null(sane_node)
	_insane_node = get_node_or_null(insane_node)
	_modulate_node = get_node_or_null(modulate_node)
	# Initial state
	var current_insanity = Global.statistics[Global.Statistic.INSANITY]
	if current_insanity >= always_insane_threshold:
		set_sane_visible(false, true)
	elif current_insanity <= always_sane_threshold:
		set_sane_visible(true, true)
	else:
		set_sane_visible(randi_range(always_sane_threshold, always_insane_threshold) >= current_insanity, true)
	# Listener for future changes
	Global.statistic_changed.connect(func (stat: int, new_value: int, old_value: int):
		if stat == Global.Statistic.INSANITY:
			var is_becoming_insane := new_value > old_value
			var is_becoming_sane := new_value < old_value
			var should_be_on := (is_becoming_insane and new_value >= always_insane_threshold) or (is_becoming_sane and new_value <= always_sane_threshold)
			var maybe_on = ((is_becoming_insane && !_currently_insane) or (is_becoming_sane && _currently_insane)) and (randf() < chance_to_flicker)
			if maybe_on or should_be_on:
				start_flicker(Direction.BECOMING_INSANE if is_becoming_insane else Direction.BECOMING_SANE)
	)

func start_flicker(direction: Direction) -> void:
	await get_tree().create_timer(randf_range(0.0, random_delay_max)).timeout
	var flicker_tween := TweenCan.flicker_fn_tween(
		func ():
			if direction == Direction.BECOMING_INSANE:
				set_sane_visible(false)
			else:
				set_sane_visible(true),
		func ():
			if direction == Direction.BECOMING_INSANE:
				set_sane_visible(true)
			else:
				set_sane_visible(false),
		flicker_time
	)
	flicker_tween.tween_interval(post_flicker_visible_time)
	flicker_tween.tween_callback(func ():
		if direction == Direction.BECOMING_INSANE:
			var on = Global.statistics[Global.Statistic.INSANITY] >= always_insane_threshold
			on = on or (randf() < chance_to_stick_early and Global.statistics[Global.Statistic.INSANITY] > always_sane_threshold)
			set_sane_visible(not on, on)
		else:
			var on = Global.statistics[Global.Statistic.INSANITY] <= always_sane_threshold
			on = on or (randf() < chance_to_stick_early and Global.statistics[Global.Statistic.INSANITY] < always_insane_threshold)
			set_sane_visible(on, on)

	)
	await flicker_tween.finished
 
func set_sane_visible(is_sane_visible: bool, permanent: bool = false) -> void:
	if permanent:
		_currently_insane = not is_sane_visible
	if _sane_node:
		_sane_node.visible = is_sane_visible
	if _insane_node:
		_insane_node.visible = not is_sane_visible
	if _modulate_node:
		_modulate_node.self_modulate = sane_color if is_sane_visible else insane_color
