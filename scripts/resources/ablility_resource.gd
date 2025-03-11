# scripts/resources/ability_resource.gd
class_name AbilityResource
extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var target_type: String  # "single", "all", "self", "allies"
@export var ability_type: String  # "attack", "heal", "buff", "debuff"
@export var stagger_amount: float
@export var effect_values: Dictionary  # Stores damage multipliers, heal amounts, etc.
@export var cooldown: int = 0
@export var icon_path: String

func execute(actor, targets):
    # Will be implemented in derived ability classes
    pass