extends KinematicBody2D
class_name Player

const dust_scene = preload("res://scenes/jump_dust_particles.tscn")
const projectile_scene = preload("res://scenes/player_projectile.tscn")

var velocity = Vector2.ZERO
var previous_velocity = Vector2.ZERO

const HORIZONTAL_VEL = 100.0
const HORIZONTAL_ACCEL = 15 # How quickly we accelerate to max speed

const GRAVITY = 7.5
const GRAVITY_DECREASE_THRESHOLD = 10 # The speed below which gravity is decreased.
const GRAVITY_DECREASE_MULTIPLIER = 0.5 # The amount of decrease for low gravity (at the height of a jump).
const JUMP_VEL = 220
const TERM_VEL = JUMP_VEL * 2
const FAST_FALL_MULTIPLIER = 1.7 # How much faster fast fall is compared to gravity
const JUMP_SIDE_DUST_SPEED = 20 # Speed after which we emit "side" jump particles
const LAND_DUST_SPEED = 80 # Speed after which we emit dust in the landed state

const JUMP_RELEASE_MULTIPLIER = 0.5 # Multiplied by velocity if button released

const MAX_HEALTH = 10
var health = MAX_HEALTH
signal health_changed

export (bool) var facing_left = true
var is_dying = false
var is_moving = false
var is_rolling = false
var is_airborne = false
var was_airborne = false
var is_fast_falling = false

# Rolling
const ROLL_HORIZONTAL_VEL = 300.0 # Burst roll speed
const ROLL_HORIZONTAL_DECEL = 5 # How quickly the roll decelerates
const ROLL_TIME = 0.3
var roll_timer = 0

# Squash and stretch
var squash_stretch_scale = Vector2.ONE
const JUMP_SQUASH_STRETCH = Vector2(0.8, 1.2)
const LAND_SQUASH_STRETCH = Vector2(1.3, 0.7)
const SQUASH_LERP_SPEED = 10

var is_controllable = true

const WALK_SFX_COOLDOWN = 0.3 # seconds
var walk_sfx_cooldown = 0

export (Array, int) var has_colors = []
var current_cidx: int = colors.CWHITE
var prev_cidx: int = current_cidx
var current_color: Color = colors.COLORS[colors.CWHITE]

func _ready():
    randomize()
    add_to_group("player")

    _maybe_jump_to_checkpoint()
    
    _update_sprite_flip()
    
    if len(has_colors) > 0:
        _set_color(has_colors[0])
    
    # Initial animation.
    is_controllable = false

    # Wait a little bit extra to allow the transition to complete fading in
    yield(get_tree().create_timer(0.2), "timeout")
    
    is_controllable = true
    $animation.play("idle")

func _maybe_jump_to_checkpoint():
    if checkpoint_store.has_checkpoint():
        global_position = checkpoint_store.get_checkpoint()

func _update_offset():
    $sprite.offset = Vector2(0, -6)
    $sprite.position = Vector2(0, 6)
    
func _set_color(c: int):
    prev_cidx = current_cidx
    current_cidx = c
    current_color = colors.COLORS[c]

func _process(delta):
    _update_shader_params()

func _physics_process(delta):
    _maybe_die()
    
    _animate_squash_stretch(delta)
    _animate_roll(delta)

    if !is_controllable:
        return

    if Input.is_action_just_pressed("restart"):
        die()
        return
    
    if Input.is_action_just_pressed("attack"):
        fire()

    _move_player(delta)
    
    _update_sprite_flip()
    _walk_sfx(delta)

    if Input.is_action_just_pressed("roll"):
        roll(delta)

func fire():
    var projectile =  projectile_scene.instance()
    var invec = _get_8dir_input_vector()
    projectile.fire(invec)
    projectile.global_position = global_position
    projectile.modulate = current_color
    _add_sibling_below(projectile)

func roll(delta):
    is_rolling = true
    is_controllable = false
    $animation.play("roll")
    velocity.x = ROLL_HORIZONTAL_VEL * (1 - 2*int(facing_left))
    roll_timer = 0.0
    _set_color(colors.CWHITE)
    if is_on_floor():
        _create_dust(false)

func _animate_roll(delta):
    if is_rolling:
        velocity.x = lerp(velocity.x, HORIZONTAL_VEL * sign(velocity.x), ROLL_HORIZONTAL_DECEL * delta)
        _move_with_gravity(velocity, 1.0)
        roll_timer += delta
        
        if roll_timer >= ROLL_TIME:
            _stop_roll()

func _stop_roll():
    is_rolling = false
    is_controllable = true
    $animation.play('idle')
    _maybe_pick_random_color()
            
func _maybe_pick_random_color():
    if len(has_colors) == 0:
        return
    # This always picks a new color
    var cidx
    while true:
        cidx = has_colors[randi()%len(has_colors)]
        if cidx != prev_cidx:
            break
    _set_color(cidx)

func _animate_squash_stretch(delta):
    _update_offset()
    if is_airborne and velocity.y < 0:
        _apply_jump_squash_stretch()
    else:
        # We could actually use delta here, but we don't have to.
        # https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
        var lerp_val = SQUASH_LERP_SPEED * delta
        assert(lerp_val <= 1.0)
        squash_stretch_scale.x = lerp(squash_stretch_scale.x, 1.0, lerp_val)
        squash_stretch_scale.y = lerp(squash_stretch_scale.y, 1.0, lerp_val)
    $sprite.scale = squash_stretch_scale

func _update_shader_params():
    $sprite.material.set_shader_param('outline_color', current_color)
    # These don't work correctly
    #$sprite.material.set_shader_param('skip_top', is_on_ceiling())
    #$sprite.material.set_shader_param('skip_bottom', is_on_floor())

