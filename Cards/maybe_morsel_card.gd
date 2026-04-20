@tool
extends BaseCard

var poisonCard = preload("res://Cards/PoisonCard.tscn")

func on_play():
	var cards_to_burn = Global.table.all_cards().filter(func(c): return c is BaseCard and c.card_name == "Hunger")
	cards_to_burn.shuffle()
	cards_to_burn = cards_to_burn.slice(0, 2)
	for card in cards_to_burn:
		await Global.table.burn_card(card)
	if !Global.is_insane():
		await Global.table.initialise_card_to_discard_pile(poisonCard.instantiate())
