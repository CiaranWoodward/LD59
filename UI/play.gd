extends Button

@export var base_scene: PackedScene

func _on_pressed():
    if base_scene:
        get_tree().change_scene_to_packed(base_scene)