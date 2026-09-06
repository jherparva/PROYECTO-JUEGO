## AntiTank_Soldier_Era9 — Soldado de Infantería Pesada Anti-Tanque (Edad Atómica / Era 9).
##
## Especialista táctico equipado con lanzamisiles guiado portátil (tipo Javelin/Stinger).
## Dispara proyectiles perforantes desde su socket ProjectileMuzzle.
## Inflige un multiplicador estricto de x2.5 contra vehículos blindados y tanques.
class_name AntiTank_Soldier_Era9
extends "res://scripts/units/soldier_3d.gd"

signal misil_antitanque_disparado(target_pos: Vector3)

func _init() -> void:
	unit_id = "anti_tank_soldier_era9"
	unit_name = "Soldado Anti-Tanque"
	attack_type = "ranged"
	weapon_type = "missile"
	impact_type = "PIERCE"
	projectile_type = "rocket"
	_salud_base = 220.0
	salud_maxima = 220.0
	salud_actual = 220.0
	_daño_base = 45.0
	daño = 45.0
	rango_ataque = 16.0
	velocidad_ataque = 2.0
	speed = 4.2
	era_entrenada = 9

func _ready() -> void:
	super._ready()
	add_to_group("antitanks")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_antitank_visuals()

func _setup_antitank_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.25, 1.35, -1.0)
		add_child(muzzle)

	if not has_node("MissileLauncher"):
		var tube := MeshInstance3D.new()
		tube.name = "MissileLauncher"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 1.6
		tube.mesh = cyl
		tube.rotation_degrees = Vector3(90, 0, 0)
		tube.position = Vector3(0.25, 1.35, -0.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.28, 0.22) # Verde camuflaje militar
		tube.material_override = mat
		add_child(tube)

## Dispara un misil guiado antitanque contra el objetivo
func disparar_misil_antitanque(target: Node3D) -> float:
	if not is_instance_valid(target):
		return 0.0

	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	misil_antitanque_disparado.emit(target.position if target.position != Vector3.ZERO else target.global_position)
	return dmg
