class_name custom_player_character
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
var ambient_accumulated_forces: Vector2 = Vector2.ZERO #stores accumulated forces that is applied as a velocity instance to the character each frame (Gravity, for example)

### Linking movement component
#@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D //static paths are bad idea ...
@export var character_collision: CollisionShape2D
#@onready var area_circle: Area2D = $AreaCircle
@export var area_circle: Area2D 
@export var area_collision_circle: CollisionShape2D


### Movement Parameters
@export_category("Movement Parameters")
@export var _walk_speed: float = 1 ## Speed affects how quick the player gets to max speed
@export var _max_walk_speed: float = 1 
@export var _air_speed: float = 1 
@export var _max_air_speed: float = 1
@export var _jump_strength: float = 1
@export var _crouch_strength: float = 1
@export var _gravity_strength: float = 1
@export var _friction_strength: float = 1 ## Friction affects how quickly the player slows down when no input is given
@export var _air_friction_strength: float = 1

# Params
var cur_walk_speed: float
var cur_max_walk_speed: float
var cur_air_speed: float
var cur_max_air_speed: float
var cur_jump_strength: float
var cur_gravity_strenth: float
var cur_friction_strength: float
var cur_crouch_strength: float
var cur_air_friction_strength: float

# State
enum E_movement_states {
	GROUNDED, GROUNDED_ON_WALL, GROUNDED_CROUCH, GROUNDED_ON_WALL_CROUCH, 
	ON_WALL, ON_WALL_SLIDING, ON_WALL_CROUCH, ON_WALL_SLIDING_CROUCH, 
	AIRBORNE, AIRBORNE_CROUCH
} #maybe we can make this Enum less annoying 
	#cannot be grounded & airborne & on wall at same time so they can be their own enum
	#something like...
enum E_surface_state {
	GROUNDED, ON_WALL, AIRBORNE
}
enum E_special_move_states {
	NONE,
	CROUCH, 
	SLIDING, SLIDING_CROUCH,  
	HOVER,
	DASHING
}
var current_surface_state : E_surface_state = 0 # default: GROUNDED
var current_movement_state: E_special_move_states = 0 #default: NONE
#var current_movement_state : InputProcessing.E_movement_states = 0 #default: GROUNDED
var time_since_last_crouch: float = 0
var time_since_last_grounded : float = 0
var time_since_last_jump_input : float = 0
# Wall sliding experiments
var b_started_sliding: bool = false
var last_collided_wall : Object = null
var current_sliding_wall: Area2D = null

# Player Input
enum E_player_inputs {
	UP, DOWN,
	LEFT, RIGHT,
	SHIFT, SPACE
}
var x_axis_influence_current : float = 0 # 64 bits for tracking directional influence could be overkill if it is only binary
var y_axis_influence_current : float = 0 # 64 bits for tracking directional influence could be overkill if it is only binary
#var directional_influence: Vector2 = Vector2(0, 0) 
var is_crouching : bool = false ## DEPRECATED



### Register Components
@onready var special_movement_energy_manager: EnergyChargingComponent = $SpecialMovementEnergyManager #we can connect to signals that this node may fire out during runtime 
@onready var character_body_2d: custom_player_character = $"."
@onready var character_sprite: Sprite2D = $CollisionShape2D/CharacterSprite


### Signals
signal notify_we_sliding(old_val: bool, cur_val: bool)


func _on_ready() -> void:
# Parameter Initializations 
	cur_walk_speed = _walk_speed
	cur_max_walk_speed = _max_walk_speed
	cur_air_speed = _air_speed
	cur_max_air_speed = _max_air_speed
	cur_friction_strength = _friction_strength
	cur_gravity_strenth = _gravity_strength
	cur_jump_strength = _jump_strength
	cur_crouch_strength = _crouch_strength
	cur_air_friction_strength = _air_friction_strength
	
	t = Timer.new()
	t.one_shot = true
	self.add_child(t)

func _physics_process(delta: float) -> void:
	debug_this_vector = Vector2.ZERO			
	
	
	
