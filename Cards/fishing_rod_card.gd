@tool
extends BaseCard

const fish_card = preload("res://Cards/FishCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(fish_card.instantiate())
