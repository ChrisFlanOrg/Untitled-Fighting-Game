extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var anim_tree = $AnimationTree
@onready var damage_percentage = $DamagePercentageLabel

@export var deviceId : int

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

var has_double_jump = true
var player_damage = 0
var direction = 0

var isJumping = false

func jump(direction):
	if is_on_floor() or has_double_jump:
		if is_on_floor():
			has_double_jump = false
		velocity.x = direction.x*JUMP_VELOCITY
		velocity.y = direction.y*JUMP_VELOCITY
		
func _input(event):
	if event.get_device() == deviceId:
		if event is InputEventJoypadButton:
			if event.is_action_pressed("Jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				isJumping = true
				anim_tree.set("parameters/conditions/jump", true)
			elif event.is_action_pressed("Attack"):
				anim_tree.set("parameters/conditions/attacking", true)
				anim_tree["parameters/playback"].travel("Attack")
				
			if event.is_action_pressed("ui_left"):
				animated_sprite_2d.flip_h = true

			elif event.is_action_pressed("ui_right"):
				animated_sprite_2d.flip_h = false
			
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		elif event is InputEventJoypadMotion:			
			if event.get_axis() == 1:
				if event.get_axis_value() > 0:
					direction = 1
				elif event.get_axis_value() < 0:
					direction = -1
				else:
					direction = 0

func _physics_process(delta):
	print(Input.get_axis("ui_left", "ui_right"))
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor() && isJumping:
		isJumping = false
		anim_tree["parameters/playback"].travel("Grounded")
	else:
		has_double_jump = true

	if direction:
		print(true)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, delta*SPEED)
		
	move_and_slide()

func take_damage(knockback: int, angle: int) -> void:
	player_damage += 10
	velocity.x = ((1 + player_damage / 10) * knockback) * cos(deg_to_rad(angle))
	velocity.y = - ((1 + player_damage / 10) * knockback) * sin(deg_to_rad(angle))
	damage_percentage.text = str(player_damage) + "%"
	
func reset_damage():
	player_damage = 0
	damage_percentage.text = "0%"
