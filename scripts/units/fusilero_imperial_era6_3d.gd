## Fusilero_Imperial — Fusilero con Bayoneta (Edad Industrial / Era 6).
##
## Unidad militar de infantería de línea con impacto balístico 'GUN' y daño de rango 28.0.
## Incorpora ataque secundario melee automático en la FSM: conmuta a estocada con bayoneta
## con daño tipo 'Slashing' / 'bayonet' si un enemigo se encuentra a distancia cercana (<= 2.0m).
class_name Fusilero_Imperial
extends "res://scripts/units/soldier_3d.gd"

signal modo_combate_cambiado(nuevo_modo: String)

var modo_combate: String = "rango_fusil"
var dano_bayoneta: float = 24.0
var umbral_distancia_bayoneta: float = 2.0

func _init() -> void:
	unit_id = "fusilero_imperial"
	unit_name = "Fusilero Imperial"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 175.0
	salud_maxima = 175.0
	salud_actual = 175.0
	_daño_base = 28.0
	daño = 28.0
	rango_ataque = 20.0
	velocidad_ataque = 1.7
	speed = 4.4
	era_entrenada = 6

func _ready() -> void:
	super._ready()
	add_to_group("fusileros")
	add_to_group("ranged_infantry")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_fusilero_visuals()

func _setup_fusilero_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.3, 1.2, -0.9)
		add_child(muzzle)

	if not has_node("MusketRifle"):
		var rifle := MeshInstance3D.new()
		rifle.name = "MusketRifle"
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.12, 1.2)
		rifle.mesh = box
		rifle.position = Vector3(0.3, 1.1, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.18, 0.12) # Madera oscura de nogal
		rifle.material_override = mat
		add_child(rifle)

	if not has_node("BayonetBlade"):
		var bayonet := MeshInstance3D.new()
		bayonet.name = "BayonetBlade"
		var prism := BoxMesh.new()
		prism.size = Vector3(0.03, 0.06, 0.35)
		bayonet.mesh = prism
		bayonet.position = Vector3(0.3, 1.1, -1.05)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.85, 0.88, 0.90) # Acero templado brillante
		mat_b.metallic = 0.9
		bayonet.material_override = mat_b
		add_child(bayonet)

## Ejecuta la evaluación y ataque de la FSM según la distancia al objetivo
func ejecutar_ataque_fusilero(target: Node3D) -> Dictionary:
	if not is_instance_valid(target):
		return {}

	var dist: float = 999.0
	if is_inside_tree() and target.is_inside_tree():
		dist = global_position.distance_to(target.global_position)
	else:
		dist = position.distance_to(target.position)

	if dist <= umbral_distancia_bayoneta:
		# Conmutación automática a bayoneta melee
		if modo_combate != "melee_bayoneta":
			modo_combate = "melee_bayoneta"
			modo_combate_cambiado.emit(modo_combate)
		var melee_dmg: float = CombatDamageCalculator.calcular_dano(dano_bayoneta, "bayonet", self, target)
		return {
			"modo": "melee_bayoneta",
			"tipo_dano": "Slashing",
			"dano": melee_dmg,
			"distancia": dist
		}
	else:
		# Ataque balístico a distancia con fusil
		if modo_combate != "rango_fusil":
			modo_combate = "rango_fusil"
			modo_combate_cambiado.emit(modo_combate)
		var ranged_dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
		return {
			"modo": "rango_fusil",
			"tipo_dano": "GUN",
			"dano": ranged_dmg,
			"distancia": dist
		}
