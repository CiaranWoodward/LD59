extends Button

@export_file("*.tscn") var target_scene_path: String

func _ready():
    connect("pressed", _on_pressed.bind())

func _on_pressed():
    if not target_scene_path.is_empty():
        get_tree().change_scene_to_file(target_scene_path)