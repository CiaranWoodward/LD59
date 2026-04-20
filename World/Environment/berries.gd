extends Node2D

@onready var berries = [$Bush/PickBerry, $Bush/PickBerry2, $Bush/PickBerry3,$Bush/PickBerry4, $Bush/PickBerry5]
var berryCard: PackedScene = preload("res://Cards/ForageBerryCard.tscn")

func activate():
	var num_berries = randi_range(1, 5)
	for berry in range(berries.size()):
		berries[berry].visible = berry < num_berries
		if berries[berry].visible:
			var card: BaseCard = berryCard.instantiate()
			card.played.connect(func(_card) -> void:
				berries[berry].visible = false
			)
			Global.table.initialise_card_to_discard_pile(card)
