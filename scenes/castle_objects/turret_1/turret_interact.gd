extends Interactable


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	label = "Build turret (Cost: 1)"

func interact(_player):
	var turret = get_parent().get_node_or_null("Turret1")
	if turret and Hub.objectives_collected > 0:
		print('Activate')
		turret.activate(_player.peer_id)
		label = ''
		return true
		
	return false
