@tool
extends BaseCard

const large_log_card = preload("res://Cards/LargeLogCard.tscn")

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(large_log_card.instantiate()).finished
