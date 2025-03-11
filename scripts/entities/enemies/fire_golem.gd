# scripts/entities/enemies/fire_golem.gd
class_name FireGolem
extends BaseCharacter

func _ready():
    # Call parent ready function
    super()
    
    # Set base stats
    stats = {
        "max_hp": 200,
        "current_hp": 200,
        "attack": 15,
        "defense": 8,
        "speed": 3
    }
    
    # Set up specific weaknesses for this enemy type
    # Fire Golem is weak to ice (2x stagger) and blunt (1.5x stagger)
    # but resistant to fire (0.5x stagger)
    stagger_component.setup_enemy_weaknesses("ice", "blunt")
    stagger_component.set_weakness("fire", 0.5)  # Resistant to fire
    
    # Higher stagger threshold for bosses (optional)
    if is_boss:
        stagger_component.stagger_threshold = 150.0

# Override the staggered handler for custom behavior
func _on_staggered(_entity):
    # Custom behavior when staggered
    # For example, fire golems might lose their flame shield when staggered
    $FlameShield.visible = false
    
    # Play a specific sound effect
    $StaggerSound.play()
    
    # Maybe drop some items
    if randf() < 0.3:  # 30% chance
        drop_item("fire_essence")

# Custom enemy attack behavior
func perform_attack(target):
    # Choose an attack based on current state
    var attack_name = "fire_blast"
    
    # If low health, use stronger attack
    if stats.current_hp < stats.max_hp * 0.3:
        attack_name = "flame_eruption"
    
    # If staggered, can only use weak attack
    if stagger_component.is_staggered():
        attack_name = "ember_flick"
    
    # Execute the selected attack
    match attack_name:
        "fire_blast":
            # Regular attack
            var damage = stats.attack * 1.2
            target.take_damage(damage, "fire")
            
        "flame_eruption":
            # Powerful attack with animation
            animation_player.play("flame_eruption")
            await animation_player.animation_finished
            var damage = stats.attack * 2.0
            target.take_damage(damage, "fire")
            
        "ember_flick":
            # Weak attack when staggered
            var damage = stats.attack * 0.5
            target.take_damage(damage, "fire")