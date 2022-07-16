extends KinematicBody2D
class_name Player

var velocity = Vector2.ZERO
var previous_velocity = Vector2.ZERO

const HORIZONTAL_VEL = 75.0
const HORIZONTAL_ACCEL = 20 # How quickly we accelerate to max speed

const GRAVITY = 6.0
const GRAVITY_DECREASE_THRESHOLD = 10 # The speed below which gravity is decreased.
const GRAVITY_DECREASE_MULTIPLIER = 0.5 # The amount of decrease for low gravity (at the height of a jump).
const JUMP_VEL = 160
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
var is_airborne = false
var was_airborne = false
var is_fast_falling = false

# Squash and stretch
var squash_stretch_scale = Vector2.ONE
const JUMP_SQUASH_STRETCH = Vector2(0.8, 1.2)
const LAND_SQUASH_STRETCH = Vector2(1.5, 0.4)
const SQUASH_LERP_SPEED = 10

var is_controllable = true

const WALK_SFX_COOLDOWN = 0.3 # seconds
var walk_sfx_cooldown = 0

func _ready():
    add_to_group("player")

    _maybe_jump_to_checkpoint()
    
    _update_sprite_flip()
    
    # Initial animation.
    is_controllable = false

    # Wait a little bit extra to allow the transition to complete fading in
    yield(get_tree().create_timer(0.2), "timeout")
    
    is_controllable = true
    $animation.play("idle")

func _maybe_jump_to_checkpoint():
    if checkpoint_store.has_checkpoint():
        global_position = checkpoint_store.get_checkpoint()

func _physics_process(delta):
    _maybe_die()
    
    _animate_squash_stretch(delta)

    if !is_controllable:
        return

    if Input.is_action_just_pressed("restart"):
        die()
        return

    _move_player(delta)
    
    _update_sprite_flip()
    _walk_sfx(delta)

func _animate_squash_stretch(delta):
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

    # When we're nearing the top of the jump, decrease gravity.
    var grav_multiplier = 1.0 if is_fast_falling or abs(velocity.y) > GRAVITY_DECREASE_THRESHOLD else GRAVITY_DECREASE_MULTIPLIER
    velocity.y = min(TERM_VEL, velocity.y + GRAVITY * grav_multiplier * fall_multiplier)

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta)

    previous_velocity = velocity
    velocity = move_and_slide(velocity, Vector2.UP)
    
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
    var dust = preload("res://scenes/jump_dust_particles.tscn").instance()
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
