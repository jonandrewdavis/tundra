extends Node3D

@export var nav_region: NavigationRegion3D

func _ready() -> void:
	if !nav_region:
		push_warning('No nav region for walking scene')	
		return

	for child: StaticBody3D in nav_region:
		if child.has_method('set_collision_layer_value'):
			# Catch bones: Layer 4
			child.set_collision_layer_value(4, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
