## Humanode_Plasma — Sintético de Energía Pura (Edad Nano-Futurista / Era 11).
##
## Entidad de energía fotónica de 450 HP.
## Su Fusil Gauss de Riel en el socket ProjectileMuzzle dispara ráfagas de plasma tipo 'ENERGY/Láser'
## que infligen un daño base de 48.0, aplicando un multiplicador de daño estricto de x3.0 exclusivamente
## contra aeronaves, cazas furtivos y unidades del grupo 'air_units' como antiaéreo definitivo.
class_name Humanode_Plasma
extends "res://scripts/units/soldier_3d.gd"

signal plasma_disparado(objetivo: Node3D, dano: float)

func _init() -> void:
	unit_id = "humanoide_plasma_era11"
	unit_name = "Sintético de Plasma"
	attack_type = "ranged"
	weapon_type = "energy"
	impact_type = "ENERGY"
	projectile_type = "plasma"
	_salud_base = 450.0
	salud_maxima = 450.0
	salud_actual = 450.0
	_daño_base = 48.0
	daño = 48.0
	rango_ataque = 22.0
	velocidad_ataque = 1.0
	speed = 5.0
	era_entrenada = 11

func _ready() -> void:
	super._ready()
	add_to_group("plasma_synthetics")
	add_to_group("anti_air")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_plasma_visuals()

func _setup_plasma_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.25, -0.85)
		add_child(muzzle)

	if not has_node("GaussRifle"):
		var rifle := MeshInstance3D.new()
		rifle.name = "GaussRifle"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 1.2
		rifle.mesh = cyl
		rifle.rotation_degrees = Vector3(90, 0, 0)
		rifle.position = Vector3(0.3, 1.15, -0.5)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.3, 1.0) # Violeta / plasma fotónico
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.2, 1.0)
		mat.emission_energy_multiplier = 3.0
		rifle.material_override = mat
		add_child(rifle)

## Dispara una descarga de plasma gauss contra el objetivo
func disparar_gauss_plasma(target: Node3D) -> float:
	if not is_instance_valid(target) or is_dead:
		return 0.0

	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "energy", self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif target.has_method("recibir_daño"):
		target.call("recibir_daño", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	plasma_disparado.emit(target, dmg)
	return dmg
