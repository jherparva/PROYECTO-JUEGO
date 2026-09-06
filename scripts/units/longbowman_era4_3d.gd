## Longbowman_Era4 — Arquero de Tiro Largo Inglés (Edad Medieval / Era 4).
##
## Extiende de Soldier3D. Alcance base de 16.0m.
## Si pertenece a la facción Inglesa, acumula bufos nativos llegando a 19.0m con +20% de daño balístico.
class_name Longbowman_Era4
extends "res://scripts/units/soldier_3d.gd"

@export var is_english: bool = false
@export var faccion: String = ""

func _init() -> void:
	unit_id = "longbowman_era4"
	unit_name = "Arquero de Tiro Largo"
	attack_type = "ranged"
	weapon_type = "arrow"
	impact_type = "ARROW"
	projectile_type = "arrow"
	_salud_base = 130.0
	salud_maxima = 130.0
	salud_actual = 130.0
	_daño_base = 15.0
	daño = 15.0
	rango_ataque = 16.0
	velocidad_ataque = 1.2
	speed = 4.5
	era_entrenada = 4

func _ready() -> void:
	super._ready()
	add_to_group("archers")
	add_to_group("longbowmen")
	add_to_group("ranged_units")
	add_to_group("units_3d")
	_verificar_bono_ingles()
	_setup_longbow_visuals()

func _verificar_bono_ingles() -> void:
	var fac: String = faccion.to_lower()
	var civ: String = civilizacion.to_lower()
	if is_english or fac == "ingleses" or fac == "english" or civ == "ingleses" or civ == "english":
		aplicar_bono_ingles()

## Inyecta el bufo nacional inglés: 19.0m de alcance y +20% de daño balístico
func aplicar_bono_ingles() -> void:
	is_english = true
	rango_ataque = 19.0
	_daño_base = 18.0 # 15.0 * 1.20 (+20%)
	daño = 18.0
	print("Longbowman_Era4 '%s': ¡Bono Inglés activado! Rango: %.1fm, Daño: %.1f (+20%%)." % [name, rango_ataque, daño])

func _setup_longbow_visuals() -> void:
	if not has_node("LongbowProp"):
		var bow := MeshInstance3D.new()
		bow.name = "LongbowProp"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.02
		cyl.height = 1.8
		bow.mesh = cyl
		bow.rotation_degrees = Vector3(15, 0, 10)
		bow.position = Vector3(-0.35, 0.9, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.48, 0.32, 0.18) # Madera de tejo
		bow.material_override = mat
		add_child(bow)

	if not has_node("ArcherTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "ArcherTorso"
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.8, 0.35)
		torso.mesh = box
		torso.position = Vector3(0.0, 0.8, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.65, 0.22, 0.22) # Casaca roja/granate
		torso.material_override = mat_t
		add_child(torso)
