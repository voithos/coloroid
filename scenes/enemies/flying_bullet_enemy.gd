extends "res://scenes/enemies/flying_enemy.gd"

export (float) var firing_frequency = 2.0

var firing_timeout = 0

func _physics_process(delta):
    if target_player and _is_in_range():
        _fire_at_player(target_player, delta)    

func _fire_at_player(player, delta):
    firing_timeout -= delta
    if firing_timeout <= 0:
        print('pew pew')
        firing_timeout = firing_frequency
