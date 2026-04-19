@tool
extends BaseCard

func on_post_draw():
    Global.change_statistic(Global.Statistic.ACTION_POINTS, -1)
    await TweenCan.pulse_tween($CardFront, 0.5).finished