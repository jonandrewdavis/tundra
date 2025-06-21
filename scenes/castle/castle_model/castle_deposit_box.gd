extends Node3D

# TODO: only detect collisions on server & queue free a different wya.
func _ready() -> void:
	$Area3D.body_entered.connect(_on_detect_deposit)
	$Area3D.set_collision_mask_value(1, false)
	$Area3D.set_collision_mask_value(1, false)
	$Area3D.set_collision_mask_value(8, true)


func _on_detect_deposit(body):
	if body:
		body.set_process(false)
		body.queue_free()
		if multiplayer.is_server():
			Hub.on_objective_collected()
