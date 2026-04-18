extends Object
class_name WaitAllTweens

signal done
var remaining := 0

func _oneDone():
    remaining -= 1
    if remaining == 0:
        emit_signal("done")

# Utility function to wait for an array of tweens to all finish
static func wait_all_tweens(tweens: Array[Tween]) -> void:
    if tweens.is_empty():
        return

    var signaler := WaitAllTweens.new()
    signaler.remaining = tweens.size()

    for tween in tweens:
        tween.parallel()
        tween.finished.connect(func():
            signaler._oneDone()
        , CONNECT_ONE_SHOT)

    await signaler.done