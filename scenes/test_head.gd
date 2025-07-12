extends Node3D

@onready var head = $head_normal
@onready var head_gib = $head_gibbed
@onready var blood = $BloodParticles

func _ready():
	head.visible = true
	head_gib.visible = false
	blood.emitting = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		head.visible = false
		head_gib.visible = true
		blood.restart()
		
	if event.is_action_pressed("restart"):  # Asumiendo que "restart" está definido en Input Map como la tecla R
		get_tree().reload_current_scene()
