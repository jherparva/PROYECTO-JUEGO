## CyberCenter3D — Centro Cibernético Táctico (Edad Digital / Era 10).
##
## Infraestructura cibernética mayor que hereda limpiamente de Barracks3D.
## Emerge verticalmente desde el 8% de altura durante la construcción.
## Gestiona la producción y encolado de infantería nanotecnológica y especialistas EMP.
class_name CyberCenter3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "cyber_center"

func _init() -> void:
	super._init()
	building_name = "Centro Cibernético"
	salud_maxima = 2600.0
	salud_actual = 2600.0
	_salud_maxima_base = 2600.0
	radio_vision = 42.0

func _ready() -> void:
	super._ready()
	building_name = "Centro Cibernético"
	add_to_group("cyber_centers")
	add_to_group("military_buildings")
	_setup_cyber_center_visuals()

func _setup_cyber_center_visuals() -> void:
	if not has_node("CyberTower"):
		var tower := MeshInstance3D.new()
		tower.name = "CyberTower"
		var box := BoxMesh.new()
		box.size = Vector3(5.0, 5.5, 5.0)
		tower.mesh = box
		tower.position = Vector3(0.0, 2.75, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.06, 0.08, 0.12) # Cromo oscuro reflectivo
		mat_t.metallic = 0.95
		mat_t.roughness = 0.15
		tower.material_override = mat_t
		add_child(tower)

	if not has_node("NeonAntenna"):
		var ant := MeshInstance3D.new()
		ant.name = "NeonAntenna"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.18
		cyl.height = 3.5
		ant.mesh = cyl
		ant.position = Vector3(0.0, 7.0, 0.0)
		var mat_a := StandardMaterial3D.new()
		mat_a.albedo_color = Color(0.0, 0.9, 1.0)
		mat_a.emission_enabled = true
		mat_a.emission = Color(0.0, 0.95, 1.0)
		mat_a.emission_energy_multiplier = 4.0
		ant.material_override = mat_a
		add_child(ant)
