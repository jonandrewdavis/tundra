extends Node
class_name ResourceSystem

@export var spawner: MultiplayerSpawner 
@export var container: Node3D 

var oil_drum = preload("res://scenes/interactables/oil-drum/oil_drum.tscn")
var oil_drum_static = preload("res://scenes/interactables/oil-drum/oil_drum_static.tscn")

var scenes_to_spawn = [oil_drum, oil_drum_static]

# TODO: Preload & add to spawner helpers (systems should extend from base)
func _ready() -> void:
	Hub.resource_system = self
	for scene in scenes_to_spawn:
		spawner.add_spawnable_scene(scene.get_state().get_path())

func spawn_as_movable(item: Interactable, player: Player):

	var transform = item.transform
	var temp_global_positon = item.global_position
	# case:
	var new_movable = oil_drum.instantiate()
	container.add_child(new_movable, true)
	new_movable.global_position = temp_global_positon
	new_movable.transform = transform
	# If this wasn't created by a spawner, broadcast it's deletion
	item.queue_free_signal.emit()
	item.queue_free()

	if new_movable.enable_pickup == true:
		player.interact_holding(new_movable)
