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

func morir():
	if esta_muerto:
		return
	esta_muerto = true
	print("Enemigo muerto: Deteniendo procesos.")
	
	# Si tienes animaciones, las paramos
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
	
	# Aquí podrías desactivar el movimiento del enemigo si tuviera IA
