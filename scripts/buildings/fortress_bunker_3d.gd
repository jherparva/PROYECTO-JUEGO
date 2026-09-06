## Fortress_Bunker_3D — Búnker de Hormigón Armado (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## Estructura defensiva pesada que hereda directamente de Tower3D.
## Salud masiva de 2200.0 HP y daño de 45.0 desde sus aspilleras blindadas.
## Proporciona vigilancia y fuego automático a 30.0m de distancia.
class_name Fortress_Bunker_3D
extends "res://scripts/buildings/tower_3d.gd"

func _init() -> void:
	super._init()
	building_name = "Búnker de Hormigón Armado"
	salud_maxima = 2200.0
	salud_actual = 2200.0
	_salud_maxima_base = 2200.0
	base_damage = 45.0
	attack_range = 30.0
	radio_vision = 34.0

func _ready() -> void:
	super._ready()
	add_to_group("bunkers")
	add_to_group("fortifications")
	_setup_bunker_visuals()

func _setup_bunker_visuals() -> void:
	if not has_node("BunkerDome"):
		var dome := MeshInstance3D.new()
		dome.name = "BunkerDome"
		var box := BoxMesh.new()
		box.size = Vector3(4.8, 1.8, 4.8)
		dome.mesh = box
		dome.position = Vector3(0.0, 0.9, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.48, 0.50, 0.49) # Hormigón armado gris
		mat.roughness = 0.95
		dome.material_override = mat
		add_child(dome)

	if not has_node("EmbrasureSlit"):
		var slit := MeshInstance3D.new()
		slit.name = "EmbrasureSlit"
		var box_s := BoxMesh.new()
		box_s.size = Vector3(1.6, 0.25, 0.4)
		slit.mesh = box_s
		slit.position = Vector3(0.0, 1.1, -2.3)
		var mat_s := StandardMaterial3D.new()
		mat_s.albedo_color = Color(0.08, 0.08, 0.08) # Aspillera oscura
		slit.material_override = mat_s
		add_child(slit)
