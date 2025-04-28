extends Interactable

func interact(_player):
	Hub.debug_change_castle_speed()
	if Hub.castle.castle_on:
		label = 'Off'
	else:
		label = 'On'
	
	return true
