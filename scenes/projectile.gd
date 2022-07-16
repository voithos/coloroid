extends Node2D

export var speed = 230
export var lifetime = 3

var velocity = Vector2.ZERO

func fire(vel: Vector2):
    velocity = vel
    rotation = vel.angle()

func _physics_process(delta):
    position += velocity * speed * delta
