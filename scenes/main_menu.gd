extends Node2D

func _ready():
    music.play(music.BACKGROUND)

func _input(event):
    if Input.is_action_just_pressed("jump"):
        var transition = get_tree().get_nodes_in_group("transition")[0]
        transition.connect("fade_complete", self, "_load_main_level")
        transition.begin_fade()

func _load_main_level():
    get_tree().change_scene("res://scenes/levels/main.tscn")
