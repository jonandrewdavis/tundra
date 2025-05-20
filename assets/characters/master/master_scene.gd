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

#func _process(_f: float) -> void:
	#if player._player_input.run_input:
		#if player._player_input.input_dir.y < 0.0 and player._player_input.input_dir.x == 0.0:
			#$Armature/GeneralSkeleton/RightHand.active = false
			#$Armature/GeneralSkeleton/RightLower.active = false
	#else:
		#$Armature/GeneralSkeleton/RightHand.active = true
		#$Armature/GeneralSkeleton/RightLower.active = true		
