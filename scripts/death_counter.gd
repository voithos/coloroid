extends Node

# Store for storing number of deaths per level, and totally.

# Note, level names must be unique!
var levels = {}
var saved_levels = {}

func _ready():
    add_to_group("persistable")

func deaths_in_level(level_id) -> int:
    if !levels.has(level_id):
        return 0
    return levels[level_id]

func total_deaths() -> int:
    var deaths = 0
    for level in levels.keys():
        deaths += deaths_in_level(level)
    return deaths

func die():
    # Track current-run deaths separately from saved deaths.
    _increment_death(levels)
    _increment_death(saved_levels)
    # Persist the data.
    saving.save_game()

func _increment_death(store):
    # Can only die in current level, naturally
    var level = _level_name()
    if !store.has(level):
        store[level] = 0
    store[level] += 1

func _level_name():
    return get_tree().get_current_scene().get_name()

func save_state():
    return saved_levels

func load_state(save_data):
    saved_levels = save_data
