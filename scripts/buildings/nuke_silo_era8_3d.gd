## NukeSilo_Era8_3D — Silo de Misiles ICBM WWII (Edad Atómica / Era 8).
##
## Súper-estructura militar de asedio estratégico que hereda directamente de Barracks3D.
## Permite fabricar a un costo colosal el proyectil 'Misil_Nuclear_ICBM'.
## Al dispararse por RPC fiable desde el Servidor, genera un radio de detonación de 18.0m
## con 9999 HP de daño instantáneo y despliega un área residual radioactiva DoT de 10 HP/s por 15.0s,
## que solo puede cruzar con seguridad el HazmatWorker_Era8 (inmunidad biológica).
class_name NukeSilo_Era8_3D
extends "res://scripts/buildings/barracks_3d.gd"

signal misil_detonado(coordenada: Vector3, radio: float)
signal zona_radioactiva_creada(zona_nodo: Node3D, duracion: float)

@export var building_type: String = "nuke_silo"
@export var misiles_disponibles: int = 1
@export var radio_detonacion: float = 18.0
@export var dano_letal: float = 9999.0
@export var duracion_radiacion: float = 15.0
@export var dano_dot_radiacion: float = 10.0

func _init() -> void:
	super._init()
	building_name = "Silo de Misiles ICBM WWII"
	salud_maxima = 3200.0
	salud_actual = 3200.0
	_salud_maxima_base = 3200.0
	radio_vision = 45.0

func _ready() -> void:
	super._ready()
	add_to_group("nuke_silos")
	add_to_group("military_buildings")
	_setup_silo_visuals()

func _setup_silo_visuals() -> void:
	if not has_node("SiloConcreteBase"):
		var base_mesh := MeshInstance3D.new()
		base_mesh.name = "SiloConcreteBase"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 4.2
		cyl.bottom_radius = 4.5
		cyl.height = 1.2
		base_mesh.mesh = cyl
		base_mesh.position = Vector3(0.0, 0.6, 0.0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.35, 0.36, 0.38) # Hormigón armado
		base_mesh.material_override = mat_b
		add_child(base_mesh)

	if not has_node("MissileHatch"):
		var hatch := MeshInstance3D.new()
		hatch.name = "MissileHatch"
		var cyl_h := CylinderMesh.new()
		cyl_h.top_radius = 2.2
		cyl_h.bottom_radius = 2.2
		cyl_h.height = 0.4
		hatch.mesh = cyl_h
		hatch.position = Vector3(0.0, 1.3, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.18, 0.2, 0.22) # Compuerta de acero blindado
		hatch.material_override = mat_h
		add_child(hatch)

	if not has_node("MissileTip"):
		var tip := MeshInstance3D.new()
		tip.name = "MissileTip"
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.9
		cone.height = 2.4
		tip.mesh = cone
		tip.position = Vector3(0.0, 2.5, 0.0)
		var mat_m := StandardMaterial3D.new()
		mat_m.albedo_color = Color(0.75, 0.78, 0.8) # Ojiva nuclear
		tip.material_override = mat_m
		add_child(tip)

## Dispara un misil nuclear ICBM por RPC fiable hacia la coordenada de destino
@rpc("any_peer", "call_local", "reliable")
func disparar_misil_icbm(target_pos: Vector3) -> Dictionary:
	var victimas_impactadas: Array[Node3D] = []
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	var root_node: Node = tree.root if is_instance_valid(tree) else get_parent()

	# 1. Búsqueda y detonación letal instantánea (9999 HP) en radio esférico de 18.0m
	if is_instance_valid(root_node):
		var candidatos: Array[Node] = []
		candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))
		candidatos.append_array(root_node.find_children("*", "StaticBody3D", true, false))

		for cand in candidatos:
			if cand == self or not is_instance_valid(cand):
				continue
			var obj_3d := cand as Node3D
			var pos_c: Vector3 = obj_3d.position if obj_3d.position != Vector3.ZERO else obj_3d.global_position
			if pos_c.distance_to(target_pos) <= radio_detonacion:
				if cand.has_method("recibir_dano"):
					cand.call("recibir_dano", dano_letal)
				elif "salud_actual" in cand:
					cand.set("salud_actual", maxf(0.0, float(cand.get("salud_actual")) - dano_letal))
				victimas_impactadas.append(obj_3d)

	# 2. Despliegue de Área Residual Radioactiva DoT (10 HP/s por 15.0s)
	var zona_rad := AreaRadioactivaResidual.new()
	zona_rad.name = "ZonaRadioactiva_ICBM"
	zona_rad.position = target_pos
	zona_rad.duracion_restante = duracion_radiacion
	zona_rad.dps_radiacion = dano_dot_radiacion
	zona_rad.radio_zona = radio_detonacion

	if is_instance_valid(root_node):
		root_node.add_child(zona_rad)

	misil_detonado.emit(target_pos, radio_detonacion)
	zona_radioactiva_creada.emit(zona_rad, duracion_radiacion)

	return {
		"victimas": victimas_impactadas,
		"radio": radio_detonacion,
		"dano": dano_letal,
		"zona_radioactiva": zona_rad
	}

# ─── Clase Interna de la Zona Radioactiva DoT ─────────────────────────────────
class AreaRadioactivaResidual extends Area3D:
	var duracion_restante: float = 15.0
	var dps_radiacion: float = 10.0
	var radio_zona: float = 18.0
	var timer_tick: float = 0.0

	func _ready() -> void:
		add_to_group("radiation_zones")
		var col_shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = radio_zona
		col_shape.shape = sphere
		add_child(col_shape)

	func _process(delta: float) -> void:
		duracion_restante -= delta
		if duracion_restante <= 0.0:
			queue_free()
			return

		timer_tick += delta
		if timer_tick >= 1.0:
			timer_tick = 0.0
			aplicar_tick_radiacion()

	## Aplica el daño por segundo a cualquier unidad dentro del radio salvo inmunes (HazmatWorker)
	func aplicar_tick_radiacion() -> Array[Node3D]:
		var afectadas: Array[Node3D] = []
		var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
		if not is_instance_valid(tree):
			return afectadas

		var candidatos: Array[Node] = tree.root.find_children("*", "CharacterBody3D", true, false)
		for cand in candidatos:
			if not is_instance_valid(cand) or cand == self:
				continue
			var obj_3d := cand as Node3D
			var pos_c: Vector3 = obj_3d.position if obj_3d.position != Vector3.ZERO else obj_3d.global_position
			var centro_zona: Vector3 = position if position != Vector3.ZERO else global_position
			if pos_c.distance_to(centro_zona) <= radio_zona:
				var dano_aplicado: float = procesar_dano_unidad(cand as Node3D)
				if dano_aplicado > 0.0:
					afectadas.append(cand as Node3D)
		return afectadas

	## Calcula y transfiere daño a una unidad según su inmunidad
	func procesar_dano_unidad(unidad: Node3D) -> float:
		if not is_instance_valid(unidad):
			return 0.0
		# Si la unidad posee inmunidad radioactiva absoluta, no sufre daño
		if unidad.get("is_radiation_immune") == true:
			return 0.0

		if unidad.has_method("recibir_dano"):
			unidad.call("recibir_dano", dps_radiacion)
		elif "salud_actual" in unidad:
			unidad.set("salud_actual", maxf(0.0, float(unidad.get("salud_actual")) - dps_radiacion))
		return dps_radiacion
