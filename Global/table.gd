extends Node2D
class_name Table

signal state_changed(new_state: TableState)

@export_group("Shuffle Settings")
@export var shuffle_duration: float = 1.1
@export var shuffle_time_randomness: float = 0.2
@export var shuffle_messiness: float = 80.0
@export var shuffle_rotation_messiness: float = 20.0
@export var shuffle_scale_randomness: float = 0.05

@export_group("Card Draw Settings")
@export var draw_duration: float = 0.5
@export var draw_time_randomness: float = 0.1
@export var draw_time_stagger: float = 0.2
@export var draw_pile_messiness: float = 10.0
@export var draw_pile_rotation_messiness: float = 5.0

@export_group("Card Discard Settings")
@export var discard_duration: float = 0.5
@export var discard_time_randomness: float = 0.1
@export var discard_time_stagger: float = 0.1
@export var discard_pile_messiness: float = 20.0
@export var discard_pile_rotation_messiness: float = 10.0

@export_group("Hand Layout Settings")
@export var hand_messiness: float = 2.0
@export var hand_rotation_messiness: float = 2.0
@export var hand_rotation_spread: float = 50.0
@export var hand_card_spacing: float = 150.0
@export var hand_fan_height: float = 80.0

@export_group("Card Settings")
@export var card_scale: float = 0.3
@export var hover_scale: float = 0.40
@export var hover_time: float = 0.2
@export var selected_scale: float = 0.48
@export var mousedown_time: float = 0.2
@export var mousedown_scale: float = 0.35

@export_group("Selected Card Follow Settings")
@export var selected_follow_stiffness: float = 100.0
@export var selected_follow_damping: float = 10.0
@export var selected_follow_max_speed: float = 10000.0

@export_group("Card Play Settings")
@export var play_card_move_duration: float = 0.3


enum TableState {
	Idle,
	PlayingCard,
	DiscardingHand,
	DrawingHand,
	ShufflingDeck,
	NotPlayerTurn,
}

var draw_pile: Array[BaseCard] = []
var discard_pile: Array[BaseCard] = []
var hand: Array[BaseCard] = []
var hovered_cards: Array[BaseCard] = []
var currently_hovered_card: BaseCard = null
var currently_selected_card: BaseCard = null
var selected_card_index := 0
var state = TableState.ShufflingDeck
var selected_follow_velocity: Vector2 = Vector2.ZERO
signal _turn_ended()


# In this file we deal with the overall management of cards on the table, and the order of the turn.
# The cards themselves are responsible for taking over once they are selected.
# See GameDriver for the overall game loop, and BaseCard for the card lifecycle and actions.

func _ready() -> void:
	Global.table = self
	# Initalize the deck
	_collect_base_cards($Cards)

func _process(delta: float) -> void:
	_poll_selected_card_movement(delta)

func _input(event: InputEvent) -> void:
	if currently_selected_card == null:
		return

	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
		_cancel_selected_card_play()
	elif mouse_event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		_play_selected_card()

## End the turn and discard the hand.
func end_turn():
	emit_signal("_turn_ended")
	_change_state(TableState.DiscardingHand)
	await _discard_hand()
	_change_state(TableState.NotPlayerTurn)

## Draw cards, reshuffling discard into draw if we run out.
func draw_cards():
	_change_state(TableState.DrawingHand)
	await _draw_cards_into_hand()

	if hand.size() < Global.statistics[Global.Statistic.HAND_SIZE] && !discard_pile.is_empty():
		_change_state(TableState.ShufflingDeck)
		await _shuffle_discard_pile_into_draw_pile()
		_change_state(TableState.DrawingHand)
		await _draw_cards_into_hand()
	
	_change_state(TableState.Idle)

## Add a card and hook it up
func initialise_card_to_discard_pile(card: BaseCard, delay: float = 0.0) -> Tween:
	if !is_instance_valid(card.get_parent()):
		$Cards.add_child(card)
		card.global_position = $SpawnPoint.global_position
	var tween = _tween_card_discard(card, delay)
	discard_pile.append(card)
	_attach_mouse_watchers(card)
	return tween

## Discard a card that is already in the hand
func add_card_to_discard_pile(card: BaseCard, delay: float = 0.0) -> Tween:
	card.action_discard()
	var tween = _tween_card_discard(card, delay)
	discard_pile.append(card)
	return tween

