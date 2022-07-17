extends "res://scenes/enemies/targeting_enemy.gd"

const GRAVITY = 7.5
const TERM_VEL = 100
const FALL_THRESHOLD = 50

func _physics_process(delta):
    if is_on_floor() or (is_upside_down and is_on_ceiling()):
        if !$floor.is_colliding() or $wall.is_colliding():
            facing_left = !facing_left
            _update_flip()

    velocity.x = max_speed * _side_multiplier()
    if !is_upside_down:
        velocity.y = min(TERM_VEL, velocity.y + GRAVITY)
    velocity = move_and_slide(velocity, Vector2.UP)
    
    if target_player:
        _maybe_fall(target_player)
    
func _maybe_fall(player):
    if _is_in_range() and abs(player.global_position.x - global_position.x) < FALL_THRESHOLD:
        is_upside_down = false
        _update_flip()
