extends Sprite3D

func _on_timer_timeout():
	if multiplayer.is_server():
		queue_free()
