extends Node3D

@onready var player: Player = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.speed_scale = 0.7
	
	$Armature/GeneralSkeleton/RightLower.target_node = player.look_at_target.get_path()
	$Armature/GeneralSkeleton/LeftLower.target_node = player.look_at_target.get_path()

	$Armature/GeneralSkeleton/LeftUpper.target_node = player.look_at_target.get_path()

	$Armature/GeneralSkeleton/RightHand.target_node = player.look_at_target.get_path()
	$Armature/GeneralSkeleton/LeftHand.target_node = player.look_at_target.get_path()
