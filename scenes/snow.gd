extends Node3D

@onready var ground = $Ground
@onready var ground_mesh: StandardMaterial3D = $Ground/GroundMesh.mesh.surface_get_material(0)

@onready var scatter = $ProtonScatter

# 2.0
# ground_mesh.uv1_offset.y += 0.31 * delta
#func _ready():
	#if multiplayer.is_server():
		#ground.constant_linear_velocity = Vector3(0.0, 0.0, 2.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if multiplayer.is_server() == false:
		if ground_mesh:
			ground_mesh.uv1_offset.y += 0.062 * delta

		if scatter:
			scatter.translate(Vector3(0, 0, 1.0) * 1.245 * delta)
			if scatter.global_position.z > 75.0:
				scatter.global_position.z = -75.0
