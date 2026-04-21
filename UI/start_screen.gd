extends Node2D

@export var parallax_strength_far: float = 0.001
@export var parallax_strength_near: float = 0.04
@export var parallax_far_distance_deadzone: float = 300.0
@export var parallax_y_divider: float = 2.0

@export var parallax_spring_stiffness: float = 80.0
@export var parallax_spring_damping: float = 12.0

var _parallax_point: Vector2 = Vector2.ZERO
var _parallax_velocity: Vector2 = Vector2.ZERO
var _current_scene: Node = null
var _suspend_parallax: bool = false

func _ready():
	_bind_meta_position()

# Apply a parallax effect to all props based on a spring-damped point following the mouse
func _process(delta: float) -> void:
	if _suspend_parallax:
		return
	var mouse_target := get_global_mouse_position() - get_viewport().get_visible_rect().size / 2
	var spring_force := (mouse_target - _parallax_point) * parallax_spring_stiffness
	var damping_force := _parallax_velocity * parallax_spring_damping
	_parallax_velocity += (spring_force - damping_force) * delta
	_parallax_point += _parallax_velocity * delta
	var props := get_tree().get_nodes_in_group("Prop")
	props += get_tree().get_nodes_in_group("character")
	for prop in props:
		if prop.has_meta("original_position"):
			var original_position: Vector2 = prop.get_meta("original_position")
			var weight: float = (prop.global_position.y - parallax_far_distance_deadzone) / (get_viewport().get_visible_rect().size.y - parallax_far_distance_deadzone)
			weight = clampf(weight, 0.0, 1.0)
			var parallax_strength := lerpf(parallax_strength_far, parallax_strength_near, weight)
			prop.global_position = original_position + Vector2(_parallax_point.x * parallax_strength, _parallax_point.y * (parallax_strength / parallax_y_divider))

func _bind_meta_position():
	var props = get_tree().get_nodes_in_group("Prop")
	props += get_tree().get_nodes_in_group("character")
	for prop in props:
		if !prop.has_meta("original_position"):
			prop.set_meta("original_position", prop.global_position)
