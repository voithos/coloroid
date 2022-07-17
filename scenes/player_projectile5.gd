extends "res://scenes/projectile.gd"

func _lifetime_explode():
    # Disabled for this type of projectile
    return
    
func _done_animating():
    queue_free()
