## Church_Era4 — Iglesia Románica / Monasterio Feudal (Edad Medieval / Era 4).
##
## Hereda directamente de Temple3D polimórficamente sin duplicidad de lógica.
## Aumenta la capacidad de rezo, regeneración de fe y entrenamiento de monjes.
class_name Church_Era4
extends "res://scripts/buildings/temple_3d.gd"

func _init() -> void:
	super._init()
	building_name = "Iglesia Románica"
	salud_maxima = 950.0
	salud_actual = 950.0
	max_faith_points = 350.0
	current_faith_points = 350.0
	faith_regen_rate = 8.0 # +8 de Fe/s en Era Medieval
	radio_vision = 32.0

func _ready() -> void:
	super._ready()
	add_to_group("churches")
	add_to_group("religious_buildings")
	_setup_church_visuals()

func _setup_church_visuals() -> void:
	if not has_node("ChurchNave"):
		var nave := MeshInstance3D.new()
		nave.name = "ChurchNave"
		var box := BoxMesh.new()
		box.size = Vector3(4.5, 3.8, 7.0)
		nave.mesh = box
		nave.position = Vector3(0.0, 1.9, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.65, 0.60) # Piedra caliza románica
		mat.roughness = 0.85
		nave.material_override = mat
		add_child(nave)

	if not has_node("BellTower"):
		var tower := MeshInstance3D.new()
		tower.name = "BellTower"
		var box_t := BoxMesh.new()
		box_t.size = Vector3(2.2, 7.2, 2.2)
		tower.mesh = box_t
		tower.position = Vector3(0.0, 3.6, -2.8)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.55, 0.52, 0.48)
		tower.material_override = mat_t
		add_child(tower)
