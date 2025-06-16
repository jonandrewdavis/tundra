extends Interactable


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	label = "Build turret"

func interact(_player):
	var turret = get_parent().get_node_or_null("Turret1")
	if turret:
		turret.activate(_player.peer_id)
		return true
		
	return false
