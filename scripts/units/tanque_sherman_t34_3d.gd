## Tanque_Sherman_T34 — Blindado de Combate Medio WWII (Edad Atómica / Era 8).
##
## Blindado estándar de choque y apoyo acorazado con 380.0 HP y velocidad de 5.2 m/s.
## Inmune al aturdimiento (is_stun_immune = true).
## Impacto balístico GUN con multiplicador x1.50 contra transportes y unidades mecanizadas.
class_name Tanque_Sherman_T34
extends "res://scripts/units/soldier_3d.gd"

signal canion_disparado(pos_impacto: Vector3)

func _init() -> void:
	unit_id = "tanque_sherman_t34"
	unit_name = "Tanque Sherman T-34"
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "GUN"
	projectile_type = "bullet"
	is_cavalry = true
	is_stun_immune = true
	_salud_base = 380.0
	salud_maxima = 380.0
	salud_actual = 380.0
	_daño_base = 55.0
	daño = 55.0
	rango_ataque = 22.0
	velocidad_ataque = 1.8
	speed = 5.2
	era_entrenada = 8

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("vehicles_3d")
	add_to_group("shermans")
	add_to_group("cavalry")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_sherman_visuals()

func _setup_sherman_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.4, -2.4)
		add_child(muzzle)

	if not has_node("ChassisMesh"):
		var chassis := MeshInstance3D.new()
		chassis.name = "ChassisMesh"
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 1.1, 4.2)
		chassis.mesh = box
		chassis.position = Vector3(0.0, 0.55, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.35, 0.25) # Verde militar oliva
		chassis.material_override = mat
		add_child(chassis)

	if not has_node("TurretMesh"):
		var turret := MeshInstance3D.new()
		turret.name = "TurretMesh"
		var box_t := BoxMesh.new()
		box_t.size = Vector3(1.5, 0.7, 1.8)
		turret.mesh = box_t
		turret.position = Vector3(0.0, 1.45, 0.1)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.26, 0.31, 0.22)
		turret.material_override = mat_t
		add_child(turret)

	if not has_node("CannonBarrel"):
		var cannon := MeshInstance3D.new()
		cannon.name = "CannonBarrel"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		cyl.height = 2.0
		cannon.mesh = cyl
		cannon.rotation_degrees = Vector3(90, 0, 0)
		cannon.position = Vector3(0.0, 1.45, -1.4)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.18, 0.2, 0.16)
		cannon.material_override = mat_c
		add_child(cannon)

## Anula cualquier aturdimiento aplicado
func aplicar_stun(_duracion: float = 1.0) -> bool:
	return false

## Disparo balístico del cañón 76mm
func disparar_canon_principal(target: Node3D) -> float:
	if not is_instance_valid(target):
		return 0.0

	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	canion_disparado.emit(target.global_position if target.is_inside_tree() else target.position)
	return dmg
