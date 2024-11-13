extends Area2D

# Signal to notify that player has died
signal player_died

# Reference to the player node (you can set this in the editor)
@export var player: Node2D

# Respawn position for the player (you can set this in the editor)
@export var respawn_position: Node2D

@export var deathParticle : PackedScene

# Trigger when something enters the boundary
func _on_body_entered(body) -> void:
	# Check if the body is the player
	if body.is_in_group("player"):
		# Kill the player (reset their position and handle death logic)
		print("Player entered boundary")
		kill_player(body)

# Function to "kill" the player by resetting their position
func kill_player(body) -> void:
	var _particle = deathParticle.instantiate()
	_particle.position = body.position
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
	
	# You can add additional death logic here, such as resetting health, playing animations, etc.
	print("Player has died.")
	
	# Emit the signal that the player has died (for other systems to listen to)
	emit_signal("player_died")
	
	var timer:SceneTreeTimer = get_tree().create_timer(2.0)  
	timer.timeout.connect(func(): 
		body.position = respawn_position.position
		body.reset_damage()
		print("Player has respawned.")
	)

	