#Resolve current movement state that the player is in
	var player_inputs_this_frame : Array[E_player_inputs] = ReadPlayerInputs() #Wonder how much performance impact long term there is from reading data only to pack into an array to randomly read again. DICTIONARY faster if lots of random reads.  
	self.current_surface_state = ResolveSurfaceState()
	self.current_movement_state = ResolveSpecialMoveState(current_surface_state, player_inputs_this_frame)

#Consume player inputs to do something with it
	var directional_influence : Vector2 = Vector2(x_axis_influence_current, y_axis_influence_current) #if we have any influence on the axes, consume it and reset it to zero to be process next physics frame. Should be careful about how we use this influence variable because it could be rewritten multiple times between physics frames. Will be bad if it accumulates multiple instances of the same influence  
	#x_axis_influence_current = 0.0
	#y_axis_influence_current = 0.0
	if (player_inputs_this_frame.has(E_player_inputs.LEFT)): 
		directional_influence.x = -1.0
	elif (player_inputs_this_frame.has(E_player_inputs.RIGHT)):
		directional_influence.x = 1.0
		
	var player_request_jump : bool = player_inputs_this_frame.has(E_player_inputs.SPACE) #TODO some function that will handle timing player jump (coyote time) 
	var player_request_crouch : bool = player_inputs_this_frame.has(E_player_inputs.DOWN)


#Establish constant forces on the player based on states
	#var inv_friction_coefficient_ambient: Vector2 = Vector2(1.0, 1.0) #inverted coefficient (higher = less friction) 
	var friction_coefficient : Vector2 = Vector2( 1.0, 1.0 ) #higher = more friction
	if (current_movement_state == E_special_move_states.HOVER):
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		
	#Dampen Dash Technology
	elif (current_movement_state == E_special_move_states.DASHING):
		directional_influence = Vector2(x_axis_influence_current, y_axis_influence_current) #override directional influence with just the influence from dashing. No inputs from user. Kind of don't like this code. Would like to utilize directional influence from user input part of the code and disable it if we are dashing. 
		
		cur_max_air_speed = lerp(cur_max_air_speed, _max_air_speed, 1 - (t.time_left/t.wait_time))
		cur_max_walk_speed = lerp(cur_max_walk_speed, _max_walk_speed, 1 - (t.time_left/t.wait_time))
		
		#Movement calculation during dashing
		velocity.x += delta * (directional_influence.x * cur_max_air_speed)
		velocity.y += delta * (directional_influence.y * cur_max_air_speed)
		velocity += get_gravity() * delta * cur_gravity_strenth
		debug_this_vector = velocity #DEBUG
		velocity = velocity.normalized() * clamp(velocity.length(), -1.0 * cur_max_air_speed, cur_max_air_speed) 
		#print(velocity.length(), " ", cur_max_air_speed) #DEBUG
			
		
	elif (current_surface_state == E_surface_state.GROUNDED):
		friction_coefficient *= cur_friction_strength
		friction_coefficient.x -= cur_crouch_strength * int(player_request_crouch)  #if crouch is true it's crouch_strength * 1 else * 0 
		if (player_request_jump):
			directional_influence.y = -1.0 
		
	#Handle X influences
		#velocity.x += delta * (cur_walk_speed * directional_influence.x) if not is_zero_approx(directional_influence.x) else delta * (velocity.x * -1.0 * inv_friction_coefficient_ambient.x) #accelerate or deccelerate 
		#velocity.x = clamp(velocity.x, -1.0 * cur_max_walk_speed * delta, cur_max_walk_speed * delta)   
			## Delta time above is somewhat uncessary, move_and_slide() implicitly multiplies delta_time to velocity vector so I guess we are gucci? 
			## In addition, physics frame rate is capped at 60fps. So unless major dips are happening in game, physics should be consistent on most devices 
			## However, I think we still need delta time when it comes to the acceleration and decceleration factors. 
				#On max speeds it is uncessary I guess
		velocity.x += delta * (cur_walk_speed * directional_influence.x) if not is_zero_approx(directional_influence.x) else delta * -1.0 * (velocity.x * friction_coefficient.x) #accelerate or deccelerate
		#friction 10 is good ^
		#velocity.x = velocity.x + (delta * (cur_walk_speed * directional_influence.x)) if not is_zero_approx(directional_influence.x) else (move_toward(velocity.x, 0, friction_coefficient.x)) #friction 50 is good ^
		velocity.x = clamp(velocity.x, -1.0 * cur_max_walk_speed, cur_max_walk_speed) 
		
	#Handle Y influences	
		velocity.y += cur_jump_strength * directional_influence.y
		velocity += get_gravity() * delta * cur_gravity_strenth
		
		#print(velocity, " ", cur_walk_speed, " ", cur_max_walk_speed, " ",  velocity / delta) ##DEBUG 

	elif ((current_movement_state == E_special_move_states.SLIDING or current_movement_state == E_special_move_states.SLIDING_CROUCH)):
		current_sliding_wall = connected_wall_sliders.get(connected_wall_sliders.size() - 1) #get last wall slider we added to the array (assuming it is the most relevant wall to slide on right now)
		
		friction_coefficient = Vector2(0.0, 0.5) #we'll just use the y component for this for now. 
		velocity = (get_gravity() * delta * cur_gravity_strenth) / friction_coefficient.y #(can we do sliding by manipulating gravity instead?)
		velocity = ComputeVelocityFromSliding(velocity, current_sliding_wall)	
		
		debug_this_vector = velocity #DEBUG	

	else: # ASSUME AIRBORNE SURFACE STATE 
		friction_coefficient *= cur_air_friction_strength
		
	#Handle X influences
		velocity.x += delta * (cur_air_speed * directional_influence.x) if directional_influence.x != 0.0 else delta * -1.0 * (velocity.x * friction_coefficient.x) #accelerate or deccelerate 
		velocity.x = clamp(velocity.x, -1.0 * cur_max_walk_speed, cur_max_walk_speed) 
		
	#Handle Y influences
		velocity += get_gravity() * delta * cur_gravity_strenth




		

		
	
	#if (current_movement_state == E_movement_states.GROUNDED and is_crouching):
		#inv_friction_coefficient_ambient = 1.5
	#elif (current_movement_state == E_movement_states.AIRBORNE):
		#velocity += get_gravity() * delta
	#else:
		#velocity += get_gravity() * delta
