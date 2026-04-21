extends Node2D

@onready var sprites = [$Insane/Leaf, $Sane/Limbs]
var searchCard: PackedScene = preload("res://Cards/SearchCard.tscn")

func activate():
	for sprite in sprites:
		sprite.frame = 0
	var card: BaseCard = searchCard.instantiate()
	card.played.connect(func(_card) -> void:
		for sprite in sprites:
			sprite.frame = 1
	)
	Global.table.initialise_card_to_discard_pile(card)
