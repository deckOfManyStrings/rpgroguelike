# scripts/ui/stagger_meter.gd
class_name StaggerMeter
extends Control

# References to UI elements
@onready var stagger_progress = $MarginContainer/VBoxContainer/ProgressBar
@onready var stagger_label = $MarginContainer/VBoxContainer/StaggerLabel 

# Entity that this meter is tracking
var tracked_entity = null

# Colors for different stagger levels
@export var normal_color: Color = Color(0.0, 0.6, 1.0, 1.0)  # Blue
@export var warning_color: Color = Color(1.0, 0.6, 0.0, 1.0)  # Orange
@export var critical_color: Color = Color(1.0, 0.2, 0.2, 1.0)  # Red
@export var staggered_color: Color = Color(0.8, 0.0, 0.0, 1.0)  # Dark Red

# Tweening for smooth updates
var tween = null

func _ready():
	# Initialize progress bar
	stagger_progress.value = 0
	stagger_progress.modulate = normal_color
	stagger_label.text = "0%"

# Connect to an entity's stagger component
func track_entity(entity):
	# Disconnect from previous entity if any
	if tracked_entity and tracked_entity.stagger_component:
		var prev_stagger = tracked_entity.stagger_component
		prev_stagger.stagger_applied.disconnect(_on_stagger_applied)
		prev_stagger.stagger_reduced.disconnect(_on_stagger_reduced)
		prev_stagger.stagger_state_changed.disconnect(_on_stagger_state_changed)
	
	# Set new entity
	tracked_entity = entity
	
	# Connect to new entity signals
	if tracked_entity and tracked_entity.stagger_component:
		var stagger = tracked_entity.stagger_component
		stagger.stagger_applied.connect(_on_stagger_applied)
		stagger.stagger_reduced.connect(_on_stagger_reduced)
		stagger.stagger_state_changed.connect(_on_stagger_state_changed)
		
		# Initialize with current values
		update_meter(stagger.get_stagger_percentage())
		_on_stagger_state_changed(stagger.is_staggered())

# Update the meter display
func update_meter(percentage, animate = true):
	# Ensure stagger doesn't exceed 100%
	percentage = min(percentage, 100.0)
	
	# Cancel existing tween if any
	if tween:
		tween.kill()
	
	# Set color based on percentage
	var new_color
	if percentage >= 100:
		new_color = staggered_color
	elif percentage >= 80:
		new_color = critical_color
	elif percentage >= 50:
		new_color = warning_color
	else:
		new_color = normal_color
	
	# Update text
	stagger_label.text = str(int(percentage)) + "%"
	
	if animate:
		# Create tween for smooth update
		tween = create_tween()
		tween.tween_property(stagger_progress, "value", percentage, 0.3)
		tween.parallel().tween_property(stagger_progress, "modulate", new_color, 0.3)
	else:
		# Instant update
		stagger_progress.value = percentage
		stagger_progress.modulate = new_color

# Signal handlers
func _on_stagger_applied(_amount, current_value, entity):
	if entity != tracked_entity:
		return
		
	var percentage = (current_value / entity.stagger_component.stagger_threshold) * 100.0
	
	# Ensure stagger doesn't exceed 100%
	percentage = min(percentage, 100.0)
	
	# Update meter
	update_meter(percentage)

func _on_stagger_reduced(_amount, current_value, entity):
	if entity != tracked_entity:
		return
		
	var percentage = (current_value / entity.stagger_component.stagger_threshold) * 100.0
	
	# Ensure stagger doesn't exceed 100%
	percentage = min(percentage, 100.0)
	
	update_meter(percentage)

func _on_stagger_state_changed(is_staggered):
	if is_staggered:
		# Make meter pulse when staggered
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(stagger_progress, "modulate:a", 0.7, 0.5)
		pulse_tween.tween_property(stagger_progress, "modulate:a", 1.0, 0.5)
		
		# Add "STAGGERED" text overlay
		stagger_label.text = "STAGGERED!"
	else:
		# Stop pulsing
		if stagger_progress.has_meta("pulse_tween"):
			var pulse_tween = stagger_progress.get_meta("pulse_tween")
			if pulse_tween and pulse_tween.is_valid():
				pulse_tween.kill()
		
		# Update with current value
		if tracked_entity and tracked_entity.stagger_component:
			var percentage = tracked_entity.stagger_component.get_stagger_percentage()
			update_meter(percentage, false)