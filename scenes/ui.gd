extends CanvasLayer

const heart_scene = preload("res://scenes/heart.tscn")

func _ready():
    call_deferred("setup_listeners")

const HEART_OFFSET = 20
var heart_nodes = []

func setup_listeners():
    var players = get_tree().get_nodes_in_group("player")
    assert(len(players) == 1)
    var player = players[0]
    
    for n in $hp_ui.get_children():
        $hp_ui.remove_child(n)
        n.queue_free()

    for i in range(player.MAX_HEALTH):
        var heart = heart_scene.instance()
        $hp_ui.add_child(heart)
        heart.position.x = i * HEART_OFFSET
        heart_nodes.append(heart)

    player.connect("health_changed", self, "on_health_changed")

func on_health_changed(health, max_health):
    for i in range(heart_nodes.size()):
        heart_nodes[i].filled = i < health
    
func _process(delta):
    #$mana.value = lerp($mana.value, mana_percent, 0.4)
    pass
