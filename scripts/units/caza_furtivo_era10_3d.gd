## Caza_Furtivo_Era10 — Caza Furtivo F-22 de 5ta Generación (Edad Digital / Era 10).
##
## Aeronave furtiva de ataque de penetración profunda con tecnología de absorción radar (RAM).
## Fija su cota de vuelo a Y = 18.0 metros y vuela a una velocidad lineal de 20.0 m/s.
## Posee el flag 'is_stealth = true', siendo invisible a la pantalla enemiga y niebla de guerra,
## revelándose de forma única si entra en el radio de 65m de una Estación de Radar Táctica.
## Dispara misiles de precisión de alto impacto y regresa autónomamente a base con max_ammo = 2.
class_name Caza_Furtivo_Era10
extends "res://scripts/units/soldier_3d.gd"

signal misil_furtivo_lanzado(objetivo: Vector3)
signal municion_agotada_retorno(base_pos: Vector3)
signal sigilo_radar_revelado(revelado_por: Node3D)

@export var crucero_altura_y: float = 18.0
@export var velocidad_crucero: float = 20.0
@export var max_ammo: int = 2
var current_ammo: int = 2
var base_aerea_origen: Node3D = null
var estado_vuelo: String = "patrulla" # "patrulla", "ataque", "regresando"

func _init() -> void:
	unit_id = "caza_furtivo_era10"
	unit_name = "Caza Furtivo F-22"
	attack_type = "ranged"
	weapon_type = "missile"
	impact_type = "EXPLOSIVE"
	projectile_type = "rocket"
	is_stealth = true
	is_invisible = true
	_salud_base = 280.0
	salud_maxima = 280.0
	salud_actual = 280.0
	_daño_base = 65.0
	daño = 65.0
	rango_ataque = 28.0
	velocidad_ataque = 2.0
	speed = velocidad_crucero
	current_ammo = max_ammo
	era_entrenada = 10

func _ready() -> void:
	super._ready()
	add_to_group("aircraft")
	add_to_group("air_units")
	add_to_group("stealth_aircraft")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_stealth_jet_visuals()

	# Fijar cota de altura a Y = 18.0m
	if position.y < 1.0:
		position.y = crucero_altura_y

func _setup_stealth_jet_visuals() -> void:
	if not has_node("StealthFuselage"):
		var fuselage := MeshInstance3D.new()
		fuselage.name = "StealthFuselage"
		var prism := PrismMesh.new()
		prism.size = Vector3(2.4, 0.6, 5.2)
		fuselage.mesh = prism
		fuselage.rotation_degrees = Vector3(-90, 0, 0)
		fuselage.position = Vector3(0.0, 0.0, 0.0)
		var mat_f := StandardMaterial3D.new()
		mat_f.albedo_color = Color(0.08, 0.09, 0.11) # Compuesto RAM absorbente de radar
		mat_f.metallic = 0.9
		mat_f.roughness = 0.2
		fuselage.material_override = mat_f
		add_child(fuselage)

	if not has_node("DeltaWings"):
		var wings := MeshInstance3D.new()
		wings.name = "DeltaWings"
		var box_w := BoxMesh.new()
		box_w.size = Vector3(4.8, 0.08, 2.6)
		wings.mesh = box_w
		wings.position = Vector3(0.0, 0.0, 0.2)
		var mat_w := StandardMaterial3D.new()
		mat_w.albedo_color = Color(0.06, 0.07, 0.09)
		wings.material_override = mat_w
		add_child(wings)

	if not has_node("TwinAfterburners"):
		var burners := MeshInstance3D.new()
		burners.name = "TwinAfterburners"
		var box_b := BoxMesh.new()
		box_b.size = Vector3(0.8, 0.25, 0.3)
		burners.mesh = box_b
		burners.position = Vector3(0.0, 0.0, 2.7)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.0, 0.8, 1.0) # Postquemadores cian digital
		mat_b.emission_enabled = true
		mat_b.emission = Color(0.0, 0.85, 1.0)
		mat_b.emission_energy_multiplier = 4.0
		burners.material_override = mat_b
		add_child(burners)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead or is_disabled:
		return

	# Mantener altura constante estricta de crucero a Y = 18.0m
	if abs(position.y - crucero_altura_y) > 0.1:
		position.y = move_toward(position.y, crucero_altura_y, delta * 8.0)

	# Manejo del estado de retorno a base si se agotaron las cargas
	if estado_vuelo == "regresando":
		var dest: Vector3 = base_aerea_origen.position if is_instance_valid(base_aerea_origen) else Vector3.ZERO
		var dir := (Vector3(dest.x, crucero_altura_y, dest.z) - position).normalized()
		velocity = dir * velocidad_crucero
		move_and_slide()
		if position.distance_to(Vector3(dest.x, crucero_altura_y, dest.z)) < 4.0:
			rearmar_completamente()

## Lanza una pasada de misiles de precisión sigilosos hacia la posición terrestre
func lanzar_pasada_furtiva(target_pos: Vector3) -> int:
	if current_ammo <= 0:
		regresar_a_base()
		return 0

	current_ammo -= 1
	var impactados: int = 0
	var centro_tierra: Vector3 = target_pos if target_pos != Vector3.ZERO else Vector3(position.x, 0, position.z)

	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root
	elif Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root:
		root_node = (Engine.get_main_loop() as SceneTree).root
	elif get_parent():
		root_node = get_parent()

	if is_instance_valid(root_node):
		var candidatos: Array[Node] = []
		candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))
		candidatos.append_array(root_node.find_children("*", "StaticBody3D", true, false))

		for cand in candidatos:
			if cand == self or not is_instance_valid(cand) or not (cand is Node3D):
				continue
			var cand_3d := cand as Node3D
			var pos_c: Vector3 = cand_3d.position if cand_3d.position != Vector3.ZERO else (cand_3d.global_position if cand_3d.is_inside_tree() else cand_3d.position)
			var pos_c_plana: Vector3 = Vector3(pos_c.x, 0, pos_c.z)
			if pos_c_plana.distance_to(Vector3(centro_tierra.x, 0, centro_tierra.z)) <= 8.0:
				var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, cand_3d)
				if cand.has_method("recibir_dano"):
					cand.call("recibir_dano", dmg)
				elif "salud_actual" in cand:
					cand.set("salud_actual", maxf(0.0, float(cand.get("salud_actual")) - dmg))
				impactados += 1

	misil_furtivo_lanzado.emit(centro_tierra)
	if current_ammo <= 0:
		regresar_a_base()

	return impactados

## Conmuta el retorno autónomo a la base aérea para rearmarse
func regresar_a_base() -> void:
	estado_vuelo = "regresando"
	var dest: Vector3 = base_aerea_origen.position if is_instance_valid(base_aerea_origen) else Vector3.ZERO
	municion_agotada_retorno.emit(dest)
	print("Caza_Furtivo_Era10 '%s': Munición agotada (0/%d). Regresando a base aérea furtiva." % [name, max_ammo])

## Restaura la munición al 100%
func rearmar_completamente() -> void:
	current_ammo = max_ammo
	estado_vuelo = "patrulla"

## Revelación de sigilo forzada por pulso de Estación de Radar Táctica
func ser_revelado_por_radar(radar_node: Node3D) -> void:
	is_invisible = false
	sigilo_radar_revelado.emit(radar_node)
