# scripts/battle_manager.gd
class_name BattleManager
extends Node

signal turn_started(actor)
signal turn_ended(actor)
signal battle_ended(result)
signal entity_staggered(entity)

enum BattleState {SETUP, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT}

var current_state: BattleState = BattleState.SETUP
var turn_queue: Array = []
var active_actor = null
var party: Array = []
var enemies: Array = []

# Active relics that might respond to battle events
var active_relics: Array = []

func _ready():
    initialize_battle()

func initialize_battle():
    # Get party from GameState
    party = get_node("/root/GameState").current_party.duplicate()
    
    # Load enemies based on current quest
    var quest = get_node("/root/GameState").current_quest
    enemies = quest.get_next_encounter()
    
    # Load active relics
    active_relics = get_node("/root/GameState").equipped_relics
    
    # Initialize turn queue
    build_turn_queue()
    
    # Start first turn
    current_state = BattleState.PLAYER_TURN
    start_next_turn()

func build_turn_queue():
    turn_queue.clear()
    
    # Add all active combatants to queue
    for character in party:
        if character.stats.current_hp > 0:
            turn_queue.append(character)
    
    for enemy in enemies:
        if enemy.stats.current_hp > 0:
            turn_queue.append(enemy)
    
    # Sort by speed
    turn_queue.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)

func start_next_turn():
    if turn_queue.is_empty():
        build_turn_queue()
    
    if turn_queue.is_empty():
        # No entities left that can act - battle should be over
        check_battle_state()
        return
    
    active_actor = turn_queue.pop_front()
    
    # Skip turn if staggered
    if active_actor.stagger_component and active_actor.stagger_component.is_staggered():
        # Process stagger recovery at end of skipped turn
        active_actor.stagger_component.process_turn_end()
        
        # Show "Turn Skipped" message
        $BattleUI.show_status_message(active_actor.name + " is staggered! Turn skipped!")
        
        # Short delay before next turn
        await get_tree().create_timer(1.0).timeout
        start_next_turn()
        return
    
    emit_signal("turn_started", active_actor)
    
    # If enemy, start AI processing
    if active_actor in enemies:
        current_state = BattleState.ENEMY_TURN
        process_enemy_turn()
    else:
        current_state = BattleState.PLAYER_TURN
        # UI will handle player input

func end_turn():
    # Process end of turn effects
    if active_actor.stagger_component:
        active_actor.stagger_component.process_turn_end()
    
    # Process status effects (not shown in this example)
    
    # Trigger any relics that activate at end of turn
    for relic in active_relics:
        if relic.trigger_condition == "end_of_turn":
            relic.apply_effect(self, active_actor)
    
    emit_signal("turn_ended", active_actor)
    check_battle_state()
    
    if current_state == BattleState.PLAYER_TURN or current_state == BattleState.ENEMY_TURN:
        start_next_turn()

func process_enemy_turn():
    # Simple AI for demonstration
    var target = get_random_valid_target(party)
    if not target:
        end_turn()
        return
        
    var ability = active_actor.get_random_ability()
    
    # Show enemy intent
    $BattleUI.show_enemy_intent(active_actor, ability, target)
    
    # Short delay before attack
    await get_tree().create_timer(0.5).timeout
    
    # Use ability on target
    execute_ability(active_actor, ability, [target])
    
    # End turn after a short delay
    await get_tree().create_timer(1.0).timeout
    end_turn()

func get_random_valid_target(target_list):
    var valid_targets = []
    for target in target_list:
        if target.stats.current_hp > 0:
            valid_targets.append(target)
    
    if valid_targets.size() > 0:
        return valid_targets[randi() % valid_targets.size()]
    return null

func execute_ability(actor, ability, targets):
    # Execute the ability
    ability.execute(actor, targets)
    
    # Apply stagger from the ability
    for target in targets:
        if target.stagger_component:
            target.stagger_component.apply_attack_stagger(actor, ability, ability.damage_type)
    
    # Trigger any relics that activate on ability use
    for relic in active_relics:
        if relic.trigger_condition == "on_ability_use":
            relic.apply_effect(self, actor, targets)

# Called when an entity becomes staggered
func on_entity_staggered(entity):
    emit_signal("entity_staggered", entity)
    
    # Trigger any relics that activate on stagger
    for relic in active_relics:
        if relic.trigger_condition == "on_stagger":
            relic.apply_effect(self, entity)
    
    # Check one of your example relic effects:
    # "When an enemy staggers, other enemies gain 50% of that stagger"
    if entity in enemies:
        # Find relic with this effect
        var stagger_spread_relic = active_relics.filter(func(r): return r.id == "stagger_spreader_relic")
        
        if stagger_spread_relic.size() > 0:
            # Apply 50% of stagger threshold to other enemies
            var stagger_amount = entity.stagger_component.stagger_threshold * 0.5
            
            for other_enemy in enemies:
                if other_enemy != entity and other_enemy.stats.current_hp > 0:
                    other_enemy.stagger_component.apply_stagger(stagger_amount)

func check_battle_state():
    # Check if all enemies are defeated
    var all_enemies_defeated = true
    for enemy in enemies:
        if enemy.stats.current_hp > 0:
            all_enemies_defeated = false
            break
    
    if all_enemies_defeated:
        current_state = BattleState.VICTORY
        emit_signal("battle_ended", "victory")
        # Handle victory (rewards, etc.)
        process_victory()
        return
    
    # Check if all party members are defeated
    var all_party_defeated = true
    for character in party:
        if character.stats.current_hp > 0:
            all_party_defeated = false
            break
    
    if all_party_defeated:
        current_state = BattleState.DEFEAT
        emit_signal("battle_ended", "defeat")
        # Handle defeat
        process_defeat()

func process_victory():
    # Update quest progress
    var game_state = get_node("/root/GameState")
    game_state.run_stats.battles_won += 1
    
    # Show victory UI
    $BattleUI.show_victory_screen()
    
    # Enemies defeated count for tracking
    var defeated_count = enemies.size()
    game_state.run_stats.enemies_defeated += defeated_count
    
    # Prepare rewards
    # (implementation not shown)

func process_defeat():
    # Show defeat UI
    $BattleUI.show_defeat_screen()
    
    # Update run statistics
    # (implementation not shown)