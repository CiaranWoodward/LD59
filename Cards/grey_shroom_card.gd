@tool
extends BaseCard

func on_play():
	var all_cards = Global.table.all_cards()
	var status_cards_in_hand = Global.table.hand.filter(func(c): return c is BaseCard and c.status)

	# If we only have one status card in hand, that shouldn't be the one we burn for hunger
	var ignore_card = null;
	if status_cards_in_hand.size() == 1:
		ignore_card = status_cards_in_hand[0]

	var cards_to_burn = Global.table.all_cards().filter(func(c): return c is BaseCard and c.card_name == "Hunger" and c != ignore_card)
	cards_to_burn.shuffle()
	cards_to_burn = cards_to_burn.slice(0, 1)
	ignore_card = cards_to_burn.get(0)

	var cards_to_burn_hand = Global.table.hand.filter(func(c): return c is BaseCard and c.status and c != ignore_card)
	cards_to_burn_hand.shuffle()
	cards_to_burn_hand = cards_to_burn_hand.slice(0, 1)

	for card in cards_to_burn:
		await Global.table.burn_card(card)
	for card in cards_to_burn_hand:
		await Global.table.burn_card(card)