## Burn a card that is anywhere
func burn_card(card: BaseCard):
	# Remove card from whatever pile it is in
	if card in hand:
		hand.erase(card)
		_reorder_hand()
	elif card in draw_pile:
		draw_pile.erase(card)
	elif card in discard_pile:
		discard_pile.erase(card)
	
	# Tween it to the center, pull it to top z-index, and burn it up
	card.z_index = 1000
	card.show_face()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "global_position", $PlayPoint.global_position, play_card_move_duration)
	tween.parallel().tween_property(card, "rotation_degrees", 0, play_card_move_duration)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * selected_scale, play_card_move_duration)
	await tween.finished
	await card._do_burn()

# General helper functions
func _change_state(new_state: TableState):
	state = new_state
	emit_signal("state_changed", new_state)

func all_cards() -> Array[BaseCard]:
	return hand + draw_pile + discard_pile

func _collect_base_cards(container: Node):
	for child in container.get_children():
		if child is BaseCard:
			child.scale = Vector2.ONE * card_scale
			initialise_card_to_discard_pile(child)
		else:
			push_warning("Child '%s' is not a BaseCard and will be skipped." % child.name)

func _attach_mouse_watchers(card: BaseCard):
	card.mouse_hovered.connect(func(c):
		if c not in hand:
			return

		if c not in hovered_cards:
			hovered_cards.append(c)

		if currently_hovered_card == c:
			return
		
		if currently_selected_card != null:
			return # Don't change hover if we have a selected card

		if currently_hovered_card == null or currently_hovered_card not in hand:
			_set_currently_hovered_card(c)
	)
	card.mouse_unhovered.connect(func(c):
		hovered_cards.erase(c)

		if c == currently_selected_card:
			return # Don't change hover if we are the selected card

		if c != currently_hovered_card:
			return

		_set_currently_hovered_card(_pick_next_hovered_card())
	)
	card.mouse_event.connect(func(c, event):
		if state != TableState.Idle:
			return
		if event is InputEventMouseButton:
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.pressed:
					_set_mousedown_visual(c)
					if not c.selected and c.is_playable():
						_set_currently_selected_card(c)
				else:
					_set_mouseup_visual(c)
	)
	card.discard.connect(func(c, burn):
		c.selected = false
		c.hovered = false
		hovered_cards.erase(c)
		hand.erase(c)
		if !burn:
			add_card_to_discard_pile(c)
		_change_state(TableState.Idle)
	)

# Selection
func _set_currently_selected_card(card: BaseCard):
	if currently_selected_card == card:
		return

	if currently_selected_card != null:
		currently_selected_card.selected = false
		if currently_selected_card in hand:
			_apply_unhover_visual(currently_selected_card)

	currently_selected_card = card
	selected_follow_velocity = Vector2.ZERO

	if currently_selected_card != null:
		currently_selected_card.selected = true
		_change_state(TableState.PlayingCard)

func _poll_selected_card_movement(delta: float):
	if currently_selected_card == null:
		selected_follow_velocity = Vector2.ZERO
		return

	var displacement = get_global_mouse_position() - currently_selected_card.global_position
	selected_follow_velocity += displacement * selected_follow_stiffness * delta
	selected_follow_velocity *= max(0.0, 1.0 - selected_follow_damping * delta)

	if selected_follow_velocity.length() > selected_follow_max_speed:
		selected_follow_velocity = selected_follow_velocity.normalized() * selected_follow_max_speed

	currently_selected_card.global_position += selected_follow_velocity * delta

func _cancel_selected_card_play():
	if currently_selected_card == null:
		return

	_set_currently_selected_card(null)
	_set_currently_hovered_card(null)
	_change_state(TableState.Idle)
	_reorder_hand()

func _play_selected_card():
	if currently_selected_card == null:
		return

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(currently_selected_card, "global_position", $PlayPoint.global_position, play_card_move_duration)
	tween.parallel().tween_property(currently_selected_card, "rotation_degrees", 0, play_card_move_duration)

	var card = currently_selected_card
	await tween.finished
	hand.erase(card)
	card.selected = false
	card.hovered = false
	hovered_cards.erase(card)
	_set_currently_selected_card(null)
	_reorder_hand()

	await card.action_play()
	if state == TableState.PlayingCard:
		_change_state(TableState.Idle)

