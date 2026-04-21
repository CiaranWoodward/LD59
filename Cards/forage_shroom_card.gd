@tool
extends BaseCard
class_name ForageShroomCard

enum ShroomType {
	Blue,
	Grey,
	Purple,
	Red
}

const blue_shroom_card = preload("res://Cards/BlueShroomCard.tscn")
const grey_shroom_card = preload("res://Cards/GreyShroomCard.tscn")
const purple_shroom_card = preload("res://Cards/PurpleShroomCard.tscn")
const red_shroom_card = preload("res://Cards/RedShroomCard.tscn")

var shroom_type = ShroomType.Blue

func on_play():
	var table = Global.table
	var card_to_add: BaseCard
	match shroom_type:
		ShroomType.Blue:
			card_to_add = blue_shroom_card.instantiate()
		ShroomType.Grey:
			card_to_add = grey_shroom_card.instantiate()
		ShroomType.Purple:
			card_to_add = purple_shroom_card.instantiate()
		ShroomType.Red:
			card_to_add = red_shroom_card.instantiate()
	await table.initialise_card_to_discard_pile(card_to_add)
	
