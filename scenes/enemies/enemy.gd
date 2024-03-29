extends KinematicBody2D

const explosion_scene = preload("res://scenes/enemy_explosion.tscn")
const hp_pickup_scene = preload("res://scenes/hp_pickup.tscn")

export (float) var max_health = 1.0
onready var health = max_health

export (int) var max_speed = 15
var velocity = Vector2.ZERO

export (bool) var facing_left = false
export (bool) var is_upside_down = false

export (int) var current_cidx: int = colors.CWHITE
var prev_cidx: int = current_cidx
var current_color: Color = colors.COLORS[colors.CWHITE]

const FLASH_DURATION = 0.15

export (float) var death_particles_size = 1.0
export (Vector2) var death_particles_offset = Vector2.ZERO

export (float) var hp_pickup_chance = 0.5

func _side_multiplier():
    return (1 - 2*int(facing_left))
    
func _ready():
    randomize()
    _update_flip()
    _set_color(current_cidx)
    _duplicate_materials()

func _duplicate_materials():
    if $sprite.material:
        $sprite.material = $sprite.material.duplicate()

func set_health(value):
    health = clamp(value, 0, max_health)
    if health == 0:
        die()

func _on_hurtbox_hit(damage, color_cidx):
    do_damage(damage, color_cidx)

func do_damage(damage, color_cidx):
    var multiplier = 1.0
    if current_cidx == colors.CWHITE:
        #sfx.play(sfx.OUCH, sfx.QUIET_DB)
        pass
    else:
        # "Correct" color does double damage by default
        if color_cidx == current_cidx:
            multiplier = 2.0
            #sfx.play(sfx.OUCH, sfx.QUIET_DB)
        else:
            multiplier = 0.5
            #sfx.play(sfx.OUCH_WEAK, sfx.QUIET_DB)
    set_health(health - damage * multiplier)
    _maybe_start_flash()

func _maybe_start_flash():
    if $sprite.material:
        $tween.interpolate_method(self, "_interpolate_flash", 0.0, 1.0, FLASH_DURATION, Tween.TRANS_QUAD)
        $tween.start()

func _interpolate_flash(progress):
    var intensity = min(progress * 2.0, 1.0) - max((progress - 0.5) * 2, 0)
    $sprite.material.set_shader_param("flash_intensity", intensity)

func die():
    var explosion = explosion_scene.instance()
    explosion.size = death_particles_size
    explosion.global_position = global_position + Vector2(death_particles_offset.x * _side_multiplier(), death_particles_offset.y)
    _add_sibling_below(explosion)
    _maybe_emit_hp_pickup()
    queue_free()

func _maybe_emit_hp_pickup():
    if randf() < hp_pickup_chance:
        var hp_pickup = hp_pickup_scene.instance()
        _add_sibling_below(hp_pickup)
        hp_pickup.global_position = global_position
        hp_pickup.add_central_force(Vector2(rand_range(-45, 45), rand_range(-40, -150)))

func _set_color(c: int):
    prev_cidx = current_cidx
    current_cidx = c
    current_color = colors.COLORS[c]

func _process(delta):
    _update_shader_params()
    
func _physics_process(delta):
    _update_flip()

func _update_flip():
    # Flipping via scale doesn't work :\
    # https://github.com/godotengine/godot/issues/12335
    var x_axis = global_transform.x
    global_transform.x.x = (-1 if facing_left else 1) * abs(x_axis.x)
    var y_axis = global_transform.y
    global_transform.y.y = (-1 if is_upside_down else 1) * abs(y_axis.y)
        

func _update_shader_params():
    if $sprite.material:
        $sprite.material.set_shader_param('outline_color', current_color)

# Adds a sibling node above the player.
func _add_sibling_above(node):
    var parent = get_parent()
    parent.add_child(node)
    parent.move_child(node, get_index())

func _add_sibling_below(node):
    var parent = get_parent()
    parent.call_deferred("add_child", node)
    parent.call_deferred("move_child", node, get_index()+1)
