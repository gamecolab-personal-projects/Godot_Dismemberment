extends Node3D

# Arrastra aquí tu escena del brazo suelto desde el FileSystem
@export var escena_brazo_suelto: PackedScene 

# Referencia a la malla que está pegada al cuerpo
@onready var malla_brazo_cuerpo = $Armature/Skeleton3D/hueso_brazo_der/Brazo_D

func recibir_dano_en_brazo():
	if not malla_brazo_cuerpo.visible:
		return
		
	malla_brazo_cuerpo.hide()
	
	var trozo = escena_brazo_suelto.instantiate()
	get_parent().add_child(trozo) # Lo añadimos a la escena principal (Mundo)
	
	# IMPORTANTE: Usamos la posición global del BoneAttachment 
	# que es el que está exactamente en la articulación.
	# Reemplaza $BoneAttachment3D_Brazo por el nombre real de tu nodo.
	trozo.global_transform = $Armature/Skeleton3D/attach_brazo_der.global_transform
	
	# Si el brazo aparece rotado raro, podemos resetear su rotación o ajustarla:
	# trozo.global_rotation = $Skeleton3D/BoneAttachment3D_Brazo.global_rotation
	
	if trozo is RigidBody3D:
		# Creamos una dirección aleatoria hacia afuera
		var fuerza_explosion = 3.0
		var direccion = Vector3(randf_range(-1,1), randf_range(0,1), randf_range(-1,1)).normalized()
		trozo.apply_central_impulse(direccion * fuerza_explosion)
		# También una rotación aleatoria para que gire al caer
		trozo.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)
