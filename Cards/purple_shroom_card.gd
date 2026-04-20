@tool
extends BaseCard

const poison_card = preload("res://Cards/PoisonCard.tscn")

func on_play():
	var cards_to_burn = Global.table.all_cards().filter(func(c): return c is BaseCard and c.card_name == "Hunger")
	cards_to_burn.shuffle()
	cards_to_burn = cards_to_burn.slice(0, 1)
	for card in cards_to_burn:
		await Global.table.burn_card(card)
	
	await Global.table.initialise_card_to_discard_pile(poison_card.instantiate())
	

	
