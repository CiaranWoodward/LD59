@tool
extends Control
class_name EncounterScreen

var _active_encounter: Encounter = null
var _text_tween: Tween = null
var _sanity_tween: Tween = null

# $ActiveEncounter contains the currently active encounter node, if any
# $ChoiceA and $ChoiceB are nodes - the child of these nodes should be the card you get by choosing the respective choice - Which can be extracted from the encounter node
# $PanelContainer/MarginContainer/VBoxContainer/MainText is the main text of the encounter, which should be updated to reflect the current encounter's text
# That text should animate on, by tweening the 'visible_characters' property of the label from 0 to the length of the text.
# $PanelContainer/MarginContainer/VBoxContainer/SanityDependentText is the text that should be shown if the player is insane, which should be updated to reflect the current encounter's text_insane or text_sane
# depending on the player's current sanity. This should animate on after the main text has completed, but using the flicker tween from TweenCan to give it a flickering effect (not typed).
# The 2 buttons under $PanelContainer/MarginContainer/VBoxContainer/ChoiceButtons should only be visible if the choice is active (string is nonempty).
# The skip button under $PanelContainer/MarginContainer/VBoxContainer/SkipButton should only be visible if the encounter can be skipped (string is nonempty).

# While in-editor (tool mode), everything should be visible when there is no active encounter. If there is an active encounter, the text and choices should reflect that encounter, but the sanity-dependent text should be visible based on an exported tool bool
# While in game, the root node should be invisible when there is no active encounter. When there is an active encounter, the text and choices should reflect that encounter, and the sanity-dependent text should depend on the player's current sanity.

## In-editor toggle for previewing insane vs sane text
@export var preview_insane: bool = false:
	set(value):
		preview_insane = value
		if Engine.is_editor_hint():
			_update_display()
@export var debug_visible: bool = true:
	set(value):
		debug_visible = value
		if Engine.is_editor_hint():
			visible = value
@export var character_type_time_ms: float = 10

signal choice_made(chosen_card: BaseCard)
signal encounter_finished()

enum Choice {
	A,
	B,
	SKIP,
}

func _ready() -> void:
	$ActiveEncounter.child_entered_tree.connect(func(node):
		if node is Encounter:
			print("EncounterScreen: Activated encounter: " + node.name)
			_active_encounter = node
			_update_display()
	)
	$ActiveEncounter.child_exiting_tree.connect(func(node):
		if node is Encounter and _active_encounter == node:
			print("EncounterScreen: Deactivated encounter: " + node.name)
			_active_encounter = null
			_clear_choice_cards()
			call_deferred("_update_display")
	)

	var choice_a_btn := $PanelContainer/MarginContainer/VBoxContainer/ChoiceButtons/ChoiceA as Button
	var choice_b_btn := $PanelContainer/MarginContainer/VBoxContainer/ChoiceButtons/ChoiceB as Button
	var skip_btn := $PanelContainer/MarginContainer/VBoxContainer/SkipButton as Button

	choice_a_btn.pressed.connect(func():
		if _active_encounter:
			await _choose(Choice.A)
	)
	choice_b_btn.pressed.connect(func():
		if _active_encounter:
			await _choose(Choice.B)
	)
	skip_btn.pressed.connect(func():
		if _active_encounter:
			await _choose(Choice.SKIP)
	)

	_update_display()

func _is_insane() -> bool:
	if Engine.is_editor_hint():
		return preview_insane
	return Global.statistics[Global.Statistic.INSANITY] >= Global.max_statistic_values[Global.Statistic.INSANITY] / 2

func _meets_sanity_requirement(req: Encounter.SanityRequirement) -> bool:
	match req:
		Encounter.SanityRequirement.ANY:
			return true
		Encounter.SanityRequirement.SANE:
			return not _is_insane()
		Encounter.SanityRequirement.INSANE:
			return _is_insane()
	return true

func _has_required_card(card_required: String) -> bool:
	if card_required == "":
		return true
	if Engine.is_editor_hint():
		return true
	return Global.table.all_cards().any(func(c): return c is BaseCard and c.card_name == card_required)

func _find_required_card(card_required: String) -> BaseCard:
	var cards = Global.table.all_cards().filter(func(c): return c is BaseCard and c.card_name == card_required)
	if cards.is_empty():
		return null
	return cards[0]

