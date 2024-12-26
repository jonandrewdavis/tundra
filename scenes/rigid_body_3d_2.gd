extends RigidBody3D

var captured_by: Player = null

func _physics_process(_delta):
	pass
	#var a = global_transform.origin # here,
	#var b = captured_by.global_transform.origin + Vector3(0.0, 0.8, 0.0) # there
	#set_linear_velocity((b - a) * 10)
