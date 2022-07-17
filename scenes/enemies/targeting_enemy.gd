extends "res://scenes/enemies/enemy.gd"

const enemy_projectile_scene = preload("res://scenes/enemies/enemy_projectile.tscn")

var target_player
export (float) var targeting_range = 200
export (float) var firing_frequency = 2.0
var firing_timeout = 0

func _ready():
    call_deferred("_find_player")

func _find_player():
    var player = get_tree().get_nodes_in_group("player")[0]
    target_player = player

func _is_in_range():
    return target_player.global_position.distance_squared_to(global_position) < (targeting_range * targeting_range)

func _update_firing_timeout(delta):
    firing_timeout -= delta

func _is_ready_to_fire():
    return firing_timeout <= 0

func _fire_at_player(player, from=null):
    var projectile = enemy_projectile_scene.instance()
    if !from:
        from = global_position
    var dir = (player.global_position - from).normalized()
    projectile.fire(dir, current_cidx, current_color, false)
    projectile.global_position = from
    _add_sibling_below(projectile)
    
    firing_timeout = firing_frequency
