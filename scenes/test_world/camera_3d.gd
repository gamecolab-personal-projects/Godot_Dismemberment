extends Camera3D

@onready var ray = $RayCast3D

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 1. Convertimos la posición del ratón en 2D a una dirección 3D
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = project_ray_origin(mouse_pos)
		var ray_direction = project_ray_normal(mouse_pos)
		
		# 2. Posicionamos y disparamos el Raycast
		ray.global_position = ray_origin
		ray.target_position = ray_direction * 100 
		
		# Forzamos la actualización inmediata de la física
		ray.force_raycast_update()
		
		print("\n--- NUEVO TEST DE PUNTERÍA ---")
		
		if ray.is_colliding():
			var colisionado = ray.get_collider()
			print("¡CHOCÓ CON: ", colisionado.name, "!")
			
			var personaje = colisionado.owner
			
			# Verificamos que el objeto tocado tenga el script con el diccionario
			if personaje and personaje.has_method("recibir_dano_en_pieza"):
				# Le enviamos el nombre del área (ej: "AreaBrazoD" o "AreaCabeza")
				personaje.recibir_dano_en_pieza(colisionado.name)
			else:
				print("Aviso: El objeto tocado no tiene el método 'recibir_dano_en_pieza'")
				
		else:
			print("El rayo no tocó nada en esta trayectoria.")
