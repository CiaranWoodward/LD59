extends Node

var table: Table

enum Statistic {
    HEALTH,
    INSANITY,
    ACTION_POINTS,
    HAND_SIZE,
    FIRE_SIZE,
    FIRE_LIT,
}

var statistics = {
    Statistic.HEALTH: 10,
    Statistic.INSANITY: 0,
    Statistic.ACTION_POINTS: 3,
    Statistic.HAND_SIZE: 5,
    Statistic.FIRE_SIZE: 0,
    Statistic.FIRE_LIT: 0,
}

var min_statistic_values = {
    Statistic.HEALTH: 0,
    Statistic.INSANITY: 0,
    Statistic.ACTION_POINTS: 0,
    Statistic.HAND_SIZE: 0,
    Statistic.FIRE_SIZE: 0,
    Statistic.FIRE_LIT: 0,
}

var max_statistic_values = {
    Statistic.HEALTH: 10,
    Statistic.INSANITY: 10,
    Statistic.ACTION_POINTS: 3,
    Statistic.HAND_SIZE: 15,
    Statistic.FIRE_SIZE: 3,
    Statistic.FIRE_LIT: 1,
}

signal statistic_changed(stat: Statistic, new_value: int, old_value: int)

func set_statistic(stat: Statistic, value: int):
    var old_value = statistics[stat]
    var new_value = clamp(value, min_statistic_values[stat], max_statistic_values[stat])
    statistics[stat] = new_value
    emit_signal("statistic_changed", stat, new_value, old_value)
    print("Statistic ", Statistic.find_key(stat), " changed from ", old_value, " to ", new_value)

func change_statistic(stat: Statistic, delta: int):
    set_statistic(stat, statistics[stat] + delta)