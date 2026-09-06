## Caballero_Pesado — Caballería Blindada Pesada Feudal (Edad Medieval / Era 4).
##
## Extiende de Soldier3D e incorpora el flag is_cavalry = true.
## Velocidad base calibrada a 6.0 m/s, impacto MELEE_SHOCK, multiplicador x1.50 vs arqueros.
class_name Caballero_Pesado
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "caballero_pesado"
	unit_name = "Caballero Pesado"
	attack_type = "melee"
	weapon_type = "melee_shock"
	impact_type = "MELEE_SHOCK"
	is_cavalry = true
	_salud_base = 280.0
	salud_maxima = 280.0
	salud_actual = 280.0
	_daño_base = 32.0
	daño = 32.0
	rango_ataque = 3.6
	velocidad_ataque = 0.95
	speed = 6.0
	era_entrenada = 4

func _ready() -> void:
	super._ready()
	add_to_group("cavalry")
	add_to_group("heavy_cavalry")
	add_to_group("knights")
	add_to_group("heavy_knights")
	add_to_group("units_3d")
	_setup_knight_visuals()

func _setup_knight_visuals() -> void:
	if not has_node("HorseBody"):
		var horse := MeshInstance3D.new()
		horse.name = "HorseBody"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(0.9, 1.2, 2.2)
		horse.mesh = box_h
		horse.position = Vector3(0.0, 0.6, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.35, 0.22, 0.14)
		horse.material_override = mat_h
		add_child(horse)

	if not has_node("BardingArmor"):
		var barding := MeshInstance3D.new()
		barding.name = "BardingArmor"
		var box_b := BoxMesh.new()
		box_b.size = Vector3(1.0, 0.9, 1.6)
		barding.mesh = box_b
		barding.position = Vector3(0.0, 0.7, 0.1)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.75, 0.75, 0.8) # Malla de acero
		mat_b.metallic = 0.85
		mat_b.roughness = 0.25
		barding.material_override = mat_b
		add_child(barding)

	if not has_node("KnightTorso"):
		var rider := MeshInstance3D.new()
		rider.name = "KnightTorso"
		var box_r := BoxMesh.new()
		box_r.size = Vector3(0.65, 0.8, 0.6)
		rider.mesh = box_r
		rider.position = Vector3(0.0, 1.6, -0.1)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.2, 0.3, 0.6) # Túnica heráldica azul y acero
		mat_r.metallic = 0.7
		rider.material_override = mat_r
		add_child(rider)
