## Airfield_WWII_3D — Aeródromo Moderno WWII (Edad Atómica / Era 8).
##
## Estructura militar aérea avanzada que hereda limpiamente de Barracks3D.
## Habilitada en la Era 8 (GlobalResourceManager.era_actual >= 8).
## Administra la cola de producción y rearme de unidades aéreas 'Caza_Helice_Era8'.
## Emerge verticalmente desde el 8% de altura durante su construcción.
class_name Airfield_WWII_3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "airfield"

func _init() -> void:
	super._init()
	building_name = "Aeródromo Moderno WWII"
	salud_maxima = 1800.0
	salud_actual = 1800.0
	_salud_maxima_base = 1800.0
	radio_vision = 40.0

func _ready() -> void:
	super._ready()
	add_to_group("airfields")
	add_to_group("military_buildings")
	_setup_airfield_wwii_visuals()

func _setup_airfield_wwii_visuals() -> void:
	if not has_node("AsphaltRunway"):
		var runway := MeshInstance3D.new()
		runway.name = "AsphaltRunway"
		var box := BoxMesh.new()
		box.size = Vector3(6.5, 0.12, 16.0)
		runway.mesh = box
		runway.position = Vector3(0.0, 0.06, 0.0)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.2, 0.22, 0.24) # Asfalto oscuro
		runway.material_override = mat_r
		add_child(runway)

	if not has_node("CorrugatedHangar"):
		var hangar := MeshInstance3D.new()
		hangar.name = "CorrugatedHangar"
		var prism := PrismMesh.new()
		prism.size = Vector3(5.0, 3.4, 6.5)
		hangar.mesh = prism
		hangar.position = Vector3(5.5, 1.7, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.45, 0.48, 0.5) # Chapa galvanizada
		hangar.material_override = mat_h
		add_child(hangar)

	if not has_node("ControlTower"):
		var tower := MeshInstance3D.new()
		tower.name = "ControlTower"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.8
		cyl.bottom_radius = 1.0
		cyl.height = 5.0
		tower.mesh = cyl
		tower.position = Vector3(-4.5, 2.5, 4.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.6, 0.62, 0.58)
		tower.material_override = mat_t
		add_child(tower)
