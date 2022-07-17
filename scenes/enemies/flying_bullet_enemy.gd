extends "res://scenes/enemies/flying_enemy.gd"

func _physics_process(delta):
    if target_player and _is_in_range():
        _update_firing_timeout(delta)
        if _is_ready_to_fire():
            _fire_at_player(target_player)
