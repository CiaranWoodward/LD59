@tool
extends BaseCard

const hunk_of_meat_card = preload("res://Cards/HunkOfMeatCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(hunk_of_meat_card.instantiate())
