extends Node2D


var PLAYER_CHARACTER_NODE : custom_player_character
var CAMERA_NODE : Camera2D
var UI_NODE : custom_control_node
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _on_ready() -> void:
## Create & Instantiate Dynamic Nodes:
	# Player character
	PLAYER_CHARACTER_NODE = preload("res://Entities/PlayerCharacter/Prototype1/PlayerCharacter01.tscn").instantiate()
	self.add_child(PLAYER_CHARACTER_NODE)
	# Camera
	#CAMERA_NODE = Camera2D.new() #added camera as part of player character scene because lazy right now (I dont know a clean way to setup component values dynamically. Probably want to just make a class for it anyway
	#PLAYER_CHARACTER_NODE.add_child(CAMERA_NODE)
	# UI
	UI_NODE = preload("res://User Interface/UI_Ingame.tscn").instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	UI_NODE.size = get_viewport().size
	UI_NODE.setup(PLAYER_CHARACTER_NODE.special_movement_energy_manager, PLAYER_CHARACTER_NODE) 
	canvas_layer.add_child(UI_NODE)
	
	
	
	
	
	pass # Replace with function body.
