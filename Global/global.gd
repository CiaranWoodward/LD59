extends Node

var table: Table
var level: Level

enum Statistic {
	HEALTH,
	INSANITY,
	ACTION_POINTS,
	HAND_SIZE,
	FIRE_SIZE,
	FIRE_LIT,
	DAY,
	ROUND,
	PATHFINDING,
	LEVEL,
	HANDS_PLAYED,
}

var StatisticNames = {
	Statistic.HEALTH: "Health",
	Statistic.INSANITY: "???",
	Statistic.ACTION_POINTS: "Energy",
	Statistic.HAND_SIZE: "Hand Size",
	Statistic.FIRE_SIZE: "Fire Size",
	Statistic.FIRE_LIT: "Fire Lit",
	Statistic.DAY: "Day",
	Statistic.ROUND: "Round",
	Statistic.PATHFINDING: "Pathfinding",
	Statistic.LEVEL: "Level",
	Statistic.HANDS_PLAYED: "Hands Played",
}

enum TurnEndImpact {
	NORMAL,
	NIGHT_FALLS,
	NEW_DAY,
}

enum SceneType {
	ANY,
	FOREST,
	RIVER,
}

var initial_statistic_values = {
	Statistic.HEALTH: 5,
	Statistic.INSANITY: 5,
	Statistic.ACTION_POINTS: 3,
	Statistic.HAND_SIZE: 5,
	Statistic.FIRE_SIZE: 0,
	Statistic.FIRE_LIT: 0,
	Statistic.DAY: 0,
	Statistic.ROUND: 0, # First 50% rounds are day, next 50% rounds are night
	Statistic.PATHFINDING: 0,
	Statistic.LEVEL: 0,
	Statistic.HANDS_PLAYED: 0,
}

var initial_min_statistic_values = {
	Statistic.HEALTH: 0,
	Statistic.INSANITY: 0,
	Statistic.ACTION_POINTS: 0,
	Statistic.HAND_SIZE: 0,
	Statistic.FIRE_SIZE: 0,
	Statistic.FIRE_LIT: 0,
	Statistic.DAY: 0,
	Statistic.ROUND: 0,
	Statistic.PATHFINDING: 0,
	Statistic.LEVEL: 0,
	Statistic.HANDS_PLAYED: 0,
}

var initial_max_statistic_values = {
	Statistic.HEALTH: 5,
	Statistic.INSANITY: 5,
	Statistic.ACTION_POINTS: 3,
	Statistic.HAND_SIZE: 15,
	Statistic.FIRE_SIZE: 4,
	Statistic.FIRE_LIT: 1,
	Statistic.DAY: 200,
	Statistic.ROUND: 8,
	Statistic.PATHFINDING: 3,
	Statistic.LEVEL: 5,
	Statistic.HANDS_PLAYED: 99999,
}

var min_statistic_values = initial_min_statistic_values.duplicate()
var max_statistic_values = initial_max_statistic_values.duplicate()
var statistics = initial_statistic_values.duplicate()

var current_scene_type: SceneType = SceneType.ANY

signal game_started()
signal statistic_changed(stat: Statistic, new_value: int, old_value: int)
signal travel_requested()

func initialise():
	min_statistic_values = initial_min_statistic_values.duplicate()
	max_statistic_values = initial_max_statistic_values.duplicate()
	statistics = initial_statistic_values.duplicate()
	randomize()

func start_game():
	emit_signal("game_started")

func set_statistic(stat: Statistic, value: int):
	var old_value = statistics[stat]
	var new_value = clamp(value, min_statistic_values[stat], max_statistic_values[stat])
	statistics[stat] = new_value
	emit_signal("statistic_changed", stat, new_value, old_value)
	print("Statistic ", Statistic.find_key(stat), " changed from ", old_value, " to ", new_value)

func set_statistic_max(stat: Statistic, value: int):
	var old_value = max_statistic_values[stat]
	max_statistic_values[stat] = value
	emit_signal("statistic_changed", stat, statistics[stat], statistics[stat])
	print("Statistic max ", Statistic.find_key(stat), " changed from ", old_value, " to ", value)

func change_statistic(stat: Statistic, delta: int):
	set_statistic(stat, statistics[stat] + delta)

func is_daytime() -> bool:
	return statistics[Statistic.ROUND] < 4

func is_insane() -> bool:
	return statistics[Statistic.INSANITY] >= 3

func is_warm() -> bool:
	return is_daytime() or (statistics[Statistic.FIRE_LIT] > 0)

func is_smoking() -> bool:
	return statistics[Statistic.FIRE_LIT] > 0 && statistics[Statistic.FIRE_SIZE] > 1

func next_round() -> TurnEndImpact:
	var next_day_coming = statistics[Statistic.ROUND] == max_statistic_values[Statistic.ROUND]
	if !next_day_coming:
		change_statistic(Statistic.ROUND, 1)

	if statistics[Statistic.ROUND] == floor(max_statistic_values[Statistic.ROUND] / 2):
		return TurnEndImpact.NIGHT_FALLS
	elif next_day_coming:
		set_statistic(Statistic.ROUND, 0)
		change_statistic(Statistic.DAY, 1)
		return TurnEndImpact.NEW_DAY
	return TurnEndImpact.NORMAL

func request_travel():
	emit_signal("travel_requested")