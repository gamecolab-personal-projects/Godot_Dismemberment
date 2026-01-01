extends Node3D

func _input(event):
	# Si pulsas la tecla R
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
