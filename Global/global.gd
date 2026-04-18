extends Node

enum Statistic {
    HEALTH,
    INSANITY,
    ACTION_POINTS,
    HAND_SIZE,
}

var statistics = {
    Statistic.HEALTH: 10,
    Statistic.INSANITY: 0,
    Statistic.ACTION_POINTS: 3,
    Statistic.HAND_SIZE: 5,
}

var min_statistic_values = {
    Statistic.HEALTH: 0,
    Statistic.INSANITY: 0,
    Statistic.ACTION_POINTS: 0,
    Statistic.HAND_SIZE: 0,
}

var max_statistic_values = {
    Statistic.HEALTH: 10,
    Statistic.INSANITY: 10,
    Statistic.ACTION_POINTS: 3,
    Statistic.HAND_SIZE: 15,
}

signal statistic_changed(stat: Statistic, new_value: int, old_value: int)

func set_statistic(stat: Statistic, value: int):
    var old_value = statistics[stat]
    statistics[stat] = clamp(value, min_statistic_values[stat], max_statistic_values[stat])
    emit_signal("statistic_changed", stat, statistics[stat], old_value)

func change_statistic(stat: Statistic, delta: int):
    set_statistic(stat, statistics[stat] + delta)