extends "res://scenes/enemies/enemy.gd"

var target_player
export (float) var targeting_range = 200

func _ready():
    call_deferred("_find_player")

func _find_player():
    var player = get_tree().get_nodes_in_group("player")[0]
    target_player = player

func _is_in_range():
    return target_player.global_position.distance_squared_to(global_position) < (targeting_range * targeting_range)
