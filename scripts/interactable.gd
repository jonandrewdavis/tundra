extends StaticBody3D
class_name Interactable

@export var label: String

signal queue_free_signal

func _ready() -> void:
	set_collision_layer_value(8, true)
	queue_free_signal.connect(func(): queue_free_on_clients.rpc())

func interact(_player: Player) -> bool:
	return true

# If this wasn't created by a spawner, broadcast it's deletion
@rpc
func queue_free_on_clients():
	if is_inside_tree():
		queue_free()
