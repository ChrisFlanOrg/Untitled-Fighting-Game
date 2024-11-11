class_name HitBox
extends Area2D

export val knockback := 10
# 0 is horizontal, 90 is straight up, -90 is straight down
export val angle := 69

func _init() -> void:
	collision_layer = 2
	collision_mask = 0
