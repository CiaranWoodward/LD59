@tool
extends Node2D
class_name BaseCard

const burn_material: ShaderMaterial = preload("res://Shaders/BurnMaterial.tres")
const unplayable_material: ShaderMaterial = preload("res://Shaders/UnplayableCard.tres")

# These signals are for communication with the Table, which manages the card until it is selected.
signal mouse_hovered(card: BaseCard)
signal mouse_unhovered(card: BaseCard)
signal mouse_event(card: BaseCard, event: InputEventMouseButton)
signal discard(card: BaseCard, burn: bool)

# These are for general use
signal played(card: BaseCard)

enum CardType {
	Basic,
	Environment,
	Tool,
	Resource,
}

enum CardTiming {
	Day,
	Night,
	All
}

enum CardSanityEffect {
	None,
	Sane,
	Insane,
}

@export var card_name: String = "Card Name":
	set(value):
		card_name = value
		_sync_front_visuals()
@export_multiline var description: String = "Card Description":
	set(value):
		description = value
		_sync_front_visuals()
@export var image: Texture2D:
	set(value):
		image = value
		_sync_front_visuals()

@export_category("Card properties")
@export var cost: int = 1
@export var card_type: CardType = CardType.Basic
@export var card_timing: CardTiming = CardTiming.All

## Burned on use.
@export var consumable: bool = false
## Only in deck for current environment.
@export var environment: bool = false
## Burned via actions.
@export var status: bool = false
## Cannot be played
@export var unplayable: bool = false

@export var play_time: float = 0.5

@export_category("Card changes on (in)sanity")
## Enable the change in function when sane/insane
@export var sanity_effect: CardSanityEffect = CardSanityEffect.None
## Change in cost when sanity effect is active.
@export var sanity_effect_cost_delta: int = 0
## Alternate description to show when sanity effect is active (if empty, description won't change)
@export_multiline var sanity_effect_description: String = ""
## Alternate image to show when sanity effect is active (if null, image won't change)
@export var sanity_effect_image: Texture2D

var _sanity_effect_visuals_active: bool = false

# These are set by the Table, which manages the card until it is selected. 
# Once a card is selected, it is down to this card to manage its own state and visuals until it is played or deselected.
# True when we are the currently selected card, about to be played.
var selected: bool = false:
	set(value):
		selected = value
		
# True when the mouse is hovering over this card.
var hovered: bool = false:
	set(value):
		hovered = value

var _in_hand: bool = false
var _burned: bool = false

# Card Lifecycle:
# Idle -> Hovered
# Hovered -> Selected 
# Selected -> Played 
# Selected -> Hovered/Idle (if deselected)
# Played -> Discarded/Burned
# In all cases, the card is responsible for its own play logic
# The table manages top-level visuals - the card can apply additional visuals on top of that
# The card will be centered on the table when it is being played, so it can apply its own visuals without worrying about position

func _ready():
	_sanity_effect_visuals_active = _is_sanity_effect_active()
	_sync_front_visuals()
	if Engine.is_editor_hint():
		return
	$CardArea.mouse_entered.connect(func():
		emit_signal("mouse_hovered", self)
	)
	$CardArea.mouse_exited.connect(func():
		emit_signal("mouse_unhovered", self)
	)
	$CardArea.input_event.connect(func(_viewport, event, _shape_idx):
		# Ignore if we're inactive
		if not is_face_up():
			return
		if event is InputEventMouseButton:
			emit_signal("mouse_event", self, event)
	)
	Global.statistic_changed.connect(func(stat: int, _new_value: int, _old_value: int):
		if stat == Global.Statistic.INSANITY:
			_handle_sanity_effect_change()
		if stat == Global.Statistic.ACTION_POINTS:
			_sync_front_visuals()
	)

func _handle_sanity_effect_change():
	if sanity_effect == CardSanityEffect.None:
		return

	var currently_active = _is_sanity_effect_active()
	if currently_active != _sanity_effect_visuals_active:
		TweenCan.flicker_fn_tween(
			func():
				# On callback - switch to the new visuals
				_sanity_effect_visuals_active = currently_active
				_sync_front_visuals(),
			func():
				# Off callback - switch back to old visuals (in case we stick early)
				_sanity_effect_visuals_active = not currently_active
				_sync_front_visuals(),
			0.8
		)

