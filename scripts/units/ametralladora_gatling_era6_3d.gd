## Ametralladora_Gatling — Artillería Ligera de Ráfaga a Manivela (Edad Industrial / Era 6).
##
## Unidad mecánica de soporte a distancia que dispara ráfagas continuas de 5 proyectiles balísticos
## por segundo desde su 'ProjectileMuzzle' a un solo objetivo, con un cooldown local de 1.2s.
class_name Ametralladora_Gatling
extends "res://scripts/units/soldier_3d.gd"

signal rafaga_gatling_disparada(proyectiles: int)

var disparos_por_rafaga: int = 5
var cooldown_rafaga: float = 1.2
var tiempo_cooldown_restante: float = 0.0
var is_mechanical: bool = true

func _init() -> void:
	unit_id = "ametralladora_gatling"
	unit_name = "Ametralladora Gatling"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 220.0
	salud_maxima = 220.0
	salud_actual = 220.0
	_daño_base = 14.0
	daño = 14.0
	rango_ataque = 18.0
	velocidad_ataque = 1.2
	speed = 2.8
	era_entrenada = 6

func _ready() -> void:
	super._ready()
	add_to_group("gatlings")
	add_to_group("artillery")
	add_to_group("siege_units")
	add_to_group("ranged_units")
	add_to_group("units_3d")
	_setup_gatling_visuals()

func _setup_gatling_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.9, -1.2)
		add_child(muzzle)

	if not has_node("TripodStand"):
		var tripod := MeshInstance3D.new()
		tripod.name = "TripodStand"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.1
		cyl.bottom_radius = 0.6
		cyl.height = 0.8
		tripod.mesh = cyl
		tripod.position = Vector3(0.0, 0.4, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.22)
		tripod.material_override = mat
		add_child(tripod)

	if not has_node("BarrelCluster"):
		var barrels := MeshInstance3D.new()
		barrels.name = "BarrelCluster"
		var cyl_b := CylinderMesh.new()
		cyl_b.top_radius = 0.12
		cyl_b.bottom_radius = 0.12
		cyl_b.height = 1.0
		barrels.mesh = cyl_b
		barrels.position = Vector3(0.0, 0.9, -0.6)
		barrels.rotation_degrees = Vector3(90, 0, 0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.7, 0.6, 0.3) # Bronce de cañones
		mat_b.metallic = 0.8
		barrels.material_override = mat_b
		add_child(barrels)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if tiempo_cooldown_restante > 0.0:
		tiempo_cooldown_restante = maxf(0.0, tiempo_cooldown_restante - delta)

## Ejecuta la ráfaga de 5 disparos consecutivos de alta velocidad
func disparar_rafaga_gatling(target: Node3D = null) -> int:
	if tiempo_cooldown_restante > 0.0:
		return 0

	var count: int = disparos_por_rafaga
	tiempo_cooldown_restante = cooldown_rafaga
	rafaga_gatling_disparada.emit(count)

	if is_instance_valid(target) and target.has_method("recibir_dano"):
		for i in range(count):
			var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
			target.call("recibir_dano", dmg)

	return count
