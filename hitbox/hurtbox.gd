class_name HurtBox extends Area2D

func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	
func _ready() -> void:
	connect("area_entered", self._on_area_entered)
	
func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null:
		return
		
	if owner.has_method("take_damage"):
		var knockback = hitbox.get_parent().get_meta("knockback")
		var angle = hitbox.get_parent().get_meta("angle", null)
		owner.take_damage(knockback, angle)