#
#
	#
	## Handle jump.
	##TODO: Queue jump inputs for "x" number of seconds for smoother experience"
	#if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("PlayerCharacter_jump") or Input.is_action_just_pressed("PlayerCharacter_move_up")) and (is_on_floor() or b_started_sliding) :
		##velocity.y = JUMP_VELOCITY
		#velocity += -1.0 * desired_direction_vector * 650;
		#if (b_started_sliding):
			#b_started_sliding = false
	#
	#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right") + Input.get_axis("PlayerCharacter_move_left", "PlayerCharacter_move_right")
	## Direction can only be negative (left) or positive (right). Therefore, if we have two ways to move left, (arrow key left + A key) we will end up with "-2" if both are pressed at the same time. 
	##So we must clamp between -1 and 1 to keep velocity math below consistent.
	#direction = clamp(direction, -1, 1) 
	#
	#
	#
	#if b_started_sliding:
		#velocity.x = velocity.x #0 friction no slowdown but also no directional input
	#elif direction: #direction is not 0 
		#velocity.x = clamp(direction * SPEED, -SPEED, SPEED)
	#else: #no direction, linearly approach x velocity towards zero 
		#velocity.x = move_toward(velocity.x, 0, SPEED / 10)

	move_and_slide()


var desired_direction_vector: Vector2
var debug_this_vector: Vector2
func _process(delta: float) -> void:
	var player_inputs_this_frame: Array[E_player_inputs] = ReadPlayerInputs()
	desired_direction_vector = self.get_local_mouse_position().normalized()
	
	var expended_energy: float = 0
	if (player_inputs_this_frame.has(E_player_inputs.SHIFT)): 
		if (!special_movement_energy_manager.b_charging and t.is_stopped()): #bandaid fix checking timer not stopped to indicate that we are in the middle of dashing so do not dash again 
		#Start charging using energy
			special_movement_energy_manager.StartCharging()
			
			print(special_movement_energy_manager.energy_after_charging, " ", special_movement_energy_manager.energy_cur) #DEBUG
		
		elif(special_movement_energy_manager.b_charging): 
		#Release charge and expend energy
		
			print(special_movement_energy_manager.energy_after_charging," ",  special_movement_energy_manager.energy_cur) #DEBUG
			expended_energy = special_movement_energy_manager.EndCharging()
			
			
			ExecuteDash(expended_energy) 

	#character_collision.look_at(get_global_mouse_position())
	#character_collision.rotate(PI/2) #add extra 90 degree rotation so character faces mouse properly
	if (player_inputs_this_frame.has(E_player_inputs.RIGHT)):
		character_sprite.flip_h = false
	elif (player_inputs_this_frame.has(E_player_inputs.LEFT)):
		character_sprite.flip_h = true
	
	
	queue_redraw() #DEBUG
	
	
