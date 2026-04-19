extends Object
class_name TweenCan

static func pulse_tween(target: Node2D, pulse_time: float) -> Tween:
    var tween = target.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(target, "scale", Vector2(1.5, 1.5), pulse_time / 2).set_ease(Tween.EASE_OUT)
    tween.tween_property(target, "scale", Vector2(1, 1), pulse_time / 2).set_ease(Tween.EASE_IN)
    return tween

static func flicker_fn_tween(flicker_on_fn: Callable, flicker_off_fn: Callable, flicker_time: float) -> Tween:
    var flicker_interval_target := 0.06
    var min_flickers := 3
    var max_flickers_cap := 10
    var off_weight_start := 2.1
    var off_weight_end := 0.7
    var on_weight_start := 0.35
    var on_weight_end := 0.1
    var segment_randomness_min := 0.7
    var segment_randomness_max := 1.3

    var scene_tree := Engine.get_main_loop() as SceneTree
    var tween := scene_tree.create_tween()

    if flicker_time <= 0.0:
        tween.tween_callback(flicker_on_fn)
        return tween

    var max_flickers := clampi(int(ceil(flicker_time / flicker_interval_target)), min_flickers, max_flickers_cap)
    var flicker_count := randi_range(min_flickers, max_flickers)
    var segment_count := flicker_count * 2 - 1
    var total_weight := 0.0
    var segment_weights: Array[float] = []

    for segment_index in range(segment_count):
        var progress := float(segment_index) / maxf(float(segment_count - 1), 1.0)
        var is_off_segment := segment_index % 2 == 0
        var base_weight := lerpf(off_weight_start, off_weight_end, progress) if is_off_segment else lerpf(on_weight_start, on_weight_end, progress)
        var weight := base_weight * randf_range(segment_randomness_min, segment_randomness_max)
        segment_weights.append(weight)
        total_weight += weight

    tween.tween_callback(flicker_off_fn)

    for segment_index in range(segment_count):
        var duration := flicker_time * (segment_weights[segment_index] / total_weight)
        tween.tween_interval(duration)

        if segment_index % 2 == 0:
            tween.tween_callback(flicker_on_fn)
        else:
            tween.tween_callback(flicker_off_fn)
    return tween



static func flicker_tween(target: Node2D, flicker_time: float) -> Tween:
    return flicker_fn_tween(
        func ():
            target.visible = true,
        func ():
            target.visible = false,
        flicker_time
    )
    