func _sync_front_visuals():
	var name_label := get_node_or_null("CardFront/Name")
	if name_label:
		name_label.text = card_name

	var description_label := get_node_or_null("CardFront/Description")
	if description_label:
		if _sanity_effect_visuals_active and sanity_effect_description != "":
			description_label.text = sanity_effect_description
		else:
			description_label.text = description

	var image_sprite := get_node_or_null("CardFront/Image")
	if image_sprite:
		if _sanity_effect_visuals_active && sanity_effect_image:
			image_sprite.texture = sanity_effect_image
		else:
			image_sprite.texture = image
	
	var cost_label := get_node_or_null("CardFront/Cost")
	if cost_label:
		if unplayable:
			cost_label.text = "X"
		else:
			var visual_cost = (cost + sanity_effect_cost_delta) if _sanity_effect_visuals_active else cost
			cost_label.text = str(visual_cost)
	
	if Engine.is_editor_hint() || !_in_hand:
		# Not in hand: show card tag
		_set_unplayable_visuals(unplayable)
	else:
		# In hand: show playability
		_set_unplayable_visuals(!is_playable())
	
	if card_timing == CardTiming.All:
		if Global.is_insane():
			$CardBack.frame = 0
			$CardFront/CardFront.frame = 0
			$CardFront/CardFill.frame = 0
		else:
			$CardBack.frame = 3
			$CardFront/CardFront.frame = 3
			$CardFront/CardFill.frame = 3
	elif card_timing == CardTiming.Day:
		$CardBack.frame = 1
		$CardFront/CardFront.frame = 1
		$CardFront/CardFill.frame = 1
	elif card_timing == CardTiming.Night:
		$CardBack.frame = 2
		$CardFront/CardFront.frame = 2
		$CardFront/CardFill.frame = 2


func _do_burn():
	await on_pre_burn()
	_burned = true

	var shaderMaterial = burn_material.duplicate()
	shaderMaterial.set_shader_parameter("progress", -1.5)
	shaderMaterial.set_shader_parameter("direction", randf_range(0, 360))
	self.material = shaderMaterial

	var update_progress = func(value):
		shaderMaterial.set_shader_parameter("progress", value)
	
	var tween := create_tween()
	tween.tween_method(update_progress, -1.5, 1.5, 0.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
	emit_signal("discard", self, true)

	self.queue_free()

func _set_unplayable_visuals(unplayable_: bool):
	if unplayable_ and !is_instance_valid(self.material):
		self.material = unplayable_material
	elif !unplayable_ and self.material == unplayable_material:
		self.material = null

func _do_discard():
	_set_unplayable_visuals(unplayable)
	emit_signal("discard", self, false)

func _is_sanity_effect_active() -> bool:
	if Engine.is_editor_hint():
		return false
	if sanity_effect == CardSanityEffect.None:
		return false
	elif sanity_effect == CardSanityEffect.Sane:
		return !Global.is_insane()
	elif sanity_effect == CardSanityEffect.Insane:
		return Global.is_insane()
	return false

# Action functions called from the table
func action_draw() -> void:
	_in_hand = true
	await on_post_draw()

func action_play():
	Global.change_statistic(Global.Statistic.ACTION_POINTS, -effective_cost())
	var play_timer = get_tree().create_timer(play_time)
	await on_play()
	emit_signal("played", self)
	if play_timer.time_left > 0:
		await play_timer.timeout
	if consumable:
		await _do_burn()
	else:
		await _do_discard()

# Returns true if the card should be discarded, false if the card has been burned
func action_discard() -> bool:
	_in_hand = false
	await on_pre_discard()
	return _burned == false

func is_playable() -> bool:
	if Engine.is_editor_hint():
		return true
	if unplayable:
		return false
	return Global.statistics[Global.Statistic.ACTION_POINTS] >= effective_cost()

func is_valid_at_current_time() -> bool:
	if card_timing == CardTiming.Day:
		return Global.is_daytime()
	elif card_timing == CardTiming.Night:
		return !Global.is_daytime()
	return true

func effective_cost() -> int:
	var ecost = cost
	if _is_sanity_effect_active():
		ecost += sanity_effect_cost_delta
	return max(ecost, 0)

# Action callbacks - these are meant to be overridden by specific cards
func on_post_draw():
	pass

func on_play():
	pass

func on_pre_discard():
	pass

func on_pre_burn():
	pass

# Flip card visuals
func is_face_up():
	return $CardFront.visible

func show_face():
	$CardFront.visible = true
	$CardBack.visible = false

func hide_face():
	$CardFront.visible = false
	$CardBack.visible = true