func _apply_jump_squash_stretch():
    squash_stretch_scale.x = range_lerp(abs(velocity.y), 0, JUMP_VEL, 1.0, JUMP_SQUASH_STRETCH.x)
    squash_stretch_scale.y = range_lerp(abs(velocity.y), 0, JUMP_VEL, 1.0, JUMP_SQUASH_STRETCH.y)
    $sprite.scale = squash_stretch_scale
    
func _move_player(delta):
    was_airborne = is_airborne
    
    var target_horizontal = 0
    var fall_multiplier = 1.0
    is_moving = false

    if Input.is_action_pressed("move_left"):
        target_horizontal -= HORIZONTAL_VEL
        is_moving = true
    if Input.is_action_pressed("move_right"):
        target_horizontal += HORIZONTAL_VEL
        is_moving = true

    if Input.is_action_just_pressed("jump") and is_on_floor():
        _jump()
    
    if target_horizontal != 0:
        facing_left = target_horizontal < 0

    # Apply gravity and fast falling
    if is_airborne and Input.is_action_just_released("jump"):
        is_fast_falling = true
        if velocity.y < 0:
            velocity.y *= JUMP_RELEASE_MULTIPLIER

    if is_fast_falling:
        fall_multiplier = FAST_FALL_MULTIPLIER

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta)
    _move_with_gravity(velocity, fall_multiplier)

    if was_airborne and is_on_floor():
        # Landed.
        is_airborne = false
        _landed()
    elif !was_airborne and !is_on_floor():
        # Fell off a cliff.
        is_airborne = true

    if !is_airborne:
        if is_moving:
            $animation.play("run")
        else:
            $animation.play("idle")

func _move_with_gravity(new_vel, fall_multiplier):
    # When we're near the top of the jump, decrease gravity.
    var grav_multiplier = 1.0 if is_fast_falling or abs(new_vel.y) > GRAVITY_DECREASE_THRESHOLD else GRAVITY_DECREASE_MULTIPLIER
    new_vel.y = min(TERM_VEL, new_vel.y + GRAVITY * grav_multiplier * fall_multiplier)

    previous_velocity = new_vel
    velocity = move_and_slide(new_vel, Vector2.UP)

# TODO: Should this just be 4dir?
func _get_8dir_input_vector():
    var x = 0
    var y = 0
    if Input.is_action_pressed("move_left"):
        x -= 1
    if Input.is_action_pressed("move_right"):
        x += 1

    if Input.is_action_pressed("move_up"):
        y -= 1
    if Input.is_action_pressed("move_down"):
        y += 1
        
    if x == 0 and y == 0:
        x = -1 + 2 * int(not facing_left)
    return Vector2(x, y).normalized()

func _jump():
    is_airborne = true
    is_fast_falling = false
    velocity.y = -JUMP_VEL
    sfx.play(sfx.JUMP, sfx.EXTRA_QUIET_DB)
    $animation.play("jump")
    _apply_jump_squash_stretch()

    # Create the dust animation
    _create_dust()

func _landed():
    if previous_velocity.y > LAND_DUST_SPEED:
        # Set the squash/stretch scales based on the landing speed.
        squash_stretch_scale.x = clamp(range_lerp(previous_velocity.y, 0, JUMP_VEL, 1.0, LAND_SQUASH_STRETCH.x), 1.0, LAND_SQUASH_STRETCH.x)
        squash_stretch_scale.y = clamp(range_lerp(previous_velocity.y, 0, JUMP_VEL, 1.0, LAND_SQUASH_STRETCH.y), LAND_SQUASH_STRETCH.y, 1.0)

        _create_dust(true)
        # The walk sound works well as a landed sound.
        sfx.play(sfx.WALK, sfx.QUIET_DB)

func _create_dust(is_landing=false):
    var dust =  dust_scene.instance()
    dust.flip_h = not facing_left
    dust.global_position = global_position
    _add_sibling_above(dust)
    
    if is_landing:
        dust.play_once("land")
    # Play different animations based on horizontal speed
    elif abs(velocity.x) > JUMP_SIDE_DUST_SPEED:
        dust.play_once("side")
    else:
        dust.play_once("up")

# Adds a sibling node above the player.
func _add_sibling_above(node):
    var parent = get_parent()
    parent.add_child(node)
    parent.move_child(node, get_index())

func _add_sibling_below(node):
    var parent = get_parent()
    parent.add_child(node)
    parent.move_child(node, get_index()+1)

func set_health(h):
    health = min(max(0, h), MAX_HEALTH)
    emit_signal("health_changed", health, MAX_HEALTH)
    if health <= 0:
        die()

func _update_sprite_flip():
    $sprite.flip_h = facing_left

func _walk_sfx(delta):
    if !is_on_floor() or !is_moving:
        walk_sfx_cooldown = 0
        return

    if walk_sfx_cooldown <= 0:
        sfx.play(sfx.WALK, sfx.QUIET_DB)
        walk_sfx_cooldown = WALK_SFX_COOLDOWN
    if walk_sfx_cooldown > 0:
        walk_sfx_cooldown -= delta

func _on_hurtbox_area_entered(_area):
    die()

func _on_hurtbox_body_entered(_body):
    die()

func die():
    if is_dying: return
    is_dying = true
    is_controllable = false
    death_counter.die()
    
    $animation.play("death")
    sfx.play(sfx.DEATH)
    global_camera.shake(0.5, 30, 3)
    yield($animation, "animation_finished")
    var level = get_tree().get_nodes_in_group("level")[0]
    level.begin_reset_transition()
    

const ABYSS_DEATH_THRESHOLD_Y = 1500
func _maybe_die():
    # Special case handling in case the player falls off the edge of the world.
    if position.y > ABYSS_DEATH_THRESHOLD_Y:
        die()
