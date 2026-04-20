@tool
extends BaseCard

const wood_card = preload("res://Cards/WoodCard.tscn")

# TODO remove resource from environment

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(wood_card.instantiate())
