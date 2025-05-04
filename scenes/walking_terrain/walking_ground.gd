extends StaticBody3D

func _ready() -> void:
	set_collision_mask(00000000_00000000_00000000_01111111) # EXCEPT INTERACTABLES: LAYER 8
