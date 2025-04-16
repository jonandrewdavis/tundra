extends PhysicalBoneSimulator3D

# Note: Followed this guide: https://docs.godotengine.org/en/stable/tutorials/physics/ragdoll_system.html
# Delete Root, Hips, Neck

func _ready() -> void:
	for bone: PhysicalBone3D in get_children():
		bone.set_collision_layer_value(1, false)
		bone.set_collision_mask_value(1, false)
		# Bones are on layer 4
		bone.set_collision_layer_value(4, true)
		bone.set_collision_mask_value(4, true)
	
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		bone.angular_damp = 0.8
		bone.linear_damp = 0.8
		bone.mass = 20.0
