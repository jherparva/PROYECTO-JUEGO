## HazmatWorker_Era8 — Técnico Biológico Hazmat (Edad Atómica / Era 8).
##
## Unidad civil especializada no combatiente con traje NBQ (Nuclear, Biológico, Químico).
## Inmunidad absoluta contra áreas de daño radioactivo / químico DoT (is_radiation_immune = true).
## Capaz de descontaminar zonas de radiación o recursos irradiados.
class_name HazmatWorker_Era8
extends "res://scripts/units/soldier_3d.gd"

signal zona_descontaminada(centro: Vector3, radio: float)

func _init() -> void:
	unit_id = "hazmat_worker_era8"
	unit_name = "Técnico Biológico Hazmat"
	attack_type = "melee"
	weapon_type = "none"
	impact_type = "NONE"
	_salud_base = 160.0
	salud_maxima = 160.0
	salud_actual = 160.0
	_daño_base = 0.0
	daño = 0.0
	rango_ataque = 0.0
	velocidad_ataque = 1.0
	speed = 4.8
	era_entrenada = 8
	is_radiation_immune = true
	is_civilian = true

func _ready() -> void:
	super._ready()
	add_to_group("hazmat_workers")
	add_to_group("villagers")
	add_to_group("civilians")
	add_to_group("units_3d")
	_setup_hazmat_visuals()

func _setup_hazmat_visuals() -> void:
	if not has_node("HazmatHelmet"):
		var helm := MeshInstance3D.new()
		helm.name = "HazmatHelmet"
		var sphere := SphereMesh.new()
		sphere.radius = 0.26
		sphere.height = 0.35
		helm.mesh = sphere
		helm.position = Vector3(0.0, 1.7, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.8, 0.1) # Amarillo Hazmat reflectante
		helm.material_override = mat
		add_child(helm)

	if not has_node("OxygenTank"):
		var tank := MeshInstance3D.new()
		tank.name = "OxygenTank"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 0.7
		tank.mesh = cyl
		tank.position = Vector3(0.0, 1.1, 0.3)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.85, 0.85, 0.85)
		tank.material_override = mat_t
		add_child(tank)

## Limpia y neutraliza zonas o focos de radiación en un radio determinado
func descontaminar_zona(centro: Vector3 = Vector3.ZERO, radio: float = 10.0) -> int:
	var origen: Vector3 = centro if centro != Vector3.ZERO else global_position
	var zonas_limpiadas: int = 0
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if not is_instance_valid(tree):
		return 0

	var root_node := tree.root
	var radiation_nodes: Array[Node] = root_node.find_children("*", "Area3D", true, false)
	for r_node in radiation_nodes:
		if r_node.is_in_group("radiation_zones") or "radiation" in r_node.name.to_lower():
			if r_node is Node3D and (r_node as Node3D).global_position.distance_to(origen) <= radio:
				r_node.queue_free()
				zonas_limpiadas += 1

	zona_descontaminada.emit(origen, radio)
	return zonas_limpiadas

## Descontamina un recurso o nodo individual
func descontaminar_recurso(recurso: Node3D) -> bool:
	if not is_instance_valid(recurso):
		return false
	if recurso.is_in_group("irradiated_resources"):
		recurso.remove_from_group("irradiated_resources")
	if recurso.has_method("limpiar_radiacion"):
		recurso.call("limpiar_radiacion")
	return true
