extends Interactable

# TODO: remove super, maybe abstract all interactables into movables first

func _ready():
	super()
	label = "Oil"	

func interact(player):
	if multiplayer.is_server():
		Hub.resource_system.spawn_as_movable(self, player)
