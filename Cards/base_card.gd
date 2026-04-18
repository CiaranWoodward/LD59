@tool
extends Node2D
class_name BaseCard

signal mouse_hovered(card: BaseCard)
signal mouse_unhovered(card: BaseCard)
signal clicked(card: BaseCard)

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

##Stays in deck through environment change.
@export var action: bool = false
##Stays in deck through environment change. Burned on use.
@export var consumable: bool = false
##Only in deck for current environment.
@export var environment: bool = false
##Stays in deck through environment change. Burned via actions.
@export var status: bool = false
##Cannot be played
@export var unplayable: bool = false

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
		# Ignore if we're face down
		if !$CardFront.visible:
			return
		if event is InputEventMouseButton and event.pressed:
			emit_signal("clicked", self)
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

# Action callbacks
func on_post_draw():
	pass

func on_play():
	pass

func on_pre_discard():
	pass

func is_playable():
	return true

# Flip card visuals
func show_face():
	$CardFront.visible = true
	$CardBack.visible = false

func hide_face():
	$CardFront.visible = false
	$CardBack.visible = true
