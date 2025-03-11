# scripts/resources/relic_resource.gd
class_name RelicResource
extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var rarity: String  # Common, Uncommon, Rare, Epic
@export var trigger_condition: String  # "on_stagger", "on_attack", etc.
@export var effect_description: String
@export var unlock_condition: String
@export var icon_path: String

# This will be used for the actual implementation of the relic effect
func apply_effect(battle_scene, actor, target = null):
    # Will be overridden in specific relic implementations
    pass