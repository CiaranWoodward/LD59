extends Node2D

@onready var sticks = [$PickStick, $PickStick2, $PickStick3]
var stickCard: PackedScene = preload("res://Cards/ForageSticksCard.tscn")

func activate():
	var num_sticks = randi_range(1, 3)
	for stick in range(sticks.size()):
		sticks[stick].visible = stick < num_sticks
		if sticks[stick].visible:
			var card: BaseCard = stickCard.instantiate()
			card.played.connect(func(_card) -> void:
				# Fade out with tween
				var tween = create_tween()
				tween.tween_property(sticks[stick], "modulate:a", 0, 0.5)
			)
			Global.table.initialise_card_to_discard_pile(card)
