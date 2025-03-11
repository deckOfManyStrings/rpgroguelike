# scripts/entities/base_character.gd
class_name BaseCharacter
extends Node2D

# Character stats
var stats = {
	"max_hp": 100,
	"current_hp": 100,
	"attack": 10,
	"defense": 5,
	"speed": 5
}

# Reference to class data
var character_class: CharacterClass

# Component references
@onready var stagger_component = $StaggerComponent

# Visual elements
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var effects_container = $EffectsContainer

# Signals
signal damaged(amount, is_critical)
signal healed(amount)
signal died()

func _ready():
	# Initialize with full health
	stats.current_hp = stats.max_hp
	
	# Connect to stagger component signals
	if stagger_component:
		stagger_component.staggered.connect(_on_staggered)
		stagger_component.stagger_state_changed.connect(_on_stagger_state_changed)

# Apply damage to this character
func take_damage(amount, damage_type = "", is_critical = false):
	# Apply defense reduction
	var actual_damage = max(1, amount - stats.defense)
	
	# Apply stagger damage multiplier if staggered
	if stagger_component and stagger_component.is_staggered():
		actual_damage = actual_damage * stagger_component.get_damage_multiplier()
	
	# Apply damage
	stats.current_hp = max(0, stats.current_hp - actual_damage)
	
	# Apply stagger (if stagger component exists)
	if stagger_component:
		stagger_component.apply_stagger(actual_damage * 0.5, damage_type)
	
	# Play hit animation
	if animation_player.has_animation("hit"):
		animation_player.play("hit")
	
	# Emit signal for UI updates
	emit_signal("damaged", actual_damage, is_critical)
	
	# Check if character died
	if stats.current_hp <= 0:
		die()
	
	return actual_damage

# Heal this character
func heal(amount):
	var old_hp = stats.current_hp
	stats.current_hp = min(stats.max_hp, stats.current_hp + amount)
	var actual_heal = stats.current_hp - old_hp
	
	# Play heal animation
	if animation_player.has_animation("heal"):
		animation_player.play("heal")
	
	# Emit signal for UI updates
	emit_signal("healed", actual_heal)
	
	return actual_heal

# Handle death
func die():
	# Play death animation
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	emit_signal("died")

# Animation functions for stagger
func play_stagger_animation():
	if animation_player.has_animation("staggered"):
		animation_player.play("staggered")
    
    # Visual effect temporarily disabled
    # var stagger_effect = load("res://scenes/effects/stagger_effect.tscn").instantiate()
    # effects_container.add_child(stagger_effect)
    
    # Simple visual indicator for testing
	modulate = Color(1.0, 0.5, 0.5)  # Turn red when staggered
	print("Entity staggered!")

func stop_stagger_animation():
	if animation_player.has_animation("staggered_recovery"):
		animation_player.play("staggered_recovery")
    
    # Reset color
	modulate = Color(1.0, 1.0, 1.0)
    
    # Remove stagger effect (commented out for now)
    # for child in effects_container.get_children():
    #     if child.name.begins_with("stagger"):
    #         child.queue_free()

# Signal handlers
func _on_staggered(_entity):
	# Handle any additional effects when this entity becomes staggered
	pass

func _on_stagger_state_changed(is_staggered):
	# Update visual state based on stagger
	if is_staggered:
		# Could change sprite color or add visual effects
		sprite.modulate = Color(1.0, 0.7, 0.7)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0)
