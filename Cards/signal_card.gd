@tool
extends BaseCard

func on_play():
	var table = Global.table
	table.get_encounter_screen().activate_random_encounter()
