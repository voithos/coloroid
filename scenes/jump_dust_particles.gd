extends Sprite

func _ready():
    pass

func play_once(direction):
    $animation.play(direction)
    yield($animation, "animation_finished")
    queue_free()
