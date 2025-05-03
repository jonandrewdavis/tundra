extends Interactable

func interact(_player):
	Hub.castle.change_castle_speed.emit()
	if Hub.castle.castle_on:
		label = 'Engine Off'
	else:
		label = 'Engine On'
	
	return true
