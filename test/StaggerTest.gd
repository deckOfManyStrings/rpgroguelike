extends Node2D

@onready var test_character = $TestCharacter
@onready var stagger_meter = $UI/UIContainer/StaggerMeter
@onready var stagger_component = $TestCharacter/StaggerComponent

@onready var apply_button = $UI/UIContainer/ApplyStaggerButton
@onready var reduce_button = $UI/UIContainer/ReduceStaggerButton
@onready var damage_type_option = $UI/UIContainer/DamageTypeOption
@onready var camera = $GameCamera

func _ready():
	# Setup damage type options
	damage_type_option.add_item("Slash")
	damage_type_option.add_item("Pierce")
	damage_type_option.add_item("Blunt")
	damage_type_option.add_item("Fire")
	damage_type_option.add_item("Ice")
	damage_type_option.add_item("Lightning")
	
	# Connect the stagger meter to the character
	stagger_meter.track_entity(test_character)
	
	# Connect UI button signals
	apply_button.pressed.connect(_on_apply_button_pressed)
	reduce_button.pressed.connect(_on_reduce_button_pressed)
	
	# Setup test character if needed
	if not test_character.has_method("play_stagger_animation"):
		test_character.set_script(create_test_character_script())
	
	# Setup stagger component for testing
	stagger_component.set_weakness("fire", 2.0)  # Weak to fire
	stagger_component.set_weakness("ice", 0.5)   # Resistant to ice
	
	print("Stagger test initialized!")

func _on_apply_button_pressed():
	var amount = 20.0  # Apply 20% stagger
	var damage_type = damage_type_option.get_item_text(damage_type_option.selected).to_lower()
	
	print("Applying " + str(amount) + " stagger of type: " + damage_type)
	stagger_component.apply_stagger(amount, damage_type)

func _on_reduce_button_pressed():
	var amount = 10.0  # Reduce by 10%
	
	print("Reducing stagger by " + str(amount))
	stagger_component.reduce_stagger(amount)

# Create a minimal script for the test character if needed
func create_test_character_script():
	var script = GDScript.new()
	script.source_code = """
	extends Node2D
	
	# Minimal implementation to work with stagger component
	func play_stagger_animation():
		print("Character staggered!")
		modulate = Color(1.0, 0.5, 0.5)  # Turn red when staggered
	
	func stop_stagger_animation():
		print("Character recovered from stagger!")
		modulate = Color(1.0, 1.0, 1.0)  # Return to normal color
	"""
	script.reload()
	return script
