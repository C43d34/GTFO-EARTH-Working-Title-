class_name InputProcessing

enum E_movement_states {
	GROUNDED, GROUNDED_ON_WALL, GROUNDED_CROUCH, GROUNDED_ON_WALL_CROUCH,
	ON_WALL, ON_WALL_SLIDING, ON_WALL_CROUCH, ON_WALL_SLIDING_CROUCH, 
	AIRBORNE, AIRBORNE_CROUCH
}



func GetDirectionalInfluence() -> Vector2:
	return Vector2.ONE
	
