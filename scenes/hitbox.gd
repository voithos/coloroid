extends Area2D

export (float) var damage = 1
export (int) var color_cidx = colors.CWHITE

func _on_hitbox_area_entered(hurtbox):
    hurtbox.emit_signal("hit", damage, color_cidx)
