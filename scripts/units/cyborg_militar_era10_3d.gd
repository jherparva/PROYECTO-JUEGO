## Cyborg_Militar — Humanoide Cibernético de Asalto Pesado (Edad Digital / Era 10).
##
## Coloso blindado de infantería pesada con chasis de titanio y servomotores avanzados.
## Salud masiva de 400.0 HP e inmunidad total a efectos de ralentización ('is_slow_immune = true').
## Incorpora una minigun rotatoria de alta velocidad capaz de desatar ráfagas de 8 proyectiles por segundo.
class_name Cyborg_Militar
extends "res://scripts/units/soldier_3d.gd"

signal rafaga_cyborg_disparada(proyectiles: int)

@export var cadencia_disparo: float = 8.0 # 8 proyectiles por segundo
var _timer_cadencia: float = 0.0

func _init() -> void:
	unit_id = "cyborg_militar_era10"
	unit_name = "Cyborg Militar Pesado"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	is_slow_immune = true
	_salud_base = 400.0
	salud_maxima = 400.0
	salud_actual = 400.0
	_daño_base = 28.0
	daño = 28.0
	rango_ataque = 20.0
	velocidad_ataque = 0.125 # 1.0 / 8.0 = 0.125s por disparo
	speed = 4.6
	era_entrenada = 10

func _ready() -> void:
	super._ready()
	add_to_group("cyborgs")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_cyborg_visuals()

func _setup_cyborg_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.35, 1.1, -0.8)
		add_child(muzzle)

	if not has_node("MinigunArm"):
		var gun := MeshInstance3D.new()
		gun.name = "MinigunArm"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.14
		cyl.bottom_radius = 0.14
		cyl.height = 1.0
		gun.mesh = cyl
		gun.rotation_degrees = Vector3(90, 0, 0)
		gun.position = Vector3(0.35, 1.1, -0.3)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.22, 0.26) # Titanio oscuro
		mat.metallic = 0.95
		mat.roughness = 0.15
		gun.material_override = mat
		add_child(gun)

	if not has_node("CyberEye"):
		var eye := MeshInstance3D.new()
		eye.name = "CyberEye"
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.05, 0.08)
		eye.mesh = box
		eye.position = Vector3(0.08, 1.65, -0.38)
		var mat_e := StandardMaterial3D.new()
		mat_e.albedo_color = Color(1.0, 0.05, 0.1) # Óptica carmesí cibernética
		mat_e.emission_enabled = true
		mat_e.emission = Color(1.0, 0.05, 0.1)
		mat_e.emission_energy_multiplier = 3.0
		eye.material_override = mat_e
		add_child(eye)

## Inmunidad absoluta a efectos de supresión y ralentización
@rpc("any_peer", "call_local", "reliable")
func aplicar_supresion(_duracion: float = 2.0) -> void:
	# El Cyborg es inmune a la ralentización
	return

## Dispara una ráfaga a ritmo de 8 proyectiles/segundo durante la fracción de tiempo delta
func disparar_rafaga_cyborg(target: Node3D, delta: float = 1.0) -> int:
	if not is_instance_valid(target) or is_disabled:
		return 0

	var disparos_a_ejecutar: int = int(round(cadencia_disparo * delta))
	if disparos_a_ejecutar <= 0:
		disparos_a_ejecutar = 1

	var impactos_exitosos: int = 0
	for i in range(disparos_a_ejecutar):
		var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg)
		elif target.has_method("recibir_daño"):
			target.call("recibir_daño", dmg)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))
		impactos_exitosos += 1

	rafaga_cyborg_disparada.emit(impactos_exitosos)
	return impactos_exitosos
