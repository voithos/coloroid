extends RigidBody2D

export (int) var heal_amount = 1

func _ready():
    pass # Replace with function body.

func _on_area_area_entered(area):
    area.emit_signal("heal", heal_amount)
    queue_free()
