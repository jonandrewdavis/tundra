extends Node3D

@export var offset: float = 20.0

@onready var parent = get_parent_node_3d()
@onready var previous_position = parent.global_position

func _ready() -> void:
	pass
	#var index = 0
	#for ray in get_children():
		#if index == 0 or index == 2:
			#global_position = global_position + Vector3(0.0, 0.0, 1.5)
#
		#index = index + 1
		
# NOTE: This fucks it all up
func _process(delta):
	pass
	#var velocity = parent.global_position - previous_position
	#global_position = parent.global_position + velocity * offset
	#
	#previous_position = parent.global_position
