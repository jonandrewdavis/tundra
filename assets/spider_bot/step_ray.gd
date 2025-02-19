extends RayCast3D

@export var step_target: Node3D

var start_pos

func _ready() -> void:
	start_pos = position

func _physics_process(delta):
	var hit_point = get_collision_point()
	if hit_point:
		step_target.global_position = hit_point

#func _process(delta: float) -> void:
	#translate(Vector3(0, 0, -1.0) * 2.0 * delta)
	#if position.distance_to(start_pos) > 4.0:
		#position = Vector3(start_pos) - Vector3(0.0, 0.0, -4.0) 
