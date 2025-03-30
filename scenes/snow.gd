extends Node3D

@onready var ground = $Ground
@onready var ground_mesh: StandardMaterial3D = $Ground/GroundMesh.mesh.surface_get_material(0)

@onready var scatter = $ProtonScatter

# 2.0
# ground_mesh.uv1_offset.y += 0.31 * delta
func _ready():
	print('DEBUG: get multiplayer on snow', get_multiplayer_authority())



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Hub.world.castle_speed == 0.0:
		return	

	if multiplayer.is_server() == false:
		if ground_mesh:
			ground_mesh.uv1_offset.y += 0.062 * delta

		if scatter:
			scatter.translate(Vector3(0, 0, 1.0) * 1.245 * delta)
			if scatter.global_position.z > 75.0:
				scatter.global_position.z = -75.0