func _clear_choice_cards() -> void:
	for child in $ChoiceA.get_children():
		child.queue_free()
	for child in $ChoiceB.get_children():
		child.queue_free()

func _stat_delta_tooltip(stat: Global.Statistic, delta: int) -> String:
	if delta == 0:
		return ""
	var stat_name: String = Global.StatisticNames.get(stat, "")
	var stat_sign := "+" if delta > 0 else ""
	return stat_name + " " + stat_sign + str(delta)

func _update_display() -> void:
	if _text_tween and _text_tween.is_valid():
		_text_tween.kill()
	if _sanity_tween and _sanity_tween.is_valid():
		_sanity_tween.kill()

	var title := $PanelContainer/MarginContainer/VBoxContainer/Title as Label
	var main_text := $PanelContainer/MarginContainer/VBoxContainer/MainText as RichTextLabel
	var sanity_text := $PanelContainer/MarginContainer/VBoxContainer/SanityDependentText as RichTextLabel
	var choice_a_btn := $PanelContainer/MarginContainer/VBoxContainer/ChoiceButtons/ChoiceA as Button
	var choice_b_btn := $PanelContainer/MarginContainer/VBoxContainer/ChoiceButtons/ChoiceB as Button
	var skip_btn := $PanelContainer/MarginContainer/VBoxContainer/SkipButton as Button

	if _active_encounter == null:
		if Engine.is_editor_hint():
			visible = debug_visible
			title.visible = debug_visible
			main_text.visible = debug_visible
			sanity_text.visible = debug_visible
			choice_a_btn.visible = debug_visible
			choice_b_btn.visible = debug_visible
			skip_btn.visible = debug_visible
		else:
			visible = false
		return

	visible = true

	# Main text
	title.text = _active_encounter.title
	main_text.text = _active_encounter.encounter_text
	main_text.visible_characters = 0

	if _active_encounter.game_complete_screen:
		main_text.text += "\n\n You made it here in " + str(Global.statistics[Global.Statistic.DAY]) + " days, with " + str(Global.statistics[Global.Statistic.INSANITY]) + " insanity after playing " + str(Global.statistics[Global.Statistic.HANDS_PLAYED]) + " hands."

	# Sanity-dependent text
	var insane := _is_insane()
	var sanity_string: String
	if insane and _active_encounter.encounter_text_insane != "":
		sanity_string = _active_encounter.encounter_text_insane
	elif not insane and _active_encounter.encounter_text_sane != "":
		sanity_string = _active_encounter.encounter_text_sane
	else:
		sanity_string = ""

	sanity_text.text = sanity_string
	sanity_text.visible = false

	# Choice buttons
	choice_a_btn.visible = _active_encounter.choicea_text != ""
	choice_a_btn.text = _active_encounter.choicea_text
	choice_a_btn.disabled = not _meets_sanity_requirement(_active_encounter.choicea_sanity) or not _has_required_card(_active_encounter.choicea_card_required)
	choice_a_btn.tooltip_text = _stat_delta_tooltip(_active_encounter.choicea_stat, _active_encounter.choicea_stat_delta)
	choice_b_btn.visible = _active_encounter.choiceb_text != ""
	choice_b_btn.text = _active_encounter.choiceb_text
	choice_b_btn.disabled = not _meets_sanity_requirement(_active_encounter.choiceb_sanity) or not _has_required_card(_active_encounter.choiceb_card_required)
	choice_b_btn.tooltip_text = _stat_delta_tooltip(_active_encounter.choiceb_stat, _active_encounter.choiceb_stat_delta)

	# Skip button
	skip_btn.visible = _active_encounter.skip_text != ""
	skip_btn.text = _active_encounter.skip_text
	skip_btn.disabled = not _meets_sanity_requirement(_active_encounter.skip_sanity)
	skip_btn.tooltip_text = _stat_delta_tooltip(_active_encounter.skip_stat, _active_encounter.skip_stat_delta)

	# Choice cards
	_clear_choice_cards()
	if _active_encounter.choicea_card:
		$ChoiceA.add_child(_active_encounter.choicea_card.instantiate())
	if _active_encounter.choiceb_card:
		$ChoiceB.add_child(_active_encounter.choiceb_card.instantiate())

	# Animate main text
	var char_count := main_text.get_total_character_count()
	var type_duration := char_count * (character_type_time_ms / 1000.0)
	_text_tween = create_tween()
	_text_tween.tween_property(main_text, "visible_characters", char_count, type_duration)

	# After main text finishes, flicker in sanity text
	if sanity_string != "":
		_text_tween.tween_callback(func():
			_sanity_tween = TweenCan.flicker_tween(sanity_text, 0.8)
			_sanity_tween.tween_callback(func(): sanity_text.visible = true)
		)

