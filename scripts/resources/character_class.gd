# scripts/resources/character_class.gd
class_name CharacterClass
extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var base_stats: Dictionary = {
    "max_hp": 100,
    "attack": 10,
    "defense": 5,
    "speed": 5
}
@export var abilities: Array[AbilityResource]
@export var unlock_condition: String
@export var sprite_path: String