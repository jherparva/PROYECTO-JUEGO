## M1Abrams_Tank — Blindado de Asalto Pesado Contemporáneo (Edad Atómica / Era 9).
##
## Coloso acorazado con blindaje compuesto Chobham.
## HP masivo de 520.0, velocidad de 5.5 m/s e inmunidad absoluta al stun (is_stun_immune = true).
## Su cañón de 120mm de ánima lisa inflige multiplicador x2.5 vs estructuras y genera un área
## de impacto explosivo AoE de 4.0 metros de radio.
class_name M1Abrams_Tank
extends "res://scripts/units/soldier_3d.gd"

signal disparo_abrams_efectuado(pos_impacto: Vector3, objetivos_afectados: int)

var is_vehicle: bool = true
var radio_aoe: float = 4.0

func _init() -> void:
	unit_id = "m1_abrams_tank"
	unit_name = "Tanque M1 Abrams"
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "GUN"
	projectile_type = "bullet"
	is_cavalry = true
	is_tank = true
	is_stun_immune = true
	_salud_base = 520.0
	salud_maxima = 520.0
	salud_actual = 520.0
	_daño_base = 80.0
	daño = 80.0
	rango_ataque = 24.0
	velocidad_ataque = 2.0
	speed = 5.5
	era_entrenada = 9

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("vehicles_3d")
	add_to_group("tanks")
	add_to_group("abrams")
	add_to_group("cavalry")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_abrams_visuals()

func _setup_abrams_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.4, -2.6)
		add_child(muzzle)

	if not has_node("ChassisMesh"):
		var chassis := MeshInstance3D.new()
		chassis.name = "ChassisMesh"
		var box := BoxMesh.new()
		box.size = Vector3(2.6, 1.1, 4.8)
		chassis.mesh = box
		chassis.position = Vector3(0.0, 0.55, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.62, 0.48) # Camuflaje arena desértico
		chassis.material_override = mat
		add_child(chassis)

	if not has_node("TurretMesh"):
		var turret := MeshInstance3D.new()
		turret.name = "TurretMesh"
		var box_t := BoxMesh.new()
		box_t.size = Vector3(2.0, 0.7, 2.8)
		turret.mesh = box_t
		turret.position = Vector3(0.0, 1.4, -0.1)
		var mat_t := StandardMaterial3D.new()
		mat_t.albedo_color = Color(0.65, 0.58, 0.44)
		turret.material_override = mat_t
		add_child(turret)

	if not has_node("Cannon120mm"):
		var cannon := MeshInstance3D.new()
		cannon.name = "Cannon120mm"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.09
		cyl.bottom_radius = 0.11
		cyl.height = 2.6
		cannon.mesh = cyl
		cannon.rotation_degrees = Vector3(90, 0, 0)
		cannon.position = Vector3(0.0, 1.4, -1.8)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.2, 0.2, 0.2)
		cannon.material_override = mat_c
		add_child(cannon)

## Inmunidad absoluta a aturdimiento
func aplicar_stun(_duracion: float = 1.0) -> bool:
	return false

## Disparo de proyectil de 120mm con detonación de área de 4.0m
func disparar_canon_abrams(target_pos: Vector3) -> Array[Node3D]:
	var impactados: Array[Node3D] = []
	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root
	elif Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root:
		root_node = (Engine.get_main_loop() as SceneTree).root
	elif get_parent():
		root_node = get_parent()

	if not is_instance_valid(root_node):
		return impactados

	var candidatos: Array[Node] = []
	candidatos.append_array(root_node.find_children("*", "CharacterBody3D", true, false))
	candidatos.append_array(root_node.find_children("*", "StaticBody3D", true, false))

	for cand in candidatos:
		if cand == self or not is_instance_valid(cand) or not (cand is Node3D):
			continue
		var cand_3d := cand as Node3D
		var pos_c: Vector3 = cand_3d.position if cand_3d.position != Vector3.ZERO else (cand_3d.global_position if cand_3d.is_inside_tree() else cand_3d.position)
		if pos_c.distance_to(target_pos) <= radio_aoe:
			var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, cand_3d)
			if cand.has_method("recibir_dano"):
				cand.call("recibir_dano", dmg)
			elif "salud_actual" in cand:
				cand.set("salud_actual", maxf(0.0, float(cand.get("salud_actual")) - dmg))
			impactados.append(cand_3d)

	disparo_abrams_efectuado.emit(target_pos, impactados.size())
	return impactados
