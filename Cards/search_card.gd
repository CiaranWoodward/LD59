@tool
extends BaseCard

var maybeMorsel = preload("res://Cards/MaybeMorselCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(maybeMorsel.instantiate())