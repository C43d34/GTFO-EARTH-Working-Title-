## A State Machine (SM) that processes the next move state transition and any side effects (output velocity) of the entity that this manager is attached to. 

## Could be converted into a MANAGER, but for now this class only handles one entity per instance.
## May refactor into a manager in the future (will handle multiple entities, and only one instance will exist during the game)

extends Node
class_name SM_MoveState

var state_nodes: Array[MoveState_Base]
var current_state: MoveState_Base
var root_node: Node


func _init() -> void:
	pass 

func GetVelocityFromState() -> Vector2:
	return Vector2.ZERO
