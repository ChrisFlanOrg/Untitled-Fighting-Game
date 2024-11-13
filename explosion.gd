extends GPUParticles2D

@onready var timeCreated = Time.get_ticks_msec()

func _process(delta):
	if Time.get_ticks_msec() - timeCreated > 3000:
		print("cleaning up explosion")
		queue_free()
