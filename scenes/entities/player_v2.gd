extends CharacterBody2D

@export var deviceId : int

@export_group("Health")
@onready var damage_percentage = $DamagePercentageLabel
var player_damage := 0

@export_group("Moves")
@export var speed := 200
@export var acceleration := 700
@export var friction := 900
var direction := Vector2.ZERO
var can_move := true

@export_group("Jump")
@export var jump_strength := 300
@export var gravity := 600
@export var terminal_velocity := 500
var jump := false
var faster_fall := false
var gravity_multiplier := 1

func _process(delta):
	apply_gravity(delta)
	
	if can_move:
		#get_input()
		apply_movement(delta)
		
func _input(event):
	if event.get_device() == deviceId:
		# Horizontal Movement
		direction.x = Input.get_axis("Left", "Right")
		
		# Jump
		if Input.is_action_just_pressed("Jump"):
			if is_on_floor() or $Timers/Coyote.time_left:
				jump = true
				
			if velocity.y > 0 and not is_on_floor():
				$Timers/JumpBuffer.start()
				
		if Input.is_action_just_released("Jump") and not is_on_floor() and velocity.y < 0:
			faster_fall = true

func apply_movement(delta):
	# Left/right Movement
	if direction.x:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		
	# Jump
	if jump or $Timers/JumpBuffer.time_left and is_on_floor():
		velocity.y = -jump_strength
		jump = false
		faster_fall = false
		
	var on_floor = is_on_floor()
	move_and_slide()
	if on_floor and not is_on_floor() and velocity.y >= 0:
		$Timers/Coyote.start()
	
func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = velocity.y / 2 if faster_fall and velocity.y < 0 else velocity.y
	velocity.y = velocity.y * gravity_multiplier
	velocity.y = min(velocity.y, terminal_velocity)
	
func take_damage(knockback: int, angle: int) -> void:
	player_damage += 10
	velocity.x = ((1 + player_damage / 10) * knockback) * cos(deg_to_rad(angle))
	velocity.y = - ((1 + player_damage / 10) * knockback) * sin(deg_to_rad(angle))
	damage_percentage.text = str(player_damage) + "%"
	
func reset_damage():
	player_damage = 0
	damage_percentage.text = "0%"
