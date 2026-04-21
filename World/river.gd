extends Node2D

var DrinkCardScene: PackedScene = preload("res://Cards/DrinkCard.tscn")

func _ready() -> void:
	Global.current_scene_type = Global.SceneType.RIVER
	Global.table.initialise_card_to_discard_pile(DrinkCardScene.instantiate())