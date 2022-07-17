extends Node2D

export var speed = 230
export var projectile_range = 100

var velocity = Vector2.ZERO
var distance = 0.0
var current_cidx = 0

func fire(vel: Vector2, cidx: int, color: Color):
    velocity = vel
    rotation = vel.angle()
    current_cidx = cidx
    $hitbox.color_cidx = current_cidx
    modulate = color

func _physics_process(delta):
    position += velocity * speed * delta
    distance += speed * delta
    if distance > projectile_range:
        queue_free()

func _on_hitbox_area_entered(_area):
    _explode()

func _on_hitbox_body_entered(_body):
    _explode()

func _explode():
    queue_free()
