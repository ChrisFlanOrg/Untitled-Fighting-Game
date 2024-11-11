extends Area2D

# Signal to notify that player has died
signal player_died

# Reference to the player node (you can set this in the editor)
@export var player: Node2D

# Respawn position for the player (you can set this in the editor)
@export var respawn_position: Node2D

# Trigger when something enters the boundary
func _on_body_entered(body) -> void:
	# Check if the body is the player
	if body.is_in_group("player"):
		# Kill the player (reset their position and handle death logic)
		print("Player entered boundary")
		kill_player()

# Function to "kill" the player by resetting their position
func kill_player() -> void:
	if player:
		# Reset the player's position
		player.position = respawn_position.position
		# You can add additional death logic here, such as resetting health, playing animations, etc.
		print("Player has died and respawned.")
		
		# Emit the signal that the player has died (for other systems to listen to)
		emit_signal("player_died")
