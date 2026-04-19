@tool
extends Node2D
class_name BaseCard

const burn_material: ShaderMaterial = preload("res://Shaders/BurnMaterial.tres")

# These signals are for communication with the Table, which manages the card until it is selected.
signal mouse_hovered(card: BaseCard)
signal mouse_unhovered(card: BaseCard)
signal mouse_event(card: BaseCard, event: InputEventMouseButton)
signal discard(card: BaseCard, burn: bool)

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

@export var cost: int = 1
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

func _sync_front_visuals():
	var name_label := get_node_or_null("CardFront/Name")
	if name_label:
		name_label.text = card_name

	var description_label := get_node_or_null("CardFront/Description")
	if description_label:
		description_label.text = description

	var image_sprite := get_node_or_null("CardFront/Image")
	if image_sprite:
		image_sprite.texture = image
	
	if unplayable:
		$CardFront.self_modulate = Color(0.8, 0.8, 0.8)
	else:
		$CardFront.self_modulate = Color(1, 1, 1)

func _do_burn():
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

func _do_discard():
	emit_signal("discard", self, false)

# Action functions called from the table
func action_draw() -> void:
	await on_post_draw()

func action_play():
	Global.change_statistic(Global.Statistic.ACTION_POINTS, -cost)
	var play_timer = get_tree().create_timer(play_time)
	await on_play()
	if play_timer.time_left > 0:
		await play_timer.timeout
	if consumable:
		_do_burn()
	else:
		_do_discard()

func action_discard():
	on_pre_discard()

func is_playable():
	if unplayable:
		return false
	return Global.statistics[Global.Statistic.ACTION_POINTS] >= cost

# Action callbacks - these are meant to be overridden by specific cards
func on_post_draw():
	pass

func on_play():
	pass

func on_pre_discard():
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
