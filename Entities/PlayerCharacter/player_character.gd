extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0



#@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D //static paths are bad idea 
@export var character_collision: CollisionShape2D



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#TODO: Queue jump inputs for "x" number of seconds for smoother experience"
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("PlayerCharacter_jump") or Input.is_action_just_pressed("PlayerCharacter_move_up")) and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		velocity += -1.0 * desired_direction_vector * 300;
		print(desired_direction_vector)
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right") + Input.get_axis("PlayerCharacter_move_left", "PlayerCharacter_move_right")
	# Direction can only be negative (left) or positive (right). Therefore, if we have two ways to move left, (arrow key left + A key) we will end up with "-2" if both are pressed at the same time. 
	#So we must clamp between -1 and 1 to keep velocity math below consistent.
	direction = clamp(direction, -1, 1)
	
	
	if direction: #direction is not 0 
		velocity.x = clamp(direction * SPEED, -SPEED, SPEED)
	else: #no direction, linearly approach x velocity towards zero 
		velocity.x = move_toward(velocity.x, 0, SPEED / 50)

	move_and_slide()


var desired_direction_vector: Vector2
func _process(delta: float) -> void:
	#pass #pass is basically for empty functions. Do nothing
	character_collision.look_at(get_global_mouse_position())
	character_collision.rotate(PI/2) #add extra 90 degree rotation so character faces mouse properly
	desired_direction_vector = self.get_local_mouse_position().normalized()
	queue_redraw() #DEBUG
	
	
func _draw() -> void:
	#have to draw line from ZERO position because draw line happens relative to the node that this is being called from and not from a global position.
	draw_line(Vector2.ZERO, (self.get_local_mouse_position().normalized() * 50), Color(0, 1, 1), 3)
	#print(self.get_local_mouse_position()) #DEBUG