func _draw() -> void:
	#have to draw line from ZERO position because draw line happens relative to the node that this is being called from and not from a global position.
	draw_line(Vector2.ZERO, (self.get_local_mouse_position().normalized() * 50), Color(0, 1, 1), 3)
	draw_line(Vector2.ZERO, debug_this_vector.normalized() * 100, Color(1, 0, 1), 3)
	#print(self.get_local_mouse_position()) #DEBUG



func GetMovementState() -> E_movement_states: ## Returns the current movement state of the character based on physics state
	
	if (is_on_wall_only() and velocity.y > -50): #on a wall and close to falling (positive y is falling gOdot why the fu,....)
		#check if we are connected to any wall sliders while we are on only a wall (wall collisions are defined by up_direction and floor_max_angle)
		var active_wall_sliders: int = connected_wall_sliders.size()
		if active_wall_sliders > 0:
			notify_we_sliding.emit(b_started_sliding, true)
			return E_movement_states.ON_WALL_SLIDING
		
		#DEBUG
		var collision: KinematicCollision2D = self.get_last_slide_collision()
		if (collision.get_collider() != last_collided_wall):
			last_collided_wall = collision.get_collider()
			print("New Wall Collided with at: ", last_collided_wall.global_position, " (Wall's origin point, not the collision point)") #DEBUG
		#DEBUG
		
		return E_movement_states.ON_WALL
		
	elif (is_on_floor()):
		return E_movement_states.GROUNDED
	
	else:
		return E_movement_states.AIRBORNE



func ResolveSpecialMoveState(last_known_surface_state: E_surface_state, active_player_inputs: Array[E_player_inputs]) -> E_special_move_states: ## Based on Physics readings this tick & current surface state, compute and return value of the given state enum. Should be called once each physics tick.
	var final_special_move_state : E_special_move_states = 0 #DEFAULT = NONE
	
	
	if (!t.is_stopped()): #timer to dash was activated I suppose!
		final_special_move_state = E_special_move_states.DASHING
	
	elif (special_movement_energy_manager.b_charging): #we are charging special movement state I suppose!
		final_special_move_state = E_special_move_states.HOVER
	
	elif 	((last_known_surface_state == E_surface_state.ON_WALL and self.velocity.y > -50) or b_started_sliding): #on a wall and close to falling (positive y is falling gOdot why the fu,....)
	#check if we are connected to any wall sliders while we are on only a wall (wall collisions are defined by up_direction and floor_max_angle)
		var active_wall_sliders: int = connected_wall_sliders.size()
		if active_wall_sliders > 0:
			notify_we_sliding.emit(b_started_sliding, true)
			final_special_move_state = E_special_move_states.SLIDING_CROUCH if active_player_inputs.has(E_player_inputs.DOWN) else E_special_move_states.SLIDING
		
		
		#DEBUG
		#var collision: KinematicCollision2D = self.get_last_slide_collision()
		#if (collision.get_collider() != last_collided_wall):
			#last_collided_wall = collision.get_collider()
			#print("New Wall Collided with at: ", last_collided_wall.global_position, " (Wall's origin point, not the collision point)") #DEBUG
		#DEBUG
		
	elif (active_player_inputs.has(E_player_inputs.DOWN)):
		final_special_move_state = E_special_move_states.CROUCH
		
	
	return final_special_move_state


