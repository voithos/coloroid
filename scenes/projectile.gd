extends Node2D

export var speed = 230
export var projectile_range = 100

var velocity = Vector2.ZERO
var distance = 0.0
var current_cidx = 0
var is_exploding = false

func _ready():
    $explosion.hide()

func fire(vel: Vector2, cidx: int, color: Color, rotate = true):
    velocity = vel
    if rotate:
        rotation = vel.angle()
    current_cidx = cidx
    $hitbox.color_cidx = current_cidx
    modulate = color

func _physics_process(delta):
    if is_exploding:
        return
    position += velocity * speed * delta
    distance += speed * delta
    if distance > projectile_range:
        _lifetime_explode()

func _on_hitbox_area_entered(_area):
    _explode()

func _on_hitbox_body_entered(_body):
    _explode()

func _explode():
    if is_exploding:
        return
    is_exploding = true
    $sprite.hide()
    $explosion.show()
    $explosion/animation.play("normal_explosion")
    yield($explosion/animation, "animation_finished")
    queue_free()

func _lifetime_explode():
    if is_exploding:
        return
    is_exploding = true
    $sprite.hide()
    $explosion.show()
    $explosion/animation.play("lifetime_explosion")
    yield($explosion/animation, "animation_finished")
    queue_free()
