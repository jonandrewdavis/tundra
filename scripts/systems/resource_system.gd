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

	spawner.set_spawn_function(handle_movable_spawn)

# TODO: Additional resource types, for now, just oil.
func handle_movable_spawn(data: Variant):
	var given_transform = data[0]
	var new_movable = oil_drum.instantiate()
	new_movable.transform = given_transform
	return new_movable

func spawn_as_movable(item: Interactable, player: Player):
	var new_interactable = spawner.spawn([item.transform])
	new_interactable.global_position = item.global_position

	## If this wasn't created by a spawner, broadcast it's deletion
	item.queue_free_signal.emit()
	item.queue_free()
	
	if new_interactable.enable_pickup == true:
		player.interact_holding(new_interactable)
