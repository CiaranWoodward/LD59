extends Node2D

func _ready():
	pass#_test_animation()

func _test_animation():
	# Delay 4 seconds
	$TestEnvironmental.visible = false
	await get_tree().create_timer(4.0).timeout
	var tween = TweenCan.fly_on_tween($TestEnvironmental, 1.0)
	await tween.finished
	await get_tree().create_timer(4.0).timeout
	var tween2 = TweenCan.fly_off_tween($TestEnvironmental, 1.0)
	await tween2.finished


