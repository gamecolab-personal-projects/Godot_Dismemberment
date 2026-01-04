extends CharacterBody3D

@onready var head_intact = $fullBodyHeadGibbed/cabeza_intacta
@onready var head_gibbed = $fullBodyHeadGibbed/cabeza_gibbed_01
@onready var blood = $ParticulasSangre

var exploded := false

func _ready():
	head_gibbed.visible = false
	blood.emitting = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		swap_head()

func swap_head():
	if exploded:
		return
	exploded = true

	head_intact.visible = false
	head_gibbed.visible = true

	blood.restart()
	blood.emitting = true
