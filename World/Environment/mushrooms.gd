extends Node2D

@onready var shrooms = [$Log/PickShroom, $Log/PickShroom2, $Log/PickShroom3,$Log/PickShroom4]
var shroomCard: PackedScene = preload("res://Cards/ForageShroomCard.tscn")

func activate():
	var num_shrooms = randi_range(1, 4)
	for shroom in range(shrooms.size()):
		shrooms[shroom].visible = shroom < num_shrooms
		if shrooms[shroom].visible:
			var shroomType = randi_range(0, 3)
			var card: ForageShroomCard = shroomCard.instantiate()
			shrooms[shroom].frame = shroomType
			card.shroom_type = shroomType as ForageShroomCard.ShroomType
			card.played.connect(func(_card) -> void:
				shrooms[shroom].visible = false
			)
			Global.table.initialise_card_to_discard_pile(card)
