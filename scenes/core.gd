tool
extends Area2D

export (int) onready var color_cidx = 1

func set_color(cidx: int):
    color_cidx = cidx
    $glow.modulate = colors.COLORS[cidx]
    # Subtract 1 since we don't have a face for CWHITE.
    $face.frame_coords.x = cidx-1

func _ready():
    set_color(color_cidx)

func _on_core_body_entered(body):
    body.gain_color(color_cidx)
    queue_free()
