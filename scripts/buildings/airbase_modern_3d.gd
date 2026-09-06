## Airbase_Modern_3D — Base Aérea Contemporánea (Edad Atómica / Era 9).
##
## Infraestructura militar aérea mayor que hereda limpiamente de Barracks3D.
## Emerge verticalmente desde el 8% de altura durante la construcción.
## Gestiona la producción y reabastecimiento de Cazas F-15 Jet y Helicópteros Apache.
class_name Airbase_Modern_3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "airbase"

func _init() -> void:
	super._init()
	building_name = "Base Aérea Moderna"
	salud_maxima = 2600.0
	salud_actual = 2600.0
	_salud_maxima_base = 2600.0
	radio_vision = 50.0

func _ready() -> void:
	super._ready()
	add_to_group("airbases")
	add_to_group("military_buildings")
	_setup_airbase_modern_visuals()

func _setup_airbase_modern_visuals() -> void:
	if not has_node("HeavyRunway"):
		var runway := MeshInstance3D.new()
		runway.name = "HeavyRunway"
		var box := BoxMesh.new()
		box.size = Vector3(8.0, 0.15, 20.0)
		runway.mesh = box
		runway.position = Vector3(0.0, 0.08, 0.0)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.24, 0.25, 0.28) # Hormigón armado para reactores
		runway.material_override = mat_r
		add_child(runway)

	if not has_node("ReinforcedHangar"):
		var hangar := MeshInstance3D.new()
		hangar.name = "ReinforcedHangar"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(7.0, 4.2, 8.0)
		hangar.mesh = box_h
		hangar.position = Vector3(7.5, 2.1, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.38, 0.4, 0.42)
		hangar.material_override = mat_h
		add_child(hangar)

	if not has_node("RadarTower"):
		var tower := MeshInstance3D.new()
		tower.name = "RadarTower"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.0
		cyl.bottom_radius = 1.3
		cyl.height = 6.5
		tower.mesh = cyl
		tower.position = Vector3(-6.0, 3.25, 5.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.5, 0.52, 0.55)
		tower.material_override = mat_t
		add_child(tower)
