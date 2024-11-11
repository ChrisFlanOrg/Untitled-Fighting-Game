extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

var has_double_jump = true

func _ready():
	animated_sprite_2d.play("idle")

func jump(direction):
	if is_on_floor() or has_double_jump:
		if is_on_floor():
			has_double_jump = false
		velocity.x = direction.x*JUMP_VELOCITY
		velocity.y = direction.y*JUMP_VELOCITY

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		has_double_jump = true
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, delta*SPEED)
	move_and_slide()
