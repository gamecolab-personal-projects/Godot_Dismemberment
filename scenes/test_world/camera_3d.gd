extends Camera3D

@onready var ray = $RayCast3D

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convertimos la posición del ratón en 2D a una dirección 3D
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = project_ray_origin(mouse_pos)
		var ray_direction = project_ray_normal(mouse_pos)
		
		# Proyectamos el Raycast desde el ratón hacia adelante
		ray.global_position = ray_origin
		ray.target_position = ray_direction * 100 # 100 metros de alcance
		
		ray.force_raycast_update()
		
		print("\n--- NUEVO TEST DE PUNTERÍA ---")
		if ray.is_colliding():
			print("¡CHOCÓ CON: ", ray.get_collider().name, "!")
			if ray.get_collider().name == "AreaBrazo":
				ray.get_collider().owner.recibir_dano_en_brazo()
		else:
			print("El rayo salió desde ", ray_origin, " hacia ", ray_direction, " pero no tocó nada.")
