extends "res://scenes/enemies/targeting_enemy.gd"

func _ready():
    $animation.play("idle")

func _physics_process(delta):
    if target_player and _is_in_range():
        _update_firing_timeout(delta)
        if _is_ready_to_fire():
            # Has a timed fire
            $animation.play("fire")
    else:
        $animation.play("idle")

func _actually_fire():
    # Just check again to be safe
    if target_player and _is_in_range():
        if _is_ready_to_fire():
            _fire_at_player(target_player, $firing_point.global_position)
