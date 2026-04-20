extends Node

var table: Table

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
}

var min_statistic_values = {
	Statistic.HEALTH: 0,
	Statistic.INSANITY: 0,
	Statistic.ACTION_POINTS: 0,
	Statistic.HAND_SIZE: 0,
	Statistic.FIRE_SIZE: 0,
	Statistic.FIRE_LIT: 0,
	Statistic.DAY: 0,
	Statistic.ROUND: 0,
	Statistic.PATHFINDING: 0,
}

var max_statistic_values = {
	Statistic.HEALTH: 5,
	Statistic.INSANITY: 5,
	Statistic.ACTION_POINTS: 3,
	Statistic.HAND_SIZE: 15,
	Statistic.FIRE_SIZE: 3,
	Statistic.FIRE_LIT: 1,
	Statistic.DAY: 10,
	Statistic.ROUND: 6,
	Statistic.PATHFINDING: 6,
}

var statistics = initial_statistic_values.duplicate()

signal game_started()
signal statistic_changed(stat: Statistic, new_value: int, old_value: int)
signal travel_requested()

func start_game():
	randomize()
	statistics = initial_statistic_values.duplicate()
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
	return statistics[Statistic.ROUND] < 3

func is_insane() -> bool:
	return statistics[Statistic.INSANITY] >= 3

func is_warm() -> bool:
	return is_daytime() or (statistics[Statistic.FIRE_LIT] > 0)

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