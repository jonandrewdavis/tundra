extends StaticBody3D
class_name Interactable

@export var label: String

func _ready() -> void:
	set_collision_layer_value(8, true)	

func interact(_player: Player) -> bool:
	return true
