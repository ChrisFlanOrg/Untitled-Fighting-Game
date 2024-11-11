class_name Game extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_phone_motion(player_id, motion):
	var dir = Vector2(motion["acc"]["x"], motion["acc"]["y"])
	print(dir, Time.get_ticks_msec())
	$Player.jump(dir)
