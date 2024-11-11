extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var anim_tree = $AnimationTree

const SPEED = 300.0
const JUMP_VELOCITY = -800.0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim_tree.set("parameters/conditions/jump", true)
	elif Input.is_action_just_pressed("Attack"):
		anim_tree.set("parameters/conditions/attacking", true)
		print("attack")
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
