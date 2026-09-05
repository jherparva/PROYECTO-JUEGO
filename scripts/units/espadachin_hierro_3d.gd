## Espadachin_Hierro — Infantería Pesada de la Edad de Hierro (Era 3).
##
## Unidad de choque de primera línea con espada de hierro forjado y escudo grande.
## Tipo de impacto: MELEE_SHOCK.
## Estadísticas oficiales de dbunitset.dat: HP 180, Daño 22.0, armadura reforzada.
class_name Espadachin_Hierro
extends "res://scripts/units/soldier_3d.gd"

var formacion_escudo: bool = true
var shield_mesh: MeshInstance3D = null

func _init() -> void:
	unit_id = "espadachin_hierro"
	unit_name = "Espadachín de Hierro"
	attack_type = "melee"
	weapon_type = "sword"
	impact_type = "MELEE_SHOCK"
	_salud_base = 180.0
	salud_maxima = 180.0
	salud_actual = 180.0
	_daño_base = 22.0
	daño = 22.0
	rango_ataque = 3.2
	velocidad_ataque = 0.85
	speed = 5.0
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("swordsmen")
	add_to_group("infantry_3d")
	add_to_group("heavy_infantry")
	_setup_shield_mesh()

func _setup_shield_mesh() -> void:
	if not has_node("ShieldMesh"):
		shield_mesh = MeshInstance3D.new()
		shield_mesh.name = "ShieldMesh"
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.8, 0.1)
		shield_mesh.mesh = box
		shield_mesh.position = Vector3(0.35, 0.8, -0.3)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.48, 0.52) # Hierro forjado
		mat.metallic = 0.85
		mat.roughness = 0.3
		shield_mesh.material_override = mat
		add_child(shield_mesh)
	else:
		shield_mesh = get_node("ShieldMesh") as MeshInstance3D
