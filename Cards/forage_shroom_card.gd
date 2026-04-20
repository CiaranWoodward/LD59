@tool
extends BaseCard

const blue_shroom_card = preload("res://Cards/BlueShroomCard.tscn")
const grey_shroom_card = preload("res://Cards/GreyShroomCard.tscn")
const purple_shroom_card = preload("res://Cards/PurpleShroomCard.tscn")
const red_shroom_card = preload("res://Cards/RedShroomCard.tscn")

# TODO gain random available mushroom
# TODO remove resource from environment

func on_play():
	var table = Global.table
	await table.initialise_card_to_discard_pile(blue_shroom_card.instantiate()).finished
	
