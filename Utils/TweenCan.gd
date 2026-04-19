extends Object
class_name TweenCan

static func pulse_tween(target: Node2D, pulse_time: float) -> Tween:
    var tween = target.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(target, "scale", Vector2(1.5, 1.5), pulse_time / 2).set_ease(Tween.EASE_OUT)
    tween.tween_property(target, "scale", Vector2(1, 1), pulse_time / 2).set_ease(Tween.EASE_IN)
    return tween