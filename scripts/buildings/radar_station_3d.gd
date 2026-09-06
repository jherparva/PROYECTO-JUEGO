## Radar_Station_3D — Estación de Radar de Fase Táctica (Edad Atómica / Era 9).
##
## Estructura de detección temprana y control del espacio aéreo que hereda directamente de Tower3D.
## Rango masivo de visión de 65.0 metros, disipando la niebla de guerra continuamente.
## Emite pulsos de barrido que revelan la posición de aeronaves y unidades aéreas enemigas.
class_name Radar_Station_3D
extends "res://scripts/buildings/tower_3d.gd"

signal pulso_radar_emitido(aeronaves_detectadas: int)

@export var frecuencia_pulso: float = 2.5
var _pulso_timer: float = 0.0

func _init() -> void:
	super._init()
	building_name = "Estación de Radar Táctica"
	salud_maxima = 2400.0
	salud_actual = 2400.0
	_salud_maxima_base = 2400.0
	radio_vision = 65.0 # Rango estricto de 65.0 metros
	attack_range = 65.0
	base_damage = 30.0

func _ready() -> void:
	super._ready()
	add_to_group("radars")
	add_to_group("military_buildings")
	_setup_radar_dome_visuals()

func _setup_radar_dome_visuals() -> void:
	if not has_node("ConcreteBase"):
		var base := MeshInstance3D.new()
		base.name = "ConcreteBase"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 3.5
		cyl.bottom_radius = 3.8
		cyl.height = 2.2
		base.mesh = cyl
		base.position = Vector3(0.0, 1.1, 0.0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.42, 0.44, 0.46)
		base.material_override = mat_b
		add_child(base)

	if not has_node("GeodesicDome"):
		var dome := MeshInstance3D.new()
		dome.name = "GeodesicDome"
		var sphere := SphereMesh.new()
		sphere.radius = 2.8
		sphere.height = 3.2
		dome.mesh = sphere
		dome.position = Vector3(0.0, 3.4, 0.0)
		var mat_d := StandardMaterial3D.new()
		mat_d.albedo_color = Color(0.88, 0.9, 0.92) # Blanco/gris cúpula radar
		mat_d.roughness = 0.4
		dome.material_override = mat_d
		add_child(dome)

## Emite un pulso de radar en red que localiza y revela toda unidad en vuelo dentro de 65.0m
func emitir_pulso_radar() -> Array[Node3D]:
	var detectadas: Array[Node3D] = []
	var centro: Vector3 = position if position != Vector3.ZERO else (global_position if is_inside_tree() else position)
	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root
	elif Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root:
		root_node = (Engine.get_main_loop() as SceneTree).root
	elif get_parent():
		root_node = get_parent()

	if not is_instance_valid(root_node):
		return detectadas

	var candidatos: Array[Node] = []
	candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))

	for cand in candidatos:
		if cand == self or not is_instance_valid(cand) or not (cand is Node3D):
			continue
		var cand_3d := cand as Node3D
		var pos_c: Vector3 = cand_3d.position if cand_3d.position != Vector3.ZERO else cand_3d.global_position
		if pos_c.distance_to(centro) <= radio_vision:
			if cand.is_in_group("air_units") or cand.is_in_group("aircraft") or cand.get("is_aircraft") == true or pos_c.y >= 5.0:
				if cand.has_method("ser_revelado_por_radar"):
					cand.call("ser_revelado_por_radar", self)
				elif "is_invisible" in cand:
					cand.set("is_invisible", false)
				detectadas.append(cand_3d)

	pulso_radar_emitido.emit(detectadas.size())
	return detectadas
