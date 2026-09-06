## Halberdier_Era5 — Alabardero Suizo (Edad del Renacimiento / Era 5).
##
## Extiende de Soldier3D. Unidad de infantería pesada de combate cercano con impacto MELEE_PIERCE.
## Multiplicador estricto de x1.65 contra caballería ('is_cavalry = true') y 207.0 HP (+15% vs Piquero).
class_name Halberdier_Era5
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "halberdier_era5"
	unit_name = "Alabardero Suizo"
	attack_type = "melee"
	weapon_type = "melee_pierce"
	impact_type = "MELEE_PIERCE"
	# +15% de HP sobre el piquero feudal de 180 HP = 207.0 HP
	_salud_base = 207.0
	salud_maxima = 207.0
	salud_actual = 207.0
	_daño_base = 24.0
	daño = 24.0
	rango_ataque = 3.0
	velocidad_ataque = 0.95
	speed = 4.7
	era_entrenada = 5

func _ready() -> void:
	super._ready()
	add_to_group("halberdiers")
	add_to_group("heavy_infantry")
	add_to_group("anti_cavalry")
	add_to_group("units_3d")
	_setup_halberd_visuals()

func _setup_halberd_visuals() -> void:
	if not has_node("HalberdProp"):
		var pole := MeshInstance3D.new()
		pole.name = "HalberdProp"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = 2.8
		pole.mesh = cyl
		pole.rotation_degrees = Vector3(-60, 0, 0)
		pole.position = Vector3(0.25, 0.9, -0.8)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.7, 0.75) # Hoja de hacha y pica de acero
		mat.metallic = 0.85
		pole.material_override = mat
		add_child(pole)

	if not has_node("SoldierTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "SoldierTorso"
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.9, 0.4)
		torso.mesh = box
		torso.position = Vector3(0.0, 0.9, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.78, 0.65, 0.15) # Uniforme acuchillado amarillo y negro
		torso.material_override = mat_t
		add_child(torso)
