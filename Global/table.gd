extends Node2D

signal state_changed(new_state: TableState)

@export var shuffle_duration: float = 1.1
@export var shuffle_time_randomness: float = 0.2

@export var draw_duration: float = 0.5
@export var draw_time_randomness: float = 0.1
@export var draw_time_stagger: float = 0.2

@export var discard_duration: float = 0.5
@export var discard_time_randomness: float = 0.1
@export var discard_time_stagger: float = 0.1

@export var draw_pile_messiness: float = 10.0
@export var shuffle_messiness: float = 80.0
@export var hand_messiness: float = 2.0
@export var discard_pile_messiness: float = 20.0

@export var draw_pile_rotation_messiness: float = 5.0
@export var shuffle_rotation_messiness: float = 20.0
@export var hand_rotation_messiness: float = 2.0
@export var hand_rotation_spread: float = 50.0
@export var discard_pile_rotation_messiness: float = 10.0


@export var shuffle_scale_randomness: float = 0.1
@export var card_scale: float = 0.3

@export var hand_card_spacing: float = 150.0
@export var hand_fan_height: float = 40.0

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
var state = TableState.ShufflingDeck

func _ready() -> void:
	forever_game_loop()

func forever_game_loop():
	# Initalize the deck
	discard_pile = _collect_base_cards($Cards)

	# Loop until the end of the universe
	while true:
		_change_state(TableState.DrawingHand)
		await _draw_cards_into_hand()

		if hand.size() < Global.statistics[Global.Statistic.HAND_SIZE] && !discard_pile.is_empty():
			_change_state(TableState.ShufflingDeck)
			await _shuffle_discard_pile_into_draw_pile()
			_change_state(TableState.DrawingHand)
			await _draw_cards_into_hand()
		
		_change_state(TableState.Idle)

		#TODO: Wait for player to do their thing
		await get_tree().create_timer(3.0).timeout

		_change_state(TableState.DiscardingHand)
		await _discard_hand()

func _change_state(new_state: TableState):
	state = new_state
	emit_signal("state_changed", new_state)

func _collect_base_cards(container: Node) -> Array[BaseCard]:
	var cards: Array[BaseCard] = []
	for child in container.get_children():
		if child is BaseCard:
			cards.append(child as BaseCard)
			child.scale = Vector2.ONE * card_scale
		else:
			push_warning("Child '%s' is not a BaseCard and will be skipped." % child.name)
	return cards

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
	if hand_size == 0:
		return 0.0
	var rotation_range = hand_rotation_spread
	var start_rotation = rotation_range / 2
	return start_rotation - index * (rotation_range / (hand_size - 1))

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

	var tween = create_tween()
	tween.tween_property(card, "global_position", $ShufflePoint.global_position + random_offset, duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", random_rotation_shuffle, duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * (card_scale + randf_range(-shuffle_scale_randomness, shuffle_scale_randomness)), duration / 2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_callback(card.hide_face.bind())
	tween.tween_property(card, "z_index", new_z_index, 0)
	tween.tween_property(card, "global_position", $DrawPoint.global_position + random_offset_draw, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", random_rotation_draw, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE * card_scale, duration / 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.play()
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

func _tween_card_draw(card: BaseCard, hand_index: int, delay: float) -> Tween:
	var duration = draw_duration + randf_range(-draw_time_randomness, draw_time_randomness)
	var random_offset = Vector2(randf_range(-hand_messiness, hand_messiness), randf_range(-hand_messiness, hand_messiness))
	var target_position = $HandPoint.global_position + _calculate_card_position_in_hand(hand_index) + random_offset
	var random_rotation = randf_range(-hand_rotation_messiness, hand_rotation_messiness)
	var stagger_rotation = _calculate_card_rotation_in_hand(hand_index)
	var target_rotation = random_rotation + stagger_rotation

	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(card, "global_position", target_position, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", target_rotation, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(card.show_face.bind())
	tween.play()
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
	tween.play()
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
	tween.parallel().tween_property(card, "z_index", new_z_index, duration / 2) 
	tween.play()
	return tween

func _discard_hand():
	var all_tweens: Array[Tween] = []
	for i in range(hand.size()):
		var card = hand[i]
		all_tweens.append(_tween_card_discard(card, discard_time_stagger * i))
		discard_pile.append(card)
	await WaitAllTweens.wait_all_tweens(all_tweens)
	hand.clear()
