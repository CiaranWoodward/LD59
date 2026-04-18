extends Node2D
class_name BaseCard

enum CardType {
    Food,
    Action,
    Debuff
}

enum CardTiming {
    Day,
    Night,
    All
}

@export var cost: int = 1
@export var card_name: String = "Card Name"
@export var description: String = "Card Description"
@export var image: Texture2D
@export var card_type: CardType = CardType.Action
@export var card_timing: CardTiming = CardTiming.All

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