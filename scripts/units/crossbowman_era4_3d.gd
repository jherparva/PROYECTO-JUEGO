## Crossbowman_Era4 — Ballestero Medieval de Alta Perforación (Edad Medieval / Era 4).
##
## Extiende de Soldier3D. Dispara virotes pesados tipo PIERCE de alta velocidad.
## Ignora de forma pasiva un 35% del valor de armadura pesada mediante 'calcular_perforacion_ballesta()'.
class_name Crossbowman_Era4
extends "res://scripts/units/soldier_3d.gd"

var porcentaje_perforacion: float = 0.35

func _init() -> void:
	unit_id = "crossbowman_era4"
	unit_name = "Ballestero Medieval"
	attack_type = "ranged"
	weapon_type = "arrow"
	impact_type = "PIERCE"
	projectile_type = "bolt"
	_salud_base = 140.0
	salud_maxima = 140.0
	salud_actual = 140.0
	_daño_base = 22.0
	daño = 22.0
	rango_ataque = 12.0
	velocidad_ataque = 1.5
	speed = 4.4
	era_entrenada = 4

func _ready() -> void:
	super._ready()
	add_to_group("archers")
	add_to_group("crossbowmen")
	add_to_group("ranged_units")
	add_to_group("units_3d")
	_setup_crossbow_visuals()

func _setup_crossbow_visuals() -> void:
	if not has_node("CrossbowProp"):
		var cb := MeshInstance3D.new()
		cb.name = "CrossbowProp"
		var box_cb := BoxMesh.new()
		box_cb.size = Vector3(0.5, 0.15, 0.7)
		cb.mesh = box_cb
		cb.position = Vector3(0.3, 0.8, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.28, 0.18)
		cb.material_override = mat
		add_child(cb)

	if not has_node("CrossbowmanTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "CrossbowmanTorso"
		var box := BoxMesh.new()
		box.size = Vector3(0.55, 0.85, 0.35)
		torso.mesh = box
		torso.position = Vector3(0.0, 0.85, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.28, 0.45, 0.32) # Túnica verde bosque y cuero
		torso.material_override = mat_t
		add_child(torso)

## Función oficial que reduce pasivamente en un 35% el valor de armadura del objetivo
func calcular_perforacion_ballesta(armadura_objetivo: float) -> float:
	var armadura_reducida: float = armadura_objetivo * (1.0 - porcentaje_perforacion)
	return maxf(0.0, armadura_reducida)
