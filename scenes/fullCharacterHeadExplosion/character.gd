extends CharacterBody3D

@onready var head_intact = $fullBodyHeadGibbed/cabeza_intacta
@onready var head_gibbed = $fullBodyHeadGibbed/cabeza_gibbed_01
@onready var blood = $ParticulasSangre
@onready var blood_explosion = $ParticulasSangreExplosion
@onready var head_origin = $fullBodyHeadGibbed/cabeza_intacta/HeadOrigin

# Nueva lista de gibs: agrega tantas variantes como quieras en el editor
@export var gib_scenes: Array[PackedScene] = []

@export var gib_count := 6

# Parámetros de impulso
@export_range(0.1, 20) var gib_force_min := 3.0
@export_range(0.1, 20) var gib_force_max := 7.0
@export_range(0, 90) var gib_angle_deg := 60 # ángulo máximo respecto de la vertical

var exploded := false

func _ready():
	head_gibbed.visible = false
	blood.emitting = false
	blood_explosion.emitting = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		swap_head()

func swap_head():
	if exploded:
		return
	exploded = true

	head_intact.visible = false
	head_gibbed.visible = true

	# Chorro lineal
	blood.restart()
	blood.emitting = true

	# Explosión radial
	blood_explosion.restart()
	blood_explosion.emitting = true

	# Spawn gibs
	spawn_gibs()

func spawn_gibs():
	if gib_scenes.is_empty():
		push_error("No hay variantes de gibs en gib_scenes")
		return

	for i in gib_count:
		# Elegir una variante aleatoria
		var gib_scene = gib_scenes[randi() % gib_scenes.size()]
		var gib = gib_scene.instantiate()
		get_tree().current_scene.add_child(gib)

		var rb := gib as RigidBody3D

		# Posición inicial cerca de la cabeza
		var offset = Vector3(
			randf_range(-0.05, 0.05),
			randf_range(0.0, 0.05),
			randf_range(-0.05, 0.05)
		)
		rb.global_position = head_origin.global_position + offset

		# Dirección aleatoria
		var theta = deg_to_rad(randf_range(0, gib_angle_deg))
		var phi = randf_range(0, PI * 2)
		var dir = Vector3(
			sin(theta) * cos(phi),
			cos(theta),
			sin(theta) * sin(phi)
		).normalized()

		# Impulso inicial
		var force = randf_range(gib_force_min, gib_force_max)
		rb.apply_central_impulse(dir * force)

		# Rotación aleatoria
		rb.angular_velocity = Vector3(
			randf_range(-10, 10),
			randf_range(-10, 10),
			randf_range(-10, 10)
		)

		# Escala aleatoria
		rb.scale = Vector3(
			randf_range(0.8, 1.2),
			randf_range(0.8, 1.2),
			randf_range(0.8, 1.2)
		)
