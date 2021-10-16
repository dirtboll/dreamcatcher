extends StaticBody2D


signal interacted()

var interactable = false

func interact():
	if interactable:
		emit_signal("interacted")