func _set_mousedown_visual(card: BaseCard):
	var mousedown_tween = create_tween()
	mousedown_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	mousedown_tween.tween_property(card, "scale", Vector2.ONE * mousedown_scale, mousedown_time)

func _set_mouseup_visual(card: BaseCard):
	var mouseup_tween = create_tween()
	mouseup_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	mouseup_tween.tween_property(card, "scale", Vector2.ONE * hover_scale, mousedown_time)

# Hovering
func _set_currently_hovered_card(card: BaseCard):
	if currently_hovered_card == card:
		return

	if currently_hovered_card != null and currently_hovered_card in hand:
		_apply_unhover_visual(currently_hovered_card)
		currently_hovered_card.hovered = false

	currently_hovered_card = card

	if currently_hovered_card != null and currently_hovered_card in hand:
		_apply_hover_visual(currently_hovered_card)
		currently_hovered_card.hovered = true

func _pick_next_hovered_card() -> BaseCard:
	for i in range(hovered_cards.size() - 1, -1, -1):
		var candidate = hovered_cards[i]
		if candidate in hand:
			return candidate
	return null

func _apply_hover_visual(card: BaseCard):
	# TODO: Might want to lead these tweens with an animation state machine
	var hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	hover_tween.tween_property(card, "scale", Vector2.ONE * hover_scale, hover_time)
	hover_tween.tween_property(card, "rotation_degrees", 0, hover_time)
	card.z_index = 100

func _apply_unhover_visual(card: BaseCard):
	if card not in hand:
		return

	var hand_index = hand.find(card)
	if hand_index == -1:
		return

	var unhover_tween = create_tween()
	unhover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	unhover_tween.tween_property(card, "scale", Vector2.ONE * card_scale, hover_time)
	unhover_tween.tween_property(card, "rotation_degrees", _calculate_card_rotation_in_hand(hand_index), hover_time)
	card.z_index = _calculate_card_hand_z_index(hand_index)

# Hand positioning
func _calculate_card_position_in_hand(index: int) -> Vector2:
	var hand_size = hand.size()
	if hand_size == 0:
		return Vector2.ZERO
	var spacing = hand_card_spacing
	var total_width = (hand_size - 1) * spacing
	var start_x = total_width / 2
	if hand_size == 1:
		return Vector2(start_x - index * spacing, 0)

	var center = (hand_size - 1) / 2.0
	var normalized_from_center = (index - center) / center
	var y_offset = -(1.0 - normalized_from_center * normalized_from_center) * hand_fan_height
	return Vector2(start_x - index * spacing, y_offset)

func _calculate_card_rotation_in_hand(index: int) -> float:
	var hand_size = hand.size()
	if hand_size == 0 || hand_size == 1:
		return 0.0
	var rotation_range = hand_rotation_spread
	var start_rotation = rotation_range / 2
	return start_rotation - index * (rotation_range / (hand_size - 1))

func _calculate_card_hand_z_index(index: int) -> int:
	return 30 - index

# Every Day I'm Shuffling
func _shuffle_discard_pile_into_draw_pile():
	discard_pile += draw_pile
	draw_pile.clear()
	discard_pile.shuffle()
	draw_pile = discard_pile
	discard_pile = []

	# Animate the shuffling
	var all_tweens: Array[Tween] = []
	for z in range(draw_pile.size()):
		all_tweens.append(_tween_card_shuffle(draw_pile[z], z))
	await WaitAllTweens.wait_all_tweens(all_tweens)