func _activate_encounter(encounter: Encounter) -> void:
	deactivate_encounter()
	var reparented := encounter.get_parent()
	if reparented:
		reparented.remove_child(encounter)
	$ActiveEncounter.add_child(encounter)
	await encounter_finished

func deactivate_encounter() -> void:
	if _active_encounter:
		var enc := _active_encounter
		$ActiveEncounter.remove_child(enc)
		# Return to original parent if possible
		if enc.get_meta("_source_parent", null):
			var source: Node = enc.get_meta("_source_parent")
			source.add_child(enc)

func activate_random_encounter() -> bool:
	var candidates: Array[Encounter] = []
	for child in $RandomEncounters.get_children():
		if child is Encounter and child.can_encounter():
			candidates.append(child)
	if candidates.is_empty():
		return false
	var chosen := candidates[randi() % candidates.size()]
	chosen.set_meta("_source_parent", $RandomEncounters)
	await _activate_encounter(chosen)
	return true

func activate_random_travel_encounter() -> bool:
	var candidates: Array[Encounter] = []
	for child in $TravelEncounters.get_children():
		if child is Encounter and child.can_encounter():
			candidates.append(child)
	if candidates.is_empty():
		return false
	var chosen := candidates[randi() % candidates.size()]
	chosen.set_meta("_source_parent", $TravelEncounters)
	await _activate_encounter(chosen)
	return true

func activate_specific_encounter(encounter_name: String) -> bool:
	var encounter := $SpecificEncounters.get_node_or_null(encounter_name) as Encounter
	if encounter == null:
		push_warning("EncounterScreen: No specific encounter named '" + encounter_name + "'")
		return false
	encounter.set_meta("_source_parent", $SpecificEncounters)
	await _activate_encounter(encounter)
	return true

func _choose(choice: Choice) -> void:
	var burn_a := choice != Choice.A
	var burn_b := choice != Choice.B

	var stat: Global.Statistic
	var delta: int
	match choice:
		Choice.A:
			stat = _active_encounter.choicea_stat
			delta = _active_encounter.choicea_stat_delta
		Choice.B:
			stat = _active_encounter.choiceb_stat
			delta = _active_encounter.choiceb_stat_delta
		Choice.SKIP:
			stat = _active_encounter.skip_stat
			delta = _active_encounter.skip_stat_delta

	# Burn cards that weren't chosen
	if burn_a and $ChoiceA.get_child_count() > 0:
		var card: BaseCard = $ChoiceA.get_child(0)
		await card._do_burn()
	if burn_b and $ChoiceB.get_child_count() > 0:
		var card: BaseCard = $ChoiceB.get_child(0)
		await card._do_burn()

	# Take the chosen card (if any) and add it to the discard pile
	var initialiseCallable: Callable = Callable()
	if choice != Choice.SKIP:
		var chosen_node: Node2D = $ChoiceA if choice == Choice.A else $ChoiceB
		if chosen_node.get_child_count() > 0:
			var chosen_card: BaseCard = chosen_node.get_child(0)
			var gp = chosen_card.global_position
			chosen_node.remove_child(chosen_card)
			initialiseCallable = Global.table.initialise_card_to_discard_pile.bind(chosen_card, 0.3, gp)
			choice_made.emit(chosen_card)

	# Burn the required card if lose_required_card is set
	var required_card_name: String = ""
	var lose_required: bool = false
	match choice:
		Choice.A:
			required_card_name = _active_encounter.choicea_card_required
			lose_required = _active_encounter.choicea_lose_required_card
		Choice.B:
			required_card_name = _active_encounter.choiceb_card_required
			lose_required = _active_encounter.choiceb_lose_required_card
	if required_card_name != "" and lose_required:
		var req_card := _find_required_card(required_card_name)
		if req_card:
			await Global.table.burn_card(req_card)

	if delta != 0:
		Global.change_statistic(stat, delta)

	_active_encounter.played = true
	deactivate_encounter()

	if initialiseCallable:
		await initialiseCallable.call()
		await get_tree().create_timer(0.5).timeout

	encounter_finished.emit()
