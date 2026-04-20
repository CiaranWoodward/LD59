extends Node2D

@export var existence_chance: float = 0.5

func _ready() -> void:
	if randf() > existence_chance:
		visible = false
		queue_free()
	else:
		visible = true
		# pick a random child to make visible and activate
		var children = get_children()
		if children.size() > 0:
			var random_child = children[randi() % children.size()]
			for child in children:
				child.visible = child == random_child
				if child.visible and child.has_method("activate"):
					child.activate()
