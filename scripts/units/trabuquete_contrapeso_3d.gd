## Trabuquete_Contrapeso — Súper Asedio Medieval por Contrapeso (Edad Medieval / Era 4).
##
## Unidad de asedio estática masiva de rango extra-largo (45.0m).
## Requiere pasar por un estado de despliegue 'is_deployed = true' (duración 3.0s con velocidad = 0)
## antes de poder disparar sus rocas ardientes con daño AoE de 5.0m contra edificios.
class_name Trabuquete_Contrapeso
extends "res://scripts/units/soldier_3d.gd"

signal desplegado()
signal plegado()
signal disparo_efectuado(pos_destino: Vector3)

var is_deployed: bool = false
var is_deploying: bool = false
var deploy_time_required: float = 3.0
var deploy_timer: float = 0.0
var radio_aoe: float = 5.0

func _init() -> void:
	unit_id = "trabuquete_contrapeso"
	unit_name = "Trabuquete de Contrapeso"
	attack_type = "ranged"
	weapon_type = "siege_stone"
	impact_type = "SIEGE"
	projectile_type = "fire_stone"
	_salud_base = 320.0
	salud_maxima = 320.0
	salud_actual = 320.0
	_daño_base = 120.0
	daño = 120.0
	rango_ataque = 45.0
	velocidad_ataque = 4.0
	speed = 2.5
	era_entrenada = 4

func _ready() -> void:
	super._ready()
	add_to_group("siege_units")
	add_to_group("trebuchets")
	add_to_group("units_3d")
	_setup_trebuchet_visuals()

func _process(delta: float) -> void:
	if is_deploying:
		deploy_timer += delta
		if deploy_timer >= deploy_time_required:
			is_deploying = false
			is_deployed = true
			speed = 0.0 # Completamente inmóvil en posición de asedio
			desplegado.emit()
			print("Trabuquete_Contrapeso '%s': ¡Despliegue de asedio completado! Listo para disparar a 45m." % name)

## Inicia la secuencia obligatoria de anclaje de 3.0 segundos
func desplegar() -> void:
	if is_deployed:
		return
	is_deploying = true
	deploy_timer = 0.0
	speed = 0.0
	print("Trabuquete_Contrapeso '%s': Iniciando anclaje y armado de contrapeso (3.0s)..." % name)

## Pliega la maquinaria para reanudar el transporte sobre ruedas
func plegar() -> void:
	is_deployed = false
	is_deploying = false
	deploy_timer = 0.0
	speed = 2.5
	plegado.emit()
	print("Trabuquete_Contrapeso '%s': Maquinaria plegada. Movilidad restaurada a 2.5 m/s." % name)

## Dispara proyectil de roca ardiente contra la posición objetivo
func disparar_trabuquete(pos_impacto: Vector3) -> bool:
	if not is_deployed:
		print("Trabuquete_Contrapeso '%s': ERROR - La unidad no puede disparar sin estar desplegada." % name)
		return false

	disparo_efectuado.emit(pos_impacto)
	aplicar_dano_aoe_edificios(pos_impacto, radio_aoe, daño)
	return true

## Aplica el daño de área de efecto (AoE de 5.0m) contra edificios
func aplicar_dano_aoe_edificios(pos_impacto: Vector3, radio: float = 5.0, cantidad_dano: float = 120.0) -> Array[Node3D]:
	var afectados: Array[Node3D] = []
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if not is_instance_valid(tree):
		var ml = Engine.get_main_loop()
		if ml is SceneTree:
			tree = ml

	var candidatos: Array[Node] = []
	if is_instance_valid(tree):
		candidatos.append_array(tree.get_nodes_in_group("buildings"))
		candidatos.append_array(tree.get_nodes_in_group("buildings_3d"))
		candidatos.append_array(tree.get_nodes_in_group("walls"))
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if is_instance_valid(child) and child is Node3D and not candidatos.has(child):
					candidatos.append(child)
	elif is_instance_valid(get_parent()):
		for child in get_parent().get_children():
			if is_instance_valid(child) and child is Node3D and not candidatos.has(child):
				candidatos.append(child)

	for bld in candidatos:
		if not is_instance_valid(bld) or bld == self:
			continue
		if not (bld is Node3D):
			continue
		var bld_3d := bld as Node3D
		var pos_b: Vector3 = bld_3d.position if bld_3d.position != Vector3.ZERO else bld_3d.global_position
		var dist: float = pos_b.distance_to(pos_impacto)
		if dist <= radio:
			afectados.append(bld_3d)
			if bld.has_method("recibir_dano"):
				bld.call("recibir_dano", cantidad_dano, self)
			elif bld.has_method("take_damage"):
				bld.call("take_damage", cantidad_dano)
			elif "salud_actual" in bld:
				bld.set("salud_actual", maxf(0.0, float(bld.get("salud_actual")) - cantidad_dano))

	print("Trabuquete_Contrapeso '%s': Impacto AoE 5.0m en %s. Estructuras alcanzadas: %d." % [name, pos_impacto, afectados.size()])
	return afectados

func _setup_trebuchet_visuals() -> void:
	if not has_node("TrebuchetChassis"):
		var chassis := MeshInstance3D.new()
		chassis.name = "TrebuchetChassis"
		var box := BoxMesh.new()
		box.size = Vector3(1.8, 1.0, 2.6)
		chassis.mesh = box
		chassis.position = Vector3(0.0, 0.5, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.38, 0.25, 0.15)
		chassis.material_override = mat
		add_child(chassis)

	if not has_node("TrebuchetBeam"):
		var beam := MeshInstance3D.new()
		beam.name = "TrebuchetBeam"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 4.2
		beam.mesh = cyl
		beam.rotation_degrees = Vector3(35, 0, 0)
		beam.position = Vector3(0.0, 2.2, -0.4)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.5, 0.35, 0.2)
		beam.material_override = mat_b
		add_child(beam)
