extends KinematicBody2D

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

func _side_multiplier():
    return (1 - 2*int(facing_left))
    
func _ready():
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
    # "Correct" color does double damage by default
    var multiplier = 1.0
    if current_cidx != colors.CWHITE:
        if color_cidx == current_cidx:
            multiplier = 2.0
        else:
            multiplier = 0.5
    set_health(health - damage * multiplier)
    print(health)
    _maybe_start_flash()

func _maybe_start_flash():
    if $sprite.material:
        $tween.interpolate_method(self, "_interpolate_flash", 0.0, 1.0, FLASH_DURATION, Tween.TRANS_QUAD)
        $tween.start()

func _interpolate_flash(progress):
    var intensity = min(progress * 2.0, 1.0) - max((progress - 0.5) * 2, 0)
    $sprite.material.set_shader_param("flash_intensity", intensity)

func die():
    queue_free()

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

func _update_shader_params():
    if $sprite.material:
        $sprite.material.set_shader_param('outline_color', current_color)
