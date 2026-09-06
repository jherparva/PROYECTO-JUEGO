## Caza_Reaccion_Era9 — Caza a Reacción Supersónico F-15 Jet (Edad Atómica / Era 9).
##
## Aeronave supersónica de alta superioridad aérea.
## Navega en una capa física fija en el eje Y (Y = 16.0m) a velocidad extrema de 18.0 m/s.
## Realiza pasadas de ataque disparando misiles aire-tierra guiados térmicos.
## Capacidad máxima de 2 ataques con misiles (max_ammo = 2), tras los cuales conmuta
## automáticamente a estado 'regresando' hacia la Base Aérea para reabastecimiento.
class_name Caza_Reaccion_Era9
extends "res://scripts/units/soldier_3d.gd"

signal municion_agotada()
signal regreso_a_base_iniciado()
signal aterrizaje_completado()

var altura_vuelo: float = 16.0
var max_ammo: int = 2
var current_ammo: int = 2
var estado_vuelo: String = "patrulla" # "patrulla", "ataque", "regresando"
var is_aircraft: bool = true

func _init() -> void:
	unit_id = "caza_reaccion_era9"
	unit_name = "Caza F-15 Jet"
	attack_type = "ranged"
	weapon_type = "missile"
	impact_type = "EXPLOSIVE"
	projectile_type = "rocket"
	_salud_base = 260.0
	salud_maxima = 260.0
	salud_actual = 260.0
	_daño_base = 60.0
	daño = 60.0
	rango_ataque = 28.0
	velocidad_ataque = 1.0
	speed = 18.0
	era_entrenada = 9

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("air_units")
	add_to_group("aircraft")
	add_to_group("military_units")
	add_to_group("units_3d")
	position.y = altura_vuelo
	_setup_jet_visuals()

func _setup_jet_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.2, -2.4)
		add_child(muzzle)

	if not has_node("Fuselage"):
		var fuse := MeshInstance3D.new()
		fuse.name = "Fuselage"
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 0.8, 4.6)
		fuse.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.48, 0.52) # Gris stealth militar
		mat.metallic = 0.9
		mat.roughness = 0.25
		fuse.material_override = mat
		add_child(fuse)

	if not has_node("DeltaWings"):
		var wing := MeshInstance3D.new()
		wing.name = "DeltaWings"
		var prism := PrismMesh.new()
		prism.size = Vector3(5.6, 0.08, 2.2)
		wing.mesh = prism
		wing.rotation_degrees = Vector3(90, 0, 0)
		wing.position = Vector3(0.0, 0.0, -0.3)
		var mat_w := StandardMaterial3D.new()
		mat_w.albedo_color = Color(0.4, 0.43, 0.47)
		mat_w.metallic = 0.9
		wing.material_override = mat_w
		add_child(wing)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if estado_vuelo != "aterrizado":
		position.y = altura_vuelo

## Ataque supersónico por RPC sobre una coordenada terrestre
@rpc("any_peer", "call_local")
func rpc_ataque_supersonico(target_pos: Vector3 = Vector3.ZERO) -> int:
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

	if current_ammo <= 0:
		regresar_a_base()

	return impactados

## Ataque guiado contra una unidad objetivo específica
func disparar_misil_reaccion(target: Node3D) -> bool:
	if current_ammo <= 0:
		regresar_a_base()
		return false

	current_ammo -= 1
	if is_instance_valid(target):
		var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	if current_ammo <= 0:
		regresar_a_base()
	return true

## Aborta combate y regresa de forma autónoma a la base aérea para rearmarse
func regresar_a_base(_base_pos: Vector3 = Vector3.ZERO) -> void:
	estado_vuelo = "regresando"
	municion_agotada.emit()
	regreso_a_base_iniciado.emit()
	print("Caza_Reaccion_Era9 '%s': Munición agotada (0/%d). Regresando a base aérea." % [name, max_ammo])
