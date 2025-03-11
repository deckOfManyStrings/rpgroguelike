# scripts/components/stagger_component.gd
class_name StaggerComponent
extends Node

signal staggered(entity)
signal stagger_applied(amount, current_value, entity)
signal stagger_reduced(amount, current_value, entity)
signal stagger_state_changed(is_staggered)

# The entity this component is attached to
@onready var entity = get_parent()

# Stagger properties
@export var stagger_value: float = 0.0
@export var stagger_threshold: float = 100.0
@export var stagger_recovery_rate: float = 25.0  # How much stagger reduces per turn when staggered
@export var stagger_decay_rate: float = 5.0  # How much stagger naturally decays per turn when not staggered

# Dictionary of damage type multipliers for weaknesses and resistances
@export var stagger_weaknesses: Dictionary = {
    "slash": 1.0,
    "pierce": 1.0,
    "blunt": 1.0,
    "fire": 1.0,
    "ice": 1.0,
    "lightning": 1.0
}

# Variable to track if this entity is currently staggered
var _is_staggered: bool = false

# Additional stagger modifiers that can be applied by abilities or relics
var incoming_stagger_modifier: float = 1.0
var outgoing_stagger_modifier: float = 1.0

# Effects applied when staggered
var stagger_damage_multiplier: float = 1.5  # 50% more damage when staggered

func _ready():
    # Initialize stagger value to 0
    stagger_value = 0.0
    _is_staggered = false

# Main function to apply stagger to this entity
func apply_stagger(amount: float, damage_type: String = "") -> float:
    # Apply weakness multiplier if damage type is specified
    var multiplier = 1.0
    if damage_type != "" and damage_type in stagger_weaknesses:
        multiplier = stagger_weaknesses[damage_type]
    
    # Apply incoming stagger modifier (from buffs/debuffs)
    var total_stagger = amount * multiplier * incoming_stagger_modifier
    
    # Update stagger value with a cap at 100%
    var old_stagger = stagger_value
    stagger_value = min(stagger_value + total_stagger, stagger_threshold)
    
    # Emit signal for UI updates and relic triggers
    emit_signal("stagger_applied", total_stagger, stagger_value, entity)
    
    # Check if entity has become staggered
    if !_is_staggered and stagger_value >= stagger_threshold:
        become_staggered()
    
    # Return the actual amount of stagger applied
    return stagger_value - old_stagger

# Apply stagger from an attack
func apply_attack_stagger(attacker, ability: Resource, damage_type: String = ""):
    # Get base stagger amount from ability
    var base_stagger = ability.stagger_amount
    
    # Apply attacker's outgoing stagger modifier
    if attacker.has_node("StaggerComponent"):
        base_stagger *= attacker.get_node("StaggerComponent").outgoing_stagger_modifier
    
    # Apply stagger
    apply_stagger(base_stagger, damage_type)

# Called when stagger reaches threshold
func become_staggered() -> void:
    _is_staggered = true
    
    # Trigger visual effect
    if entity.has_method("play_stagger_animation"):
        entity.play_stagger_animation()
    
    # Emit signal for UI updates and relic triggers
    emit_signal("staggered", entity)
    emit_signal("stagger_state_changed", true)
    
    # Alert the battle system
    var battle = entity.get_node_or_null("/root/BattleManager")
    if battle and battle.has_method("on_entity_staggered"):
        battle.on_entity_staggered(entity)

# Called when stagger falls below threshold after being staggered
func recover_from_stagger() -> void:
    _is_staggered = false
    
    # End visual effect
    if entity.has_method("stop_stagger_animation"):
        entity.stop_stagger_animation()
    
    # Emit signal for UI and relic triggers
    emit_signal("stagger_state_changed", false)

# Process stagger reduction at the end of a turn
func process_turn_end() -> void:
    if _is_staggered:
        # Reset stagger to zero after skipping a turn
        reset_stagger()
        recover_from_stagger()
    else:
        # Natural decay when not staggered
        reduce_stagger(stagger_decay_rate)

# Reset stagger value to zero
func reset_stagger() -> void:
    var old_stagger = stagger_value
    stagger_value = 0.0
    
    emit_signal("stagger_reduced", old_stagger, stagger_value, entity)

# Reduce stagger by specified amount
func reduce_stagger(amount: float) -> void:
    var old_stagger = stagger_value
    stagger_value = max(0, stagger_value - amount)
    
    emit_signal("stagger_reduced", old_stagger - stagger_value, stagger_value, entity)

# Get current stagger percentage (0-100)
func get_stagger_percentage() -> float:
    return (stagger_value / stagger_threshold) * 100.0

# Check if entity is currently staggered
func is_staggered() -> bool:
    return _is_staggered

# Calculate damage multiplier based on stagger state
func get_damage_multiplier() -> float:
    if _is_staggered:
        return stagger_damage_multiplier
    return 1.0

# Reset stagger state (e.g., between battles)
func reset() -> void:
    stagger_value = 0.0
    if _is_staggered:
        recover_from_stagger()

# Modify weakness to a specific damage type
func set_weakness(damage_type: String, multiplier: float) -> void:
    stagger_weaknesses[damage_type] = multiplier

# Helper method to set up standard enemy weaknesses
func setup_enemy_weaknesses(primary_weakness: String, secondary_weakness: String = "") -> void:
    # Reset all to base value
    for type in stagger_weaknesses.keys():
        stagger_weaknesses[type] = 1.0
    
    # Set primary weakness (2x stagger)
    stagger_weaknesses[primary_weakness] = 2.0
    
    # Set secondary weakness (1.5x stagger) if specified
    if secondary_weakness != "":
        stagger_weaknesses[secondary_weakness] = 1.5