## Airfield_WWI_3D — Aeródromo de Lienzo / Pista Primitiva (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## Estructura aérea de apoyo que hereda directamente de Barracks3D.
## Se habilita si GlobalResourceManager.era_actual >= 7 (o era_actual == 7).
## Gestiona la cola de producción y reabastecimiento para la unidad aérea 'Biplano_Fokker_Era7'.
## Emerge verticalmente desde el 8% de altura.
class_name Airfield_WWI_3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "airfield"

func _init() -> void:
	super._init()
	building_name = "Aeródromo de Lienzo"
	salud_maxima = 1400.0
	salud_actual = 1400.0
	_salud_maxima_base = 1400.0
	radio_vision = 35.0

func _ready() -> void:
	super._ready()
	add_to_group("airfields")
	add_to_group("military_buildings")
	_setup_airfield_visuals()

func _setup_airfield_visuals() -> void:
	if not has_node("DirtRunway"):
		var runway := MeshInstance3D.new()
		runway.name = "DirtRunway"
		var box := BoxMesh.new()
		box.size = Vector3(5.0, 0.1, 12.0)
		runway.mesh = box
		runway.position = Vector3(0.0, 0.05, 0.0)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.42, 0.36, 0.28) # Tierra apisonada
		runway.material_override = mat_r
		add_child(runway)

	if not has_node("CanvasHangar"):
		var hangar := MeshInstance3D.new()
		hangar.name = "CanvasHangar"
		var prism := PrismMesh.new()
		prism.size = Vector3(4.0, 2.8, 5.0)
		hangar.mesh = prism
		hangar.position = Vector3(4.5, 1.4, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.72, 0.68, 0.58) # Lona beige militar
		hangar.material_override = mat_h
		add_child(hangar)

	if not has_node("Windsock"):
		var sock := MeshInstance3D.new()
		sock.name = "Windsock"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.04
		cyl.height = 3.5
		sock.mesh = cyl
		sock.position = Vector3(-3.5, 1.75, 5.0)
		var mat_s := StandardMaterial3D.new()
		mat_s.albedo_color = Color(0.7, 0.7, 0.7)
		sock.material_override = mat_s
		add_child(sock)
