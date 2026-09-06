## SpecOps_Era9 — Operador de Fuerzas Especiales Contemporáneo (Edad Atómica / Era 9).
##
## Infantería táctica avanzada equipada con visor térmico nocturno cuádruple (NVG).
## Tipo de impacto 'GUN', daño de rango 35.0 desde su ProjectileMuzzle.
## Su visión térmica anula por completo la invisibilidad de tiradores de élite y unidades
## sigilosas enemigas dentro de su radio de escaneo activo.
class_name SpecOps_Era9
extends "res://scripts/units/soldier_3d.gd"

signal objetivos_revelados(cantidad: int)

@export var radio_escaneo_termico: float = 25.0

func _init() -> void:
	unit_id = "spec_ops_era9"
	unit_name = "Operador SpecOps"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	has_thermal_vision = true
	_salud_base = 230.0
	salud_maxima = 230.0
	salud_actual = 230.0
	_daño_base = 35.0
	daño = 35.0
	rango_ataque = 24.0
	velocidad_ataque = 0.9
	speed = 5.0
	era_entrenada = 9

func _ready() -> void:
	super._ready()
	add_to_group("spec_ops")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_specops_visuals()

func _setup_specops_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.8)
		add_child(muzzle)

	if not has_node("NVGGoggles"):
		var nvg := MeshInstance3D.new()
		nvg.name = "NVGGoggles"
		var box := BoxMesh.new()
		box.size = Vector3(0.24, 0.08, 0.16)
		nvg.mesh = box
		nvg.position = Vector3(0.0, 1.68, -0.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.85, 0.2) # Verde fósforo térmico
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.85, 0.2)
		mat.emission_energy_multiplier = 1.8
		nvg.material_override = mat
		add_child(nvg)

## Escanea el área circundante y desactiva el camuflaje/invisibilidad de unidades enemigas
func escanear_termico(radio: float = 0.0) -> int:
	var r: float = radio if radio > 0.0 else radio_escaneo_termico
	var centro: Vector3 = position if position != Vector3.ZERO else (global_position if is_inside_tree() else position)
	var detectados: int = 0

	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root
	elif Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root:
		root_node = (Engine.get_main_loop() as SceneTree).root
	elif get_parent():
		root_node = get_parent()

	if not is_instance_valid(root_node):
		return 0

	var candidatos: Array[Node] = []
	candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))

	for cand in candidatos:
		if cand == self or not is_instance_valid(cand) or not (cand is Node3D):
			continue
		var cand_3d := cand as Node3D
		var pos_c: Vector3 = cand_3d.position if cand_3d.position != Vector3.ZERO else (cand_3d.global_position if cand_3d.is_inside_tree() else cand_3d.position)
		if pos_c.distance_to(centro) <= r:
			if cand.get("is_invisible") == true:
				cand.set("is_invisible", false)
				if cand.has_method("establecer_sigilo"):
					cand.call("establecer_sigilo", false)
				detectados += 1

	if detectados > 0:
		objetivos_revelados.emit(detectados)
	return detectados
