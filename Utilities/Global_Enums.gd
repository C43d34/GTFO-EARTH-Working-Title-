class_name GLOBAL_E
	# State
enum movement_states {
	GROUNDED, GROUNDED_ON_WALL, GROUNDED_CROUCH, GROUNDED_ON_WALL_CROUCH, 
	ON_WALL, ON_WALL_SLIDING, ON_WALL_CROUCH, ON_WALL_SLIDING_CROUCH, 
	AIRBORNE, AIRBORNE_CROUCH
} #maybe we can make this Enum less annoying 
	#cannot be grounded & airborne & on wall at same time so they can be their own enum
	#something like...
enum surface_state {
	GROUNDED, ON_WALL, AIRBORNE
}
enum special_move_states {
	NONE,
	CROUCH, 
	SLIDING, SLIDING_CROUCH,  
	HOVER,
	DASHING
}
