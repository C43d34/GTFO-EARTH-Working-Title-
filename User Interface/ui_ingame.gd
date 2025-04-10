class_name custom_control_node
extends Control

var character_energy_manager_component : EnergyChargingComponent
var player_character : custom_player_character



@onready var shift: Button = $PanelContainer2/GridContainer/HBoxContainer/SHIFT
@onready var w: Button = $PanelContainer2/GridContainer/HBoxContainer/VBoxContainer/VBoxContainer/W
@onready var a: Button = $PanelContainer2/GridContainer/HBoxContainer/VBoxContainer/HBoxContainer/A
@onready var s: Button = $PanelContainer2/GridContainer/HBoxContainer/VBoxContainer/HBoxContainer/S
@onready var d: Button = $PanelContainer2/GridContainer/HBoxContainer/VBoxContainer/HBoxContainer/D
@onready var space: Button = $PanelContainer2/GridContainer/HBoxContainer/VBoxContainer/HBoxContainer2/SPACE


func _init() -> void: 
	character_energy_manager_component = EnergyChargingComponent.new()
	player_character = custom_player_character.new()
	pass
	
func setup(thing : EnergyChargingComponent, pc : custom_player_character) -> void:
	character_energy_manager_component.queue_free()
	character_energy_manager_component = thing
	
	player_character.queue_free()
	player_character = pc
	
	
func _on_ready() -> void:
	pass


func _process(delta: float) -> void:
	
	#TODO: Very bad coupling of with naming
		#Implemenet dynamic interface to player node in the scene (See Autoloaders) 
			#also should use signals or something instead of directly accessing member variables
	$PanelContainer/EnergyCharged.set_value_no_signal(character_energy_manager_component.energy_after_charging)
	$PanelContainer/EnergyCur.set_value_no_signal(character_energy_manager_component.energy_cur)
	
	
	w.remove_theme_color_override("font_color")
	a.remove_theme_color_override("font_color")
	s.remove_theme_color_override("font_color")
	d.remove_theme_color_override("font_color")
	shift.remove_theme_color_override("font_color")
	space.remove_theme_color_override("font_color")
	
	var green = Color(0,1,0)
	if (Input.is_action_pressed("PlayerCharacter_move_up")):
		w.add_theme_color_override("font_color", green)
	if (Input.is_action_pressed("PlayerCharacter_move_left")):
		a.add_theme_color_override("font_color", green)
	if (Input.is_action_pressed("PlayerCharacter_move_down")):
		s.add_theme_color_override("font_color", green)
	if (Input.is_action_pressed("PlayerCharacter_move_right")):
		d.add_theme_color_override("font_color", green)
	if (Input.is_action_pressed("PlayerCharacter_charge")):
		shift.add_theme_color_override("font_color", green)
	if (Input.is_action_pressed("PlayerCharacter_jump")):
		space.add_theme_color_override("font_color", green)
		
	
	pass
	
	
	
	