func ResolveSurfaceState() -> E_surface_state: ## Based on Physics readings this tick, compute and return values of the entity's state: Returns [E_surface_state, E_special_move_states]. Should be called once each physics tick
	var final_surface_state: E_surface_state = 0 #DEFAULT = GROUNDED
	
	if (is_on_wall_only()): 
		final_surface_state = E_surface_state.ON_WALL
	elif (is_on_floor()):
		final_surface_state = E_surface_state.GROUNDED
	else:
		final_surface_state = E_surface_state.AIRBORNE
	
	return final_surface_state
		
		
func ReadPlayerInputs() -> Array[E_player_inputs]: ## Reads player inputs and packs them into an array of E_Player_inputs to be processed by physics tick function. Should be called only once per Physics Tick. MAY NEED TO CALL GETMOVEMENTSTATE BEFORE AND AFTER THIS FUNCTION BECAUSE IT COULD CHANGE MOVEMENT STATE (or accept being 1 frame late) 
	var input_source = Input
	var active_inputs : Array[E_player_inputs] = []
	
	if (input_source.is_action_pressed("PlayerCharacter_move_down")):
		active_inputs.append(E_player_inputs.DOWN)
		
	if (input_source.is_action_just_pressed("PlayerCharacter_move_up")):
		active_inputs.append(E_player_inputs.UP)
		
	if (input_source.is_action_just_pressed("PlayerCharacter_jump")):
		active_inputs.append(E_player_inputs.SPACE)
	
	if (input_source.is_action_just_pressed("PlayerCharacter_charge")):
		active_inputs.append(E_player_inputs.SHIFT)
	elif (input_source.is_action_just_released("PlayerCharacter_charge")): #need to make letting go of shift and enabling shift differnet states cause it matters for sure 
		active_inputs.append(E_player_inputs.SHIFT)
	
	var directional_influence: int = input_source.get_axis("ui_left", "ui_right") + input_source.get_axis("PlayerCharacter_move_left", "PlayerCharacter_move_right")
	if (directional_influence < 0):
		active_inputs.append(E_player_inputs.LEFT)
	elif (directional_influence > 0):
		active_inputs.append(E_player_inputs.RIGHT)
	
	
	return active_inputs



		
func ComputeVelocityFromSliding(current_velocity: Vector2, wall_to_slide_from: Area2D) -> Vector2:
	var velocity_for_sliding: Vector2 = current_velocity #dampen velocity a little bit since we slideey
	
# Use currently active wall slider to do some sliding
	#get wall slider angle and adjust current velocity to be along that angle 
	# (project the would be velocity vector onto the vector in the direction of the sliding)
	var sliding_rotation_degrees: float = current_sliding_wall.global_rotation_degrees
		# 0 means sliding wall points straight down
		# 180 means sliding points straight up
			# Therefore, we are expecting sliding rotation to be somewhere 0 < "x" < 90  or 270 < "x" < 360 
		#subtract 90 degrees to make the range continuous (180 < "x" < "360") and the trig math is just easier really 
			# now 270 (same as 0 - 90) degrees means straight down (think unit circle)
			# 180 or 360 is purely horizontal 
	sliding_rotation_degrees -= 90.0
	sliding_rotation_degrees = sliding_rotation_degrees if sliding_rotation_degrees >= 0 else (sliding_rotation_degrees + 360.0)
	if ((sliding_rotation_degrees >= 180 and sliding_rotation_degrees <= 360)): 
	#Scale X and Y component of velocity to match the direction of sliding rotation
		#Opt 1: Project current velocity onto direction of sliding. 
		velocity_for_sliding = velocity_for_sliding.project(Vector2.from_angle(deg_to_rad(sliding_rotation_degrees)))  #TODO: check the angle here because I think x is facing in the wrong direction which is why it's not sticking


		#Opt 2: Custom math that uses Y velocity component (gravity mostly) to drive sliding 
			#If the wall goes straight down, currently velocity direction is unchanged (just goes straight down)
			#As the wall becomes more horizontal, current velocity direction shifts to horizontal, but gets weaker until purely horizontal
		#velocity_for_sliding = velocity_for_sliding.rotated(deg_to_rad(sliding_rotation_degrees)) * sin(deg_to_rad(sliding_rotation_degrees)) #TODO: check rotated function I dont think you are using this how you think you want it to be used 
		
		
		#print("sliding vec magnitude (before scaling): ", velocity_for_sliding.length()) #DEUBG
		#print("degrees_of_surface: ", sliding_rotation_degrees) #DEBUG
		
	velocity_for_sliding = velocity_for_sliding.normalized() * clamp(velocity_for_sliding.length(), 0, 100)
	return velocity_for_sliding


