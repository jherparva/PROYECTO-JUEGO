## Mosquetero_Era5 — Mosquetero de Línea de Fuego (Edad del Renacimiento / Era 5).
##
## Extiende de Soldier3D. Dispara salvas de pólvora tipo GUN desde el socket 'ProjectileMuzzle'.
## Incorpora una penetración pasiva de armadura del 25% (is_armor_piercing_gun = true)
## mediante la función 'calcular_penetracion_polvora()'.
class_name Mosquetero_Era5
extends "res://scripts/units/soldier_3d.gd"

var is_armor_piercing_gun: bool = true
var porcentaje_penetracion_polvora: float = 0.25

func _init() -> void:
	unit_id = "mosquetero_era5"
	unit_name = "Mosquetero de Pólvora"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 150.0
	salud_maxima = 150.0
	salud_actual = 150.0
	_daño_base = 24.0
	daño = 24.0
	rango_ataque = 18.0
	velocidad_ataque = 1.8
	speed = 4.3
	era_entrenada = 5

func _ready() -> void:
	super._ready()
	add_to_group("musketeers")
	add_to_group("gunpowder_units")
	add_to_group("ranged_units")
	add_to_group("units_3d")
	_setup_mosquetero_visuals()

func _setup_mosquetero_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.25, 1.1, -1.0)
		add_child(muzzle)

	if not has_node("MusketProp"):
		var musket := MeshInstance3D.new()
		musket.name = "MusketProp"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.04
		cyl.height = 1.6
		musket.mesh = cyl
		musket.rotation_degrees = Vector3(-80, 0, 0)
		musket.position = Vector3(0.25, 1.0, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.22, 0.22, 0.24) # Cañón de hierro fundido
		mat.metallic = 0.9
		musket.material_override = mat
		add_child(musket)

	if not has_node("SoldierTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "SoldierTorso"
		var box := BoxMesh.new()
		box.size = Vector3(0.55, 0.85, 0.35)
		torso.mesh = box
		torso.position = Vector3(0.0, 0.85, 0.0)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.18, 0.32, 0.58) # Casaca azul renacentista
		torso.material_override = mat_t
		add_child(torso)

## Reduce en un 25% la mitigación de armadura pesada o de placas del objetivo
func calcular_penetracion_polvora(armadura_objetivo: float) -> float:
	var reduccion: float = armadura_objetivo * (1.0 - porcentaje_penetracion_polvora)
	return maxf(0.0, reduccion)
