extends CharacterBody3D

@onready var head_intact = $fullBodyHeadGibbed/cabeza_intacta
@onready var head_gibbed = $fullBodyHeadGibbed/cabeza_gibbed_01
@onready var blood = $ParticulasSangre
@onready var blood_explosion = $ParticulasSangreExplosion   # <-- Nuevo sistema de explosión
@onready var head_origin = $fullBodyHeadGibbed/cabeza_intacta/HeadOrigin

@export var gib_scene: PackedScene
@export var gib_count := 6

# Parámetros que puedes tocar
@export_range(0.1, 20) var gib_force_min := 3.0
@export_range(0.1, 20) var gib_force_max := 7.0
@export_range(0, 90) var gib_angle_deg := 60 # ángulo máximo respecto de la vertical (0 = hacia arriba, 90 = horizontal)

var exploded := false

func _ready():
	head_gibbed.visible = false
	blood.emitting = false
	blood_explosion.emitting = false   # <-- Inicialmente apagado

func _input(event):
	if event.is_action_pressed("ui_accept"):
		swap_head()

func swap_head():
	if exploded:
		return
	exploded = true

	head_intact.visible = false
	head_gibbed.visible = true

	# Chorro lineal actual
	blood.restart()
	blood.emitting = true

	# Explosión radial
	blood_explosion.restart()
	blood_explosion.emitting = true

	# Spawn de gibs
	spawn_gibs()

func spawn_gibs():
	for i in gib_count:
		var gib = gib_scene.instantiate()
		get_tree().current_scene.add_child(gib)

		# Asegurarse de que sea RigidBody3D
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
