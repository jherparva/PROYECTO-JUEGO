## Ametralladora_Maxim — Artillería de Supresión de Trinchera (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## Unidad de soporte de rango medio con camisa de enfriamiento por agua y escudo de trinchera.
## Dispara ráfagas continuas de 4 proyectiles balísticos por segundo desde su 'ProjectileMuzzle'
## a un solo objetivo terrestre, aplicando fuego de supresión que ralentiza en un -30% por 2.0s.
class_name Ametralladora_Maxim
extends "res://scripts/units/soldier_3d.gd"

signal rafaga_maxim_disparada(target: Node3D, cantidad: int)

var disparos_por_rafaga: int = 4
var duracion_supresion: float = 2.0
var cooldown_rafaga: float = 1.0
var tiempo_cooldown: float = 0.0

func _init() -> void:
	unit_id = "ametralladora_maxim"
	unit_name = "Ametralladora Maxim"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 240.0
	salud_maxima = 240.0
	salud_actual = 240.0
	_daño_base = 16.0
	daño = 16.0
	rango_ataque = 22.0
	velocidad_ataque = 1.0
	speed = 2.6
	era_entrenada = 7

func _ready() -> void:
	super._ready()
	add_to_group("maxims")
	add_to_group("artillery")
	add_to_group("siege_units")
	add_to_group("ranged_units")
	add_to_group("units_3d")
	_setup_maxim_visuals()

func _setup_maxim_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.9, -1.3)
		add_child(muzzle)

	if not has_node("GunShield"):
		var shield := MeshInstance3D.new()
		shield.name = "GunShield"
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 0.8, 0.06)
		shield.mesh = box
		shield.position = Vector3(0.0, 0.9, -0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.24, 0.25, 0.22)
		mat.metallic = 0.8
		shield.material_override = mat
		add_child(shield)

	if not has_node("WaterJacketBarrel"):
		var barrel := MeshInstance3D.new()
		barrel.name = "WaterJacketBarrel"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.09
		cyl.bottom_radius = 0.09
		cyl.height = 1.1
		barrel.mesh = cyl
		barrel.position = Vector3(0.0, 0.9, -0.7)
		barrel.rotation_degrees = Vector3(90, 0, 0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.18, 0.18, 0.2)
		mat_b.metallic = 0.9
		barrel.material_override = mat_b
		add_child(barrel)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if tiempo_cooldown > 0.0:
		tiempo_cooldown = maxf(0.0, tiempo_cooldown - delta)

## Dispara ráfaga de 4 tiros aplicando daño y debuff de supresión (-30% de velocidad)
func disparar_rafaga_maxim(target: Node3D = null) -> int:
	if tiempo_cooldown > 0.0:
		return 0

	tiempo_cooldown = cooldown_rafaga
	var count: int = disparos_por_rafaga

	if is_instance_valid(target):
		# Aplicar debuff de supresión (-30% vel por 2.0s)
		if target.has_method("aplicar_supresion"):
			target.call("aplicar_supresion", duracion_supresion)
		for i in range(count):
			var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
			if target.has_method("recibir_dano"):
				target.call("recibir_dano", dmg)
			elif "salud_actual" in target:
				target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	rafaga_maxim_disparada.emit(target, count)
	return count
