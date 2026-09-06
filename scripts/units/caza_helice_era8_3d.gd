## Caza_Helice_Era8 — Caza Monoplano P-51 (Edad Atómica / Era 8).
##
## Vehículo aéreo monoplano de alta cota y velocidad superior.
## Navega en una capa física fija en el eje Y (Y = 12.0m) a 12.0 m/s.
## Ejecuta ráfagas de ametrallamiento aire-tierra mediante rpc_ametrallar_suelo().
## Capacidad máxima de 4 pasadas de ametrallamiento (max_ammo = 4), regresando
## automáticamente a la base para rearmarse al quedar sin munición.
class_name Caza_Helice_Era8
extends "res://scripts/units/soldier_3d.gd"

signal municion_agotada()
signal regreso_a_base_iniciado()
signal aterrizaje_completado()

var altura_vuelo: float = 12.0
var max_ammo: int = 4
var current_ammo: int = 4
var estado_vuelo: String = "patrulla" # "patrulla", "ametrallamiento", "regresando"
var is_aircraft: bool = true

func _init() -> void:
	unit_id = "caza_helice_era8"
	unit_name = "Caza Monoplano P-51"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 220.0
	salud_maxima = 220.0
	salud_actual = 220.0
	_daño_base = 42.0
	daño = 42.0
	rango_ataque = 26.0
	velocidad_ataque = 1.0
	speed = 12.0
	era_entrenada = 8

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("air_units")
	add_to_group("aircraft")
	add_to_group("military_units")
	add_to_group("units_3d")
	position.y = altura_vuelo
	_setup_monoplano_visuals()

func _setup_monoplano_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.2, -1.8)
		add_child(muzzle)

	if not has_node("Fuselage"):
		var fuse := MeshInstance3D.new()
		fuse.name = "Fuselage"
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 0.7, 3.8)
		fuse.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.65, 0.7, 0.75) # Metalizado aluminio P-51
		mat.metallic = 0.85
		mat.roughness = 0.3
		fuse.material_override = mat
		add_child(fuse)

	if not has_node("SingleWing"):
		var wing := MeshInstance3D.new()
		wing.name = "SingleWing"
		var box_w := BoxMesh.new()
		box_w.size = Vector3(5.2, 0.08, 1.1)
		wing.mesh = box_w
		wing.position = Vector3(0.0, 0.0, -0.1)
		var mat_w := StandardMaterial3D.new()
		mat_w.albedo_color = Color(0.6, 0.65, 0.7)
		mat_w.metallic = 0.85
		wing.material_override = mat_w
		add_child(wing)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if estado_vuelo != "aterrizado":
		position.y = altura_vuelo

## Realiza una pasada de ametrallamiento en ráfaga sobre tierra consumiendo munición
@rpc("any_peer", "call_local")
func rpc_ametrallar_suelo(target_pos: Vector3 = Vector3.ZERO) -> int:
	if current_ammo <= 0:
		regresar_a_aerodromo()
		return 0

	current_ammo -= 1
	var impactados: int = 0
	var origen_suelo: Vector3 = target_pos if target_pos != Vector3.ZERO else Vector3(global_position.x, 0, global_position.z)

	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		var root_node := tree.root
		var candidatos: Array[Node] = []
		candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))
		candidatos.append_array(root_node.find_children("*", "StaticBody3D", true, false))

		for cand in candidatos:
			if cand == self or not is_instance_valid(cand):
				continue
			var pos_c: Vector3 = cand.global_position if cand is Node3D and cand.is_inside_tree() else cand.position
			var pos_c_plana: Vector3 = Vector3(pos_c.x, 0, pos_c.z)
			if pos_c_plana.distance_to(Vector3(origen_suelo.x, 0, origen_suelo.z)) <= 6.0:
				var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, cand as Node3D)
				if cand.has_method("recibir_dano"):
					cand.call("recibir_dano", dmg)
				elif "salud_actual" in cand:
					cand.set("salud_actual", maxf(0.0, float(cand.get("salud_actual")) - dmg))
				impactados += 1

	if current_ammo <= 0:
		regresar_a_aerodromo()

	return impactados

## Ataque directo contra un nodo objetivo específico
func ametrallar_objetivo(target: Node3D) -> bool:
	if current_ammo <= 0:
		regresar_a_aerodromo()
		return false

	current_ammo -= 1
	if is_instance_valid(target):
		var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	if current_ammo <= 0:
		regresar_a_aerodromo()
	return true

## Aborta combate y activa regreso autónomo al aeródromo
func regresar_a_aerodromo(_aerodromo_pos: Vector3 = Vector3.ZERO) -> void:
	estado_vuelo = "regresando"
	municion_agotada.emit()
	regreso_a_base_iniciado.emit()
	print("Caza_Helice_Era8 '%s': Munición agotada (0/%d). Regresando a aeródromo para rearme." % [name, max_ammo])
