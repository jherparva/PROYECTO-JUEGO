## Soldado_EMP — Especialista en Pulso Electromagnético Táctico (Edad Digital / Era 10).
##
## Unidad de asalto y soporte cibernético equipada con lanzador de ondas EMP.
## Al impactar vehículos, tanques o aeronaves enemigas, desata una descarga electromagnética
## síncrona por RPC que paraliza completamente su FSM ('is_disabled = true', velocidad 0 y ataque
## cancelado) durante 4.5 segundos estrictos.
class_name Soldado_EMP
extends "res://scripts/units/soldier_3d.gd"

signal pulso_emp_disparado(objetivo: Node3D, exito: bool)

@export var duracion_desactivacion_emp: float = 4.5

func _init() -> void:
	unit_id = "soldado_emp_era10"
	unit_name = "Soldado de Pulso EMP"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "SHOCK"
	projectile_type = "bullet"
	_salud_base = 250.0
	salud_maxima = 250.0
	salud_actual = 250.0
	_daño_base = 30.0
	daño = 30.0
	rango_ataque = 18.0
	velocidad_ataque = 1.2
	speed = 4.8
	era_entrenada = 10

func _ready() -> void:
	super._ready()
	add_to_group("emp_soldiers")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_emp_visuals()

func _setup_emp_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.8)
		add_child(muzzle)

	if not has_node("EMPCannon"):
		var cannon := MeshInstance3D.new()
		cannon.name = "EMPCannon"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.16
		cyl.height = 1.1
		cannon.mesh = cyl
		cannon.rotation_degrees = Vector3(90, 0, 0)
		cannon.position = Vector3(0.28, 1.1, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.4, 0.9) # Azul arco eléctrico
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.5, 1.0)
		mat.emission_energy_multiplier = 2.5
		cannon.material_override = mat
		add_child(cannon)

## Dispara una onda electromagnética dirigida contra el objetivo
func disparar_pulso_emp(target: Node3D) -> bool:
	if not is_instance_valid(target):
		return false

	var es_mecanizado: bool = false
	if "is_vehicle" in target and target.get("is_vehicle") == true:
		es_mecanizado = true
	elif "is_tank" in target and target.get("is_tank") == true:
		es_mecanizado = true
	elif target.is_in_group("vehicles_3d") or target.is_in_group("tanks") or target.is_in_group("air_units") or target.is_in_group("aircraft"):
		es_mecanizado = true
	elif "is_aircraft" in target and target.get("is_aircraft") == true:
		es_mecanizado = true

	# Daño de impacto base
	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif target.has_method("recibir_daño"):
		target.call("recibir_daño", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	# Aplicar debuff de congelación FSM si es mecanizado
	if es_mecanizado:
		if target.has_method("aplicar_desactivacion_emp"):
			target.call("aplicar_desactivacion_emp", duracion_desactivacion_emp)
		else:
			target.set("is_disabled", true)
			if "velocity" in target:
				target.set("velocity", Vector3.ZERO)
			# Desactivar temporalmente durante 4.5s
			_restaurar_desactivacion_async(target, duracion_desactivacion_emp)

	pulso_emp_disparado.emit(target, es_mecanizado)
	return es_mecanizado

func _restaurar_desactivacion_async(target: Node3D, tiempo: float) -> void:
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		await tree.create_timer(tiempo).timeout
		if is_instance_valid(target):
			target.set("is_disabled", false)
