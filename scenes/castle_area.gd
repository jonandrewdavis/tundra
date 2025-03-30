extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", _on_castle_area_entered)
	connect("body_exited", _on_castle_area_exited)

func _on_castle_area_entered(body):
	if body && body.has_method('toggle_constant_force'):
		body.toggle_constant_force(false)
	
func _on_castle_area_exited(body):
	if body && body.has_method('toggle_constant_force'):
		body.toggle_constant_force(true)
