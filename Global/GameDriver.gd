extends Node

var hungerCard: PackedScene = preload("res://Cards/HungerCard.tscn")
var chillCard: PackedScene = preload("res://Cards/ChillCard.tscn")
var travelCard: PackedScene = preload("res://Cards/TravelCard.tscn")

var _travelState = 0

# This is a singleton that drives everything. Nothing else refers to it, but it reaches into everything else.
func _ready() -> void:
	Global.statistic_changed.connect(stat_watcher)
	Global.game_started.connect(func():
		forever_game_loop())
	Global.travel_requested.connect(func():
		handle_travel_request())

func stat_watcher(stat, new_value, old_value):
	if stat == Global.Statistic.HEALTH and new_value <= 0:
		Global.table.game_over()
	if stat == Global.Statistic.PATHFINDING and old_value != new_value && new_value == Global.max_statistic_values[Global.Statistic.PATHFINDING]:
		var travel_card = travelCard.instantiate()
		await Global.table.initialise_card_to_discard_pile(travel_card)
		
func turn_ticker(was_cold: bool):
	if was_cold:
		await Global.table.initialise_card_to_discard_pile(chillCard.instantiate())
	# Process the fire
	if Global.statistics[Global.Statistic.FIRE_LIT] > 0:
		Global.change_statistic(Global.Statistic.FIRE_SIZE, -1)
		if Global.statistics[Global.Statistic.FIRE_SIZE] <= 0:
			Global.set_statistic(Global.Statistic.FIRE_LIT, 0)

func handle_travel_request():
	_travelState = 1

func handle_travel():
	_travelState = 0
	# Shuffle all cards
	Global.table.reshuffle()
	# Advance the day and reset the round
	Global.set_statistic(Global.Statistic.ROUND, 0)
	Global.change_statistic(Global.Statistic.DAY, 1)
	# Unload the old scene
	await Global.level.transition_scene_out()
	# Burn all environment cards in the deck
	var cards_to_burn = Global.table.all_cards().filter(func(c): return c is BaseCard and c.environment)
	for card in cards_to_burn:
		await Global.table.burn_card(card)
	# Increase the level
	Global.change_statistic(Global.Statistic.LEVEL, 1)
	Global.set_statistic_max(Global.Statistic.PATHFINDING, Global.max_statistic_values[Global.Statistic.PATHFINDING] + 1)
	Global.set_statistic(Global.Statistic.PATHFINDING, 0)
	Global.set_statistic(Global.Statistic.FIRE_SIZE, 0)
	Global.set_statistic(Global.Statistic.FIRE_LIT, 0)

	if Global.statistics[Global.Statistic.LEVEL] == 1:
		await Global.table.get_encounter_screen().activate_specific_encounter("FirstStep")
	elif Global.statistics[Global.Statistic.LEVEL] == 5:
		await Global.table.get_encounter_screen().activate_specific_encounter("GameComplete")
	else:
		await Global.table.get_encounter_screen().activate_random_travel_encounter()

	# Load the new scene in
	await Global.level.transition_scene_in(Global.statistics[Global.Statistic.LEVEL] - 1)

func forever_game_loop():
	var table = Global.table
	# Intro
	await table.get_encounter_screen().activate_specific_encounter("JourneyStart")


	while table.state != Table.TableState.GameOver:
		Global.set_statistic(Global.Statistic.ACTION_POINTS, Global.max_statistic_values[Global.Statistic.ACTION_POINTS])
		await table.draw_cards()

		await table.get_encounter_screen().activate_random_encounter()

		# If there are 3 hunger cards, burn them all and take 1 damage
		var hunger_cards = table.hand.filter(func(c): return c.card_name == "Hunger")
		if hunger_cards.size() >= 3:
			for card in hunger_cards:
				await table.burn_card(card)
			Global.change_statistic(Global.Statistic.HEALTH, -1)

		if table.state == Table.TableState.GameOver:
			return

		# Wait for the player to finish their turn
		while true:
			await table.state_changed
			if table.state == Table.TableState.GameOver:
				return
			if table.state == Table.TableState.NotPlayerTurn:
				break
			if _travelState == 1:
				break
			table.all_cards()
		
		Global.change_statistic(Global.Statistic.HANDS_PLAYED, 1)
		# End the player's turn if it isn't already over
		if table.state != Table.TableState.NotPlayerTurn:
			await table.end_turn()

		# Some random random encounters
		var hands_played = Global.statistics[Global.Statistic.HANDS_PLAYED]
		if hands_played == 14 or hands_played == 28 or hands_played == 42:
			await table.get_encounter_screen().activate_random_encounter()
		
		if _travelState == 1:
			await handle_travel()
			continue

		var was_cold = !Global.is_warm()
		var turn_end_impact = Global.next_round()

		if table.state == Table.TableState.GameOver:
			return
		
		await table.initialise_card_to_discard_pile(hungerCard.instantiate())

		if turn_end_impact != Global.TurnEndImpact.NORMAL:
			if turn_end_impact == Global.TurnEndImpact.NEW_DAY:
				await Global.table.get_encounter_screen().activate_specific_encounter("DayBreak")
			await table.reshuffle()
		
		# Process end of turn effects
		await turn_ticker(was_cold)
		
		if table.state == Table.TableState.GameOver:
			return
