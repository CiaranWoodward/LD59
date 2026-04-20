extends Node

var hungerCard: PackedScene = preload("res://Cards/HungerCard.tscn")

# This is a singleton that drives everything. Nothing else refers to it, but it reaches into everything else.
func _ready() -> void:
	Global.statistic_changed.connect(stat_watcher)
	Global.game_started.connect(func():
		forever_game_loop())

func stat_watcher(stat, new_value, _old_value):
	if stat == Global.Statistic.HEALTH and new_value <= 0:
		Global.table.game_over()

func forever_game_loop():
	var table = Global.table
	# Intro
	await table.get_encounter_screen().activate_specific_encounter("JourneyStart")

	while table.state != Table.TableState.GameOver:
		Global.set_statistic(Global.Statistic.ACTION_POINTS, Global.max_statistic_values[Global.Statistic.ACTION_POINTS])
		await table.draw_cards()

		if table.state == Table.TableState.GameOver:
			return

		# Wait for the player to finish their turn
		# TODO: End turn button
		while table.state != Table.TableState.Idle || table.any_playable_cards_in_hand():
			await table.state_changed
			if table.state == Table.TableState.GameOver:
				return
			table.all_cards()
		
		# End the player's turn
		await table.end_turn()

		var turn_end_impact = Global.next_round()

		if table.state == Table.TableState.GameOver:
			return
		
		table.initialise_card_to_discard_pile(hungerCard.instantiate())

		if turn_end_impact != Global.TurnEndImpact.NORMAL:
			await table.reshuffle()

		# Process the fire
		if Global.statistics[Global.Statistic.FIRE_LIT] > 0:
			Global.change_statistic(Global.Statistic.FIRE_SIZE, -1)
			if Global.statistics[Global.Statistic.FIRE_SIZE] <= 0:
				Global.set_statistic(Global.Statistic.FIRE_LIT, 0)
		
		if table.state == Table.TableState.GameOver:
			return
