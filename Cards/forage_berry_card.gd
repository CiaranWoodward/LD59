@tool
extends BaseCard

const berry_card = preload("res://Cards/BerryCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(berry_card.instantiate()).finished
