extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var anim_tree = $AnimationTree

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

var isJumping = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor() && isJumping:
		isJumping = false
		anim_tree["parameters/playback"].travel("Grounded")
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		isJumping = true
		anim_tree.set("parameters/conditions/jump", true)
	elif Input.is_action_just_pressed("Attack"):
		anim_tree.set("parameters/conditions/attacking", true)
		anim_tree["parameters/playback"].travel("Attack")
		
	if Input.is_action_just_pressed("ui_left"):
		animated_sprite_2d.flip_h = true

	elif Input.is_action_just_pressed("ui_right"):
		animated_sprite_2d.flip_h = false
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
