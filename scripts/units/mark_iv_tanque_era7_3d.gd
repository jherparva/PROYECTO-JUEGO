## MarkIV_Tanque_Orugas — El Primer Tanque de la Historia (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## Vehículo blindado pesado con silueta romboidal y orugas envolventes completas.
## Salud masiva de 400.0 HP. Inmunidad total al aturdimiento (is_stun_immune = true).
## Cuenta con dos barbetas laterales (Muzzle_Left y Muzzle_Right) con capacidad de disparar
## simultáneamente a dos objetivos distintos dentro de su radio de escaneo.
class_name MarkIV_Tanque_Orugas
extends "res://scripts/units/soldier_3d.gd"

signal disparo_barbetas_dobles(left_target: Node3D, right_target: Node3D)

var is_vehicle: bool = true

func _init() -> void:
	unit_id = "mark_iv_tanque"
	unit_name = "Tanque Mark IV"
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "GUNPOWDER"
	projectile_type = "bullet"
	is_cavalry = true
	is_stun_immune = true
	_salud_base = 400.0
	salud_maxima = 400.0
	salud_actual = 400.0
	_daño_base = 35.0
	daño = 35.0
	rango_ataque = 20.0
	velocidad_ataque = 2.0
	speed = 2.8
	era_entrenada = 7

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("tanks")
	add_to_group("vehicles")
	add_to_group("vehicles_3d")
	add_to_group("siege_units")
	add_to_group("units_3d")
	_setup_markiv_visuals()

func _setup_markiv_visuals() -> void:
	# Barbeta izquierda (Muzzle_Left)
	if not has_node("Muzzle_Left"):
		var m_l := Marker3D.new()
		m_l.name = "Muzzle_Left"
		m_l.position = Vector3(-1.6, 1.1, 0.0)
		add_child(m_l)

	# Barbeta derecha (Muzzle_Right)
	if not has_node("Muzzle_Right"):
		var m_r := Marker3D.new()
		m_r.name = "Muzzle_Right"
		m_r.position = Vector3(1.6, 1.1, 0.0)
		add_child(m_r)

	if not has_node("RhomboidHull"):
		var hull := MeshInstance3D.new()
		hull.name = "RhomboidHull"
		var box := BoxMesh.new()
		box.size = Vector3(2.6, 1.8, 4.4)
		hull.mesh = box
		hull.position = Vector3(0.0, 0.9, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.29, 0.25) # Verde grisáceo acorazado
		mat.metallic = 0.8
		mat.roughness = 0.5
		hull.material_override = mat
		add_child(hull)

	if not has_node("SponsonLeft"):
		var sp_l := MeshInstance3D.new()
		sp_l.name = "SponsonLeft"
		var box_l := BoxMesh.new()
		box_l.size = Vector3(0.6, 0.8, 1.4)
		sp_l.mesh = box_l
		sp_l.position = Vector3(-1.4, 1.0, 0.0)
		var mat_s := StandardMaterial3D.new()
		mat_s.albedo_color = Color(0.22, 0.23, 0.20)
		sp_l.material_override = mat_s
		add_child(sp_l)

	if not has_node("SponsonRight"):
		var sp_r := MeshInstance3D.new()
		sp_r.name = "SponsonRight"
		var box_r := BoxMesh.new()
		box_r.size = Vector3(0.6, 0.8, 1.4)
		sp_r.mesh = box_r
		sp_r.position = Vector3(1.4, 1.0, 0.0)
		var mat_sr := StandardMaterial3D.new()
		mat_sr.albedo_color = Color(0.22, 0.23, 0.20)
		sp_r.material_override = mat_sr
		add_child(sp_r)

## Dispara simultáneamente a dos objetivos independientes desde las barbetas laterales
func disparar_barbetas_dobles(left_target: Node3D, right_target: Node3D) -> Dictionary:
	var disparos: Dictionary = {"left_hit": false, "right_hit": false}

	if is_instance_valid(left_target):
		disparos["left_hit"] = true
		var dmg_l: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, left_target)
		if left_target.has_method("recibir_dano"):
			left_target.call("recibir_dano", dmg_l)
		elif "salud_actual" in left_target:
			left_target.set("salud_actual", maxf(0.0, float(left_target.get("salud_actual")) - dmg_l))

	if is_instance_valid(right_target):
		disparos["right_hit"] = true
		var dmg_r: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, right_target)
		if right_target.has_method("recibir_dano"):
			right_target.call("recibir_dano", dmg_r)
		elif "salud_actual" in right_target:
			right_target.set("salud_actual", maxf(0.0, float(right_target.get("salud_actual")) - dmg_r))

	disparo_barbetas_dobles.emit(left_target, right_target)
	return disparos
