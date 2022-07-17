extends Particles2D

var timeout = 0
var counter = 0
export (float) var size = 1.0

func _ready():
    amount = int(amount * size * size) # Area is quadratic ;)
    process_material.emission_sphere_radius = process_material.emission_sphere_radius * size
    emitting = true
    one_shot = true
    timeout = lifetime

func _process(delta):
    counter += delta
    if counter >= timeout:
        queue_free()
