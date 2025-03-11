# scripts/autoload/game_state.gd
extends Node

# Game progress tracking
var campaign_progress := 0
var unlocked_classes := ["Warrior"]
var discovered_relics := []
var completed_quests := []

# Current run state
var current_party := []
var equipped_relics := []
var current_quest = null
var run_stats := {}

# Save/load functionality
func save_game() -> void:
    var save_data := {
        "campaign_progress": campaign_progress,
        "unlocked_classes": unlocked_classes,
        "discovered_relics": discovered_relics,
        "completed_quests": completed_quests
    }
    var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
    file.store_var(save_data)

func load_game() -> bool:
    if not FileAccess.file_exists("user://savegame.save"):
        return false
    
    var file = FileAccess.open("user://savegame.save", FileAccess.READ)
    var save_data = file.get_var()
    
    campaign_progress = save_data.campaign_progress
    unlocked_classes = save_data.unlocked_classes
    discovered_relics = save_data.discovered_relics
    completed_quests = save_data.completed_quests
    
    return true

# Called when starting a new run
func start_new_run() -> void:
    current_party = []
    equipped_relics = []
    current_quest = null
    run_stats = {
        "battles_won": 0,
        "enemies_defeated": 0,
        "staggers_caused": 0
    }