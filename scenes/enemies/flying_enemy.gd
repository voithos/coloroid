extends "res://scenes/enemies/targeting_enemy.gd"

export (float) var acceleration = 100

func _physics_process(delta):
    if target_player and _is_in_range():
        _chase_player(target_player, delta)    

func _chase_player(player, delta):
    var direction = (player.global_position - global_position).normalized()
    velocity += direction * acceleration * delta
    velocity = velocity.clamped(max_speed)
    $sprite.flip_h = global_position > player.global_position
    velocity = move_and_slide(velocity)
