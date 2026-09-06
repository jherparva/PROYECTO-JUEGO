## RoboticsLab3D — Laboratorio de Robótica con Domos de Policarbonato (Edad Digital / Era 10).
##
## Complejo tecnológico militar de última generación que hereda limpiamente de Barracks3D.
## Emerge progresivamente desde el 8% de altura durante su construcción.
## Gestiona la producción sincronizada de Cyborgs Militares y unidades robóticas de Era 10.
class_name RoboticsLab3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "robotics_lab"

func _init() -> void:
	super._init()
	building_name = "Laboratorio de Robótica"
	salud_maxima = 2800.0
	salud_actual = 2800.0
	_salud_maxima_base = 2800.0
	radio_vision = 45.0

func _ready() -> void:
	super._ready()
	building_name = "Laboratorio de Robótica"
	add_to_group("robotics_labs")
	add_to_group("military_buildings")
	_setup_robotics_lab_visuals()

func _setup_robotics_lab_visuals() -> void:
	if not has_node("LabMainBase"):
		var base_m := MeshInstance3D.new()
		base_m.name = "LabMainBase"
		var box := BoxMesh.new()
		box.size = Vector3(6.5, 2.8, 6.5)
		base_m.mesh = box
		base_m.position = Vector3(0.0, 1.4, 0.0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.12, 0.14, 0.18) # Titanio/cromo oscuro
		mat_b.metallic = 0.9
		mat_b.roughness = 0.2
		base_m.material_override = mat_b
		add_child(base_m)

	if not has_node("PolycarbonateDome"):
		var dome := MeshInstance3D.new()
		dome.name = "PolycarbonateDome"
		var sphere := SphereMesh.new()
		sphere.radius = 2.4
		sphere.height = 2.6
		dome.mesh = sphere
		dome.position = Vector3(0.0, 2.8, 0.0)
		var mat_d := StandardMaterial3D.new()
		mat_d.albedo_color = Color(0.0, 0.6, 0.9, 0.75) # Policarbonato traslúcido cian
		mat_d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_d.metallic = 0.3
		mat_d.roughness = 0.1
		dome.material_override = mat_d
		add_child(dome)

	if not has_node("NeonTrims"):
		var neon := MeshInstance3D.new()
		neon.name = "NeonTrims"
		var torus := TorusMesh.new()
		torus.inner_radius = 2.5
		torus.outer_radius = 2.65
		neon.mesh = torus
		neon.position = Vector3(0.0, 2.7, 0.0)
		var mat_n := StandardMaterial3D.new()
		mat_n.albedo_color = Color(0.0, 0.9, 1.0)
		mat_n.emission_enabled = true
		mat_n.emission = Color(0.0, 0.95, 1.0)
		mat_n.emission_energy_multiplier = 3.0
		neon.material_override = mat_n
		add_child(neon)