var t : Timer
func ExecuteDash(dash_strength: float) -> void:
	## Could consider adding a movement state for this action 
	var dash_dir : Vector2 = desired_direction_vector
	x_axis_influence_current = dash_dir.x * dash_strength
	y_axis_influence_current = dash_dir.y * dash_strength
	print (dash_dir, dash_strength)
	cur_max_air_speed *= clamp(dash_strength / 5, 0, 10)
	cur_max_walk_speed *= clamp(dash_strength / 5, 0, 10)
	
	if (!t.timeout.is_connected(FinishDash)):
		t.timeout.connect(FinishDash.bind(dash_strength)) #we have to rebind this everytime because the value of dash strength is different! (But onyl if we care about using dash strength tho. Or we can just make this variable accessible globally, or do some sort of signal magic? 
	
	t.start(0.3)
	
	pass


func FinishDash(dash_strength: float) -> void:
	x_axis_influence_current = 0.0
	y_axis_influence_current = 0.0
	cur_max_air_speed = _max_air_speed
	cur_max_walk_speed = _max_walk_speed
	
	t.timeout.disconnect(FinishDash) #we have to rebind this everytime because the value of dash strength is different! (But onyl if we care about using dash strength tho. Or we can just make this variable accessible globally, or do some sort of signal magic? 
	print("WehA! ", dash_strength)
	pass
	
	
	
var connected_wall_sliders: Array = [] #small array that shouldn't have more that ~5 or so object references EVER
									#contains references ColliderWallSlider objects that were overlapped by this character's area2D volume
func _on_area_circle_area_entered(area: Area2D) -> void:
	if area is ColliderWallSliderArea: #hate this check because if we refactor class name we are cooked for real
		#any wallslider areas we find, we add them to a list of currently contacted walls
		connected_wall_sliders.append(area) 
		

func _on_area_circle_area_exited(area: Area2D) -> void:
	if area is ColliderWallSliderArea:
		var connected_wall_slider_index: int = connected_wall_sliders.find(area) 
		if (connected_wall_slider_index == connected_wall_sliders.size() - 1):
			# Since we use the LAST stored wall slider as the wall to slide against, if that is the one we removed, then we can assume we are no longer sliding
				#this only makes sense because we can only slide in one direction (which is down). If we could slide up & down it would cause a problem. 
			notify_we_sliding.emit(b_started_sliding, false)
			
		connected_wall_sliders.remove_at(connected_wall_slider_index)
			
			
	
func _on_notify_we_sliding(old_val: bool, cur_val: bool) -> void:
	#if state of sliding went from false to true we can do some stuff
	if not old_val and cur_val:
		#self.velocity.y = 0 #set reset y velocity to zero 
		self.velocity = Vector2(0,0)
	
	b_started_sliding = cur_val
	
	
@onready var camera_2d: Camera2D = $Camera2D
func GetCamera() -> Camera2D:
	return camera_2d
	
