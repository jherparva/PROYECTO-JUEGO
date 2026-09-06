## Foundry_Era5 — Fundición de Artillería (Edad del Renacimiento / Era 5).
##
## Edificio militar de artillería pesada que hereda directamente de Barracks3D.
## Se habilita si GlobalResourceManager.era_actual >= 5.
## Reutiliza limpiamente la cola de producción, cálculo de perímetro y emergencia vertical desde el 8%.
class_name Foundry_Era5
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "foundry"

func _init() -> void:
	super._init()
	building_name = "Fundición de Artillería"
	salud_maxima = 1250.0
	salud_actual = 1250.0
	_salud_maxima_base = 1250.0
	radio_vision = 30.0

func _ready() -> void:
	super._ready()
	add_to_group("foundries")
	add_to_group("artillery_buildings")
	_setup_foundry_visuals()

func _setup_foundry_visuals() -> void:
	if not has_node("FoundryFurnace"):
		var furnace := MeshInstance3D.new()
		furnace.name = "FoundryFurnace"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.4
		cyl.bottom_radius = 2.0
		cyl.height = 4.8
		furnace.mesh = cyl
		furnace.position = Vector3(1.8, 2.4, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.28, 0.26) # Ladrillo refractario oscuro
		mat.roughness = 0.9
		furnace.material_override = mat
		add_child(furnace)

	if not has_node("FoundryHall"):
		var hall := MeshInstance3D.new()
		hall.name = "FoundryHall"
		var box := BoxMesh.new()
		box.size = Vector3(5.0, 3.2, 5.0)
		hall.mesh = box
		hall.position = Vector3(-1.0, 1.6, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.48, 0.46, 0.44) # Mampostería de piedra
		hall.material_override = mat_h
		add_child(hall)
