extends Control

const GAME_SCENE = "res://scenes/world.tscn"

func _ready():
	print("Main menu ready...")
	if OS.has_feature("dedicated_server"):
		print("Calling host game...")
		NetworkManager.host_game()
		get_tree().call_deferred(&"change_scene_to_packed", load(GAME_SCENE))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()
		
func host_game():
	print("Host game pressed")
	NetworkManager.host_game()
	get_tree().call_deferred(&"change_scene_to_packed", load(GAME_SCENE))
	
func join_game():
	print("Join game pressed")
	NetworkManager.join_game()
	get_tree().call_deferred(&"change_scene_to_packed", load(GAME_SCENE))
	
func exit_game():
	get_tree().quit(0)
