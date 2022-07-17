tool
extends Sprite

export (bool) var filled = true setget set_filled

func _ready():
    pass

func set_filled(f):
    filled = f
    frame = 0 if filled else 1
