extends "res://scenes/enemies/flying_enemy.gd"

const enemy_projectile_scene = preload("res://scenes/enemies/enemy_projectile.tscn")

export (float) var firing_frequency = 2.0

var firing_timeout = 0

func _physics_process(delta):
    if target_player and _is_in_range():
        _fire_at_player(target_player, delta)    

func _fire_at_player(player, delta):
    firing_timeout -= delta
    if firing_timeout <= 0:
        var projectile = enemy_projectile_scene.instance()
        var dir = (player.global_position - global_position).normalized()
        projectile.fire(dir, current_cidx, current_color, false)
        projectile.global_position = global_position
        _add_sibling_below(projectile)
        
        firing_timeout = firing_frequency
