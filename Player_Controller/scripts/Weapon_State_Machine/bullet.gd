extends RigidBody3D

signal hit_signal

var damage: int = 0

func _on_body_entered(body):
	if body.is_in_group("targets") && body.has_method("hit"):
		body.hit(damage)
		emit_signal("hit_signal")

	queue_free()

func _on_timer_timeout():
	queue_free()
