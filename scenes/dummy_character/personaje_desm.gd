extends Node3D

# Diccionario de configuración:
# "NombreDelArea": [Nodo_Malla, Escena_RigidBody, Nodo_Attachment]
@onready var piezas = {
	"AreaBrazoD": [
		$Armature/Skeleton3D/hueso_brazo_der/Brazo_D, 
		preload("uid://21cbsjtctt06"), 
		$Armature/Skeleton3D/attach_brazo_der
	],
	"AreaBrazoI": [
		$Armature/Skeleton3D/hueso_brazo_izq/Brazo_I, 
		preload("uid://syy038g30tx3"), 
		$Armature/Skeleton3D/attach_brazo_izq
	],
	"AreaCabeza": [
		$Armature/Skeleton3D/hueso_cabeza/Cabeza, # Ajusta este nombre a tu malla real
		preload("uid://cg82yeqpmihdp"), 
		$Armature/Skeleton3D/attach_cabeza       # Ajusta este nombre a tu attachment real
	]
}

var esta_muerto = false

func recibir_dano_en_pieza(nombre_area: String):
	# Si la pieza no está en el diccionario, ignoramos
	if not piezas.has(nombre_area):
		print("El área ", nombre_area, " no está configurada en el diccionario.")
		return
	
	var datos = piezas[nombre_area]
	var malla = datos[0]
	var escena_suelta = datos[1]
	var attachment = datos[2]
	
	# Si la malla ya no está (ya se desmembró), no hacemos nada
	if not malla.visible:
		return
	
	# 1. Escondemos la parte del cuerpo original
	malla.hide()
	
	# 2. Si es la cabeza, ejecutamos la lógica de muerte
	if nombre_area == "AreaCabeza":
		morir()
	
	# 3. Soltamos el trozo físico (RigidBody)
	var trozo = escena_suelta.instantiate()
	
	# PRIMERO: Añadir al mundo
	get_parent().add_child(trozo)
	
	# SEGUNDO: Posición del hombro (attachment)
	trozo.global_position = attachment.global_position

	# TERCERO: Rotación del cuerpo (para que no salga vertical)
	trozo.global_rotation = self.global_rotation
	
	# 4. Impulso físico para que no caiga como un bloque
	if trozo is RigidBody3D:
		var fuerza_explosion = 3.0
		var direccion = Vector3(randf_range(-1,1), randf_range(0.5,1), randf_range(-1,1)).normalized()
		trozo.apply_central_impulse(direccion * fuerza_explosion)
		trozo.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)

func generar_ragdoll_estable():
	var skeleton = $Armature/Skeleton3D
	
	# 1. PREPARACIÓN
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()

	# 2. LIMPIEZA
	for hijo in skeleton.get_children():
		if hijo is PhysicalBone3D:
			hijo.queue_free()

	# 3. GENERACIÓN
	for i in skeleton.get_bone_count():
		var nombre_hueso = skeleton.get_bone_name(i)
		var pb = PhysicalBone3D.new()
		pb.bone_name = nombre_hueso
		pb.name = "Ragdoll_" + nombre_hueso
		skeleton.add_child(pb)
		
		# IMPORTANTE: Capas para evitar que los huesos se empujen entre sí
		pb.collision_layer = 4
		pb.collision_mask = 1 # Solo choca con el suelo (Capa 1)
		
		# Sincronizar posición inicial
		pb.global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(i)
		
		var shape_node = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		
		# Cápsulas finas para que las articulaciones tengan "espacio" para doblarse
		if "torso" in nombre_hueso.to_lower() or "hips" in nombre_hueso.to_lower():
			capsule.radius = 0.1
			capsule.height = 0.35
			pb.mass = 15.0 # Peso muerto para que caiga rápido
		else:
			capsule.radius = 0.04
			capsule.height = 0.2
			pb.mass = 1.0
			
		shape_node.shape = capsule
		pb.add_child(shape_node)
		
		# 4. ARTICULACIÓN PIN (Simple y sin errores)
		if skeleton.get_bone_parent(i) != -1:
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_PIN
		
		# Ajustes de fricción para evitar que parezca gelatina
		pb.linear_damp = 0.5
		pb.angular_damp = 3.0 # Un poco de resistencia al giro para que no vibre

	# 5. INICIO DE SIMULACIÓN E IMPULSO
	skeleton.physical_bones_start_simulation()
	
	# Empujón para asegurar que no caiga de pie
	var cadera = skeleton.get_node_or_null("Ragdoll_Hips") 
	if cadera:
		cadera.apply_central_impulse(Vector3(0, -2.0, -1.0))

	# 6. AUTO-STOP
	get_tree().create_timer(7.0).timeout.connect(func():
		if is_instance_valid(skeleton):
			skeleton.physical_bones_stop_simulation()
	)

func morir():
	if esta_muerto: return
	esta_muerto = true
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
	
	generar_ragdoll_estable()
