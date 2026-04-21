@tool
extends BaseCard

const morsel_card = preload("res://Cards/MorselCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(morsel_card.instantiate())
