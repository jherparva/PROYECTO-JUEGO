## Conquistador_Era5 — Conquistador Ecuestre (Edad del Renacimiento / Era 5).
##
## Unidad de caballería de rango ligera ('is_cavalry = true').
## Combina alta movilidad (6.2 m/s) con disparos cortos de pistola de rueda.
## Multiplicador estricto de x1.30 contra infantería ligera de choque.
class_name Conquistador_Era5
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "conquistador_era5"
	unit_name = "Conquistador Ecuestre"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	is_cavalry = true
	_salud_base = 220.0
	salud_maxima = 220.0
	salud_actual = 220.0
	_daño_base = 22.0
	daño = 22.0
	rango_ataque = 10.0
	velocidad_ataque = 1.4
	speed = 6.2 # 6.2 m/s carrera ecuestre
	era_entrenada = 5

func _ready() -> void:
	super._ready()
	add_to_group("cavalry")
	add_to_group("ranged_cavalry")
	add_to_group("conquistadors")
	add_to_group("gunpowder_units")
	add_to_group("units_3d")
	_setup_conquistador_visuals()

func _setup_conquistador_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.35, 1.4, -0.9)
		add_child(muzzle)

	if not has_node("HorseBody"):
		var horse := MeshInstance3D.new()
		horse.name = "HorseBody"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(0.85, 1.1, 2.1)
		horse.mesh = box_h
		horse.position = Vector3(0.0, 0.55, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.24, 0.16, 0.12)
		horse.material_override = mat_h
		add_child(horse)

	if not has_node("RiderTorso"):
		var rider := MeshInstance3D.new()
		rider.name = "RiderTorso"
		var box_r := BoxMesh.new()
		box_r.size = Vector3(0.6, 0.8, 0.45)
		rider.mesh = box_r
		rider.position = Vector3(0.0, 1.4, -0.1)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.65, 0.65, 0.7) # Coraza de acero brillante
		mat_r.metallic = 0.85
		mat_r.roughness = 0.3
		rider.material_override = mat_r
		add_child(rider)
