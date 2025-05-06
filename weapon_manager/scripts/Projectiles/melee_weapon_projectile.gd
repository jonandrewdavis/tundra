extends Projectile

@onready var melee_hitbox: ShapeCast3D = $MeleeHitbox

func _over_ride_collision(_camera_collision:Array, _damage: float):
	melee_hitbox.force_shapecast_update()
	var colliders = melee_hitbox.get_collision_count()
	for c in colliders:
		var target = melee_hitbox.get_collider(c)
		if target.is_in_group("targets") and target.has_method("hit"):
			#hit_signal.emit()
			var Direction = (target.global_transform.origin - global_transform.origin).normalized()
			var Position =  melee_hitbox.get_collision_point(c)
			target.hit(_damage, Direction, Position)
	queue_free()
