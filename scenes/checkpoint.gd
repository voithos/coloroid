extends Sprite

var is_reached = false
export var is_exit = false

func _ready():
    add_to_group("checkpoints")

func _on_area_area_entered(area):
    if is_exit:
        var level = get_tree().get_nodes_in_group("level")[0]
        level.begin_next_level_transition()
        return

    if !is_reached:
        # We need some special logic when we're spawning at a checkpoint.
        var is_spawning = false
        if checkpoint_store.has_checkpoint() and checkpoint_store.get_checkpoint() == global_position:
            is_spawning = true
        
        checkpoint_store.set_checkpoint(global_position)
        $animation.play("reached")
        is_reached = true
        
        if !is_spawning:
            #sfx.play(sfx.CHECKPOINT)
            pass
