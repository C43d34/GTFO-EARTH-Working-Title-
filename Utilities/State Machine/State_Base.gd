extends Node
class_name State_Base

var valid_transition_states : Array[int] #array of enums, but since this is the generic state base, we aren't sure what enum to use so we will leave that up to a base child class to specify

var entity_stats #TODO store a reference to the attached entity's stat block for use in modifying Activation function
var root_node_reference: Node


func _init() -> void:
	pass


func Transition() -> State_Base:
	return null


func Activate() -> Vector2:
	return Vector2.ZERO
	
	
	
	
