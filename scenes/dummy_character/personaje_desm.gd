extends Node3D

# Exporta la escena de partículas de sangre (chorro)
@export var escena_sangre_chorro: PackedScene
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
	if not piezas.has(nombre_area): return
	
	var datos = piezas[nombre_area]
	var malla = datos[0]
	var escena_suelta = datos[1]
	var attachment = datos[2]
	
	if not malla.visible: return
	
	malla.hide()
	
	if nombre_area == "AreaCabeza":
		morir()
	
	# --- LLAMADA A LA FUNCIÓN DE PARTÍCULAS ---
	generar_chorro_sangre(attachment)
	# ------------------------------------------

	# Soltamos el trozo físico (Tu lógica original)
	var trozo = escena_suelta.instantiate()
	get_parent().add_child(trozo)
	trozo.global_position = attachment.global_position
	trozo.global_rotation = self.global_rotation
	
	if trozo is RigidBody3D:
		var fuerza_explosion = 3.0
		var direccion = Vector3(randf_range(-1,1), randf_range(0.5,1), randf_range(-1,1)).normalized()
		trozo.apply_central_impulse(direccion * fuerza_explosion)

# --- FUNCIÓN DE PARTÍCULAS INDEPENDIENTE ---
func generar_chorro_sangre(nodo_anclaje: Node3D):
	if not escena_sangre_chorro:
		return

	var sangre = escena_sangre_chorro.instantiate() as GPUParticles3D
	nodo_anclaje.add_child(sangre)
	
	# 1. Definimos el "Punto Origen" (Centro del torso a la altura del corte)
	var torso_pos_global = self.global_position
	torso_pos_global.y = nodo_anclaje.global_position.y
	
	# 2. Calculamos la dirección real TORSO -> EXTREMIDAD
	# Restamos Destino - Origen para que el vector apunte hacia afuera
	var direccion_hacia_afuera = (nodo_anclaje.global_position - torso_pos_global).normalized()
	
	# 3. Ajuste de posición (el "lerp" para meterlo en el cilindro)
	# Convertimos el punto del torso a local del attachment para saber hacia dónde retraer
	var objetivo_local = nodo_anclaje.to_local(torso_pos_global)
	var factor_retraccion = 0.3
	sangre.position = Vector3.ZERO.lerp(objetivo_local, factor_retraccion)
	
	# 4. ORIENTACIÓN FINAL (Look At)
	# Forzamos que el chorro mire hacia la dirección calculada en el paso 2
	# Usamos global_position de la sangre para que el rayo de mirada sea paralelo al vector
	if direccion_hacia_afuera.length() > 0.01:
		sangre.look_at(sangre.global_position + direccion_hacia_afuera, Vector3.UP)
	
	# 5. Activar partículas
	sangre.emitting = true
	
	# Limpieza automática
	get_tree().create_timer(sangre.lifetime + 1.0).timeout.connect(func():
		if is_instance_valid(sangre):
			sangre.queue_free()
	)


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
		var nombre_hueso = skeleton.get_bone_name(i).to_lower()
		
		# Ignorar huesos pequeños que causan ruido visual
		if "toe" in nombre_hueso or "finger" in nombre_hueso or "end" in nombre_hueso:
			continue

		var pb = PhysicalBone3D.new()
		pb.bone_name = skeleton.get_bone_name(i)
		pb.name = "Ragdoll_" + pb.bone_name
		skeleton.add_child(pb, true)
		
		pb.collision_layer = 4
		pb.collision_mask = 1 
		pb.can_sleep = true
		pb.global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(i)
		
		var shape_node = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		
		if "torso" in nombre_hueso or "hips" in nombre_hueso:
			capsule.radius = 0.11
			capsule.height = 0.4
			pb.mass = 25.0 
		else:
			capsule.radius = 0.05
			capsule.height = 0.28
			pb.mass = 2.0 
			
		shape_node.shape = capsule
		pb.add_child(shape_node)
		
		# 4. ARTICULACIÓN PIN CON LÍMITE ANATÓMICO "SIMULADO"
		if skeleton.get_bone_parent(i) != -1:
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_PIN
			
			# Ajustamos BIAS y SOFTNESS para endurecer el giro.
			# Al bajar Softness a 0.2, el hueso se resiste mucho a girar lejos de su eje.
			pb.set("joint_constraints/bias", 0.5)     # Fuerza de retorno más rápida
			pb.set("joint_constraints/softness", 0.1) # Muy bajo para que actúe como "tope"
			pb.set("joint_constraints/relaxation", 1.0)
		
		# 5. CONTROL DE ROTACIÓN (Aquí limitamos los giros locos)
		pb.linear_damp = 0.6
		# Subimos el angular_damp a 15 de base para que el giro se sienta "pesado"
		# y no alcance velocidades que permitan dar la vuelta completa fácilmente.
		pb.angular_damp = 15.0 

	# 6. INICIO E IMPULSO
	skeleton.physical_bones_start_simulation()
	
	var cadera = null
	for child in skeleton.get_children():
		if child is PhysicalBone3D and ("hips" in child.name.to_lower() or "root" in child.name.to_lower()):
			cadera = child
			break
			
	if cadera:
		# Impulso más seco para que el cuerpo caiga rápido antes de poder girar sobre sí mismo
		cadera.apply_central_impulse(Vector3(randf_range(-1, 1), -4.5, -1.0))

	# 7. CIERRE PROGRESIVO
	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(skeleton):
			for pb in skeleton.get_children():
				if pb is PhysicalBone3D:
					pb.angular_damp = 60.0 
					pb.linear_damp = 20.0
			
			await get_tree().create_timer(1.0).timeout
			if is_instance_valid(skeleton):
				skeleton.physical_bones_stop_simulation()
	)

func morir():
	if esta_muerto: return
	esta_muerto = true
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
	
	generar_ragdoll_estable()
