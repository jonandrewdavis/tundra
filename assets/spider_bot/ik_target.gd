extends Marker3D

@export var step_target: Node3D
@export var step_distance: float = 3.0

@export var adjacent_target: Node3D
@export var opposite_target: Node3D

var is_stepping := false

var ray_starting_position

var reverse = true
var is_tracking = true

func _ready():
	ray_starting_position = step_target.get_parent().global_position - Vector3(0, 0, 1.5)

func _process(delta):
	if reverse == false && !is_stepping && !adjacent_target.is_stepping:
		# Forward
		step_target.get_parent().translate(Vector3(0, 0, -1.0) * 100 * delta)
		
	if reverse == true:
		# Backwards (moving away from front)
		step_target.get_parent().translate(Vector3(0, 0, 1.0) * 1.25 * delta)
		if is_tracking:
			global_position = step_target.global_position
			# THIS IS KEY
			if step_target.get_parent().global_position.z > ray_starting_position.z + 2.95:
				reverse = false
				is_tracking = false
				return
				#step_target.get_parent().global_position = step_target.get_parent().global_position + Vector3(0.0, 0.0, 3.0)
				


	if !is_stepping && !adjacent_target.is_stepping && abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()
		opposite_target.step()


func step():
	if reverse: 
		return
		
	var target_pos = step_target.global_position
	var half_way = (global_position + step_target.global_position) / 2
	is_stepping = true
	
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position", half_way + owner.basis.y, 0.1)
	t.tween_property(self, "global_position", target_pos, 0.1)

	t.tween_callback(finish_step)
	
func finish_step():
	is_stepping = false
	reverse = true
	is_tracking = true
