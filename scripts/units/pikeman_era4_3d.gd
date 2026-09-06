## Pikeman_Era4 — Piquero Medieval de Contra-Choque (Edad Medieval / Era 4).
##
## Extiende de Soldier3D con tipo de impacto MELEE_PIERCE.
## Aplica un multiplicador de daño estricto de x2.0 contra unidades de caballería y carros ecuestres.
class_name Pikeman_Era4
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "pikeman_era4"
	unit_name = "Piquero Medieval"
	attack_type = "melee"
	weapon_type = "melee_pierce"
	impact_type = "MELEE_PIERCE"
	_salud_base = 180.0
	salud_maxima = 180.0
	salud_actual = 180.0
	_daño_base = 20.0
	daño = 20.0
	rango_ataque = 3.2
	velocidad_ataque = 0.9
	speed = 4.8
	era_entrenada = 4

func _ready() -> void:
	super._ready()
	add_to_group("pikemen")
	add_to_group("infantry_3d")
	add_to_group("anti_cavalry")
	add_to_group("units_3d")
	_setup_pike_visuals()

func _setup_pike_visuals() -> void:
	if not has_node("LongPike"):
		var pike := MeshInstance3D.new()
		pike.name = "LongPike"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.04
		cyl.height = 3.4
		pike.mesh = cyl
		# Orientada hacia adelante en posición de guardia anti-carga
		pike.rotation_degrees = Vector3(-65, 0, 0)
		pike.position = Vector3(0.25, 0.8, -1.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.65, 0.65, 0.7) # Acero templado en punta
		mat.metallic = 0.8
		pike.material_override = mat
		add_child(pike)

	if not has_node("PikemanTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "PikemanTorso"
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.9, 0.4)
		torso.mesh = box
		torso.position = Vector3(0.0, 0.9, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.6, 0.2, 0.2) # Gambesón acolchado rojo
		torso.material_override = mat_t
		add_child(torso)
