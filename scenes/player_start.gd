extends Node2D

export (bool) var active = false

func _ready():
    if active and OS.is_debug_build():
        yield(get_tree(), "idle_frame")
        var player = get_tree().get_nodes_in_group("player")[0]
        player.position = position