func _tween_card_shuffle(card: BaseCard, new_z_index: int) -> Tween:
	# We tween from current position to the shuffle point, then to the draw pile
	var duration = shuffle_duration + randf_range(-shuffle_time_randomness, shuffle_time_randomness)
	var random_offset = Vector2(randf_range(-shuffle_messiness, shuffle_messiness), randf_range(-shuffle_messiness, shuffle_messiness))
	var random_offset_draw = Vector2(randf_range(-draw_pile_messiness, draw_pile_messiness), randf_range(-draw_pile_messiness, draw_pile_messiness))
	var random_rotation_shuffle = randf_range(-shuffle_rotation_messiness, shuffle_rotation_messiness)
	var random_rotation_draw = randf_range(-draw_pile_rotation_messiness, draw_pile_rotation_messiness)

	# Yes I legitimately wrote this all by hand xD
	var tween = create_tween()
	tween.tween_property(card, "global_position", $ShufflePoint.global_position + random_offset, duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", random_rotation_shuffle, duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * (card_scale + randf_range(-shuffle_scale_randomness, shuffle_scale_randomness)), duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_callback(card.hide_face.bind())
	tween.tween_property(card, "z_index", new_z_index, 0)
	tween.tween_property(card, "global_position", $DrawPoint.global_position + random_offset_draw, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", random_rotation_draw, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * card_scale, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	return tween

# Draw!
func _draw_cards_into_hand():
	var hand_size = Global.statistics[Global.Statistic.HAND_SIZE]
	var original_hand_size = hand.size()
	while hand.size() < hand_size and draw_pile.size() > 0:
		hand.append(draw_pile.pop_back())
		
	# Animate the drawing of old cards in hand to new positions
	var all_tweens: Array[Tween] = []
	for i in range(0, original_hand_size):
		all_tweens.append(_tween_card_hand_move(hand[i], i))
	# Animate the drawing of new cards into hand
	var delay_timer = draw_time_stagger
	for i in range(original_hand_size, hand.size()):
		all_tweens.append(_tween_card_draw(hand[i], i, delay_timer))
		delay_timer += draw_time_stagger
	await WaitAllTweens.wait_all_tweens(all_tweens)

func _reorder_hand():
	var all_tweens: Array[Tween] = []
	for i in range(hand.size()):
		all_tweens.append(_tween_card_hand_move(hand[i], i))
	await WaitAllTweens.wait_all_tweens(all_tweens)

func _tween_card_draw(card: BaseCard, hand_index: int, delay: float) -> Tween:
	var duration = draw_duration + randf_range(-draw_time_randomness, draw_time_randomness)
	var random_offset = Vector2(randf_range(-hand_messiness, hand_messiness), randf_range(-hand_messiness, hand_messiness))
	var target_position = $HandPoint.global_position + _calculate_card_position_in_hand(hand_index) + random_offset
	var random_rotation = randf_range(-hand_rotation_messiness, hand_rotation_messiness)
	var stagger_rotation = _calculate_card_rotation_in_hand(hand_index)
	var target_rotation = random_rotation + stagger_rotation
	card.z_index = _calculate_card_hand_z_index(hand_index)

	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(card, "global_position", target_position, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", target_rotation, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(card.show_face.bind())
	tween.tween_callback(card.action_draw.bind())
	return tween

func _tween_card_hand_move(card: BaseCard, hand_index: int) -> Tween:
	var duration = (draw_duration + randf_range(-draw_time_randomness, draw_time_randomness)) / 2
	var random_offset = Vector2(randf_range(-hand_messiness, hand_messiness), randf_range(-hand_messiness, hand_messiness))
	var target_position = $HandPoint.global_position + _calculate_card_position_in_hand(hand_index) + random_offset
	var random_rotation = randf_range(-hand_rotation_messiness, hand_rotation_messiness)
	var stagger_rotation = _calculate_card_rotation_in_hand(hand_index)
	var target_rotation = random_rotation + stagger_rotation

	var tween = create_tween()
	tween.tween_property(card, "global_position", target_position, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", target_rotation, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	return tween

# Discard card
func _tween_card_discard(card: BaseCard, delay: float = 0.0) -> Tween:
	var duration = discard_duration + randf_range(-discard_time_randomness, discard_time_randomness)
	var random_offset = Vector2(randf_range(-discard_pile_messiness, discard_pile_messiness), randf_range(-discard_pile_messiness, discard_pile_messiness))
	var target_position = $DiscardPoint.global_position + random_offset
	var target_rotation = randf_range(-discard_pile_rotation_messiness, discard_pile_rotation_messiness)

	var tween = create_tween()
	var new_z_index = -100 + discard_pile.size()
	tween.tween_interval(delay)
	tween.tween_property(card, "global_position", target_position, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", target_rotation, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * card_scale, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "z_index", new_z_index, duration / 2) 
	return tween

func _discard_hand():
	var all_tweens: Array[Tween] = []
	var old_hand = hand.duplicate()
	hovered_cards.clear()
	currently_hovered_card = null
	hand.clear()
	for i in range(old_hand.size()):
		var card = old_hand[i]
		all_tweens.append(add_card_to_discard_pile(card, discard_time_stagger * i))
		
	await WaitAllTweens.wait_all_tweens(all_tweens)
	hand.clear()
