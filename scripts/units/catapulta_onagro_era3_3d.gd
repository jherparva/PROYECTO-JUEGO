## Catapulta_Onagro_Era3 — Onagro de Torsión (Edad de Hierro / Era 3).
##
## Maquinaria pesada de asedio a distancia.
## Lanza proyectiles de roca ardiente desde el socket 'ProjectileMuzzle' superior.
## Aplica daño de área de efecto (AoE) en un radio esférico estricto de 4.0 metros.
class_name Catapulta_Onagro_Era3
extends "res://scripts/units/soldier_3d.gd"

var is_siege_engine: bool = true
var radio_aoe: float = 4.0

func _init() -> void:
	unit_id = "catapulta_onagro_era3"
	unit_name = "Onagro de Torsión"
	attack_type = "ranged"
	weapon_type = "siege_stone"
	projectile_type = "fire_stone"
	_salud_base = 220.0
	salud_maxima = 220.0
	salud_actual = 220.0
	_daño_base = 45.0
	daño = 45.0
	rango_ataque = 24.0 # Largo alcance
	velocidad_ataque = 3.0 # Torsión lenta y pesada
	speed = 3.0 # Desplazamiento lento
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("siege_units")
	add_to_group("catapults")
	add_to_group("vehicles_3d")
	add_to_group("units_3d")
	_setup_muzzle_and_mesh()

func _setup_muzzle_and_mesh() -> void:
	# Socket ProjectileMuzzle superior para balística parabólica
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.8, -0.4)
		add_child(muzzle)

	if not has_node("OnagerBase"):
		var base_m := MeshInstance3D.new()
		base_m.name = "OnagerBase"
		var box := BoxMesh.new()
		box.size = Vector3(1.6, 1.0, 2.4)
		base_m.mesh = box
		base_m.position = Vector3(0.0, 0.5, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.38, 0.26, 0.16)
		base_m.material_override = mat
		add_child(base_m)

## Aplica el daño de área de efecto (AoE) en un radio de 4.0m alrededor del impacto
func aplicar_dano_aoe(pos_impacto: Vector3, radio: float = 4.0, cantidad_dano: float = 45.0) -> Array[Node3D]:
	var afectados: Array[Node3D] = []
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if not is_instance_valid(tree):
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop

	var posibles_objetivos: Array[Node] = []
	if is_instance_valid(tree):
		posibles_objetivos.append_array(tree.get_nodes_in_group("units_3d"))
		posibles_objetivos.append_array(tree.get_nodes_in_group("buildings_3d"))
		posibles_objetivos.append_array(tree.get_nodes_in_group("enemy_units"))
		posibles_objetivos.append_array(tree.get_nodes_in_group("walls"))
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if is_instance_valid(child) and child is Node3D and not posibles_objetivos.has(child):
					posibles_objetivos.append(child)
	elif is_instance_valid(get_parent()):
		for child in get_parent().get_children():
			if is_instance_valid(child) and child is Node3D and not posibles_objetivos.has(child):
				posibles_objetivos.append(child)

	for obj in posibles_objetivos:
		if not is_instance_valid(obj) or obj == self:
			continue
		if not (obj is Node3D):
			continue
		var obj_3d := obj as Node3D
		var pos_obj: Vector3 = obj_3d.position if obj_3d.position != Vector3.ZERO else obj_3d.global_position
		var dist: float = pos_obj.distance_to(pos_impacto)
		if dist <= radio:
			afectados.append(obj_3d)
			if obj.has_method("recibir_dano"):
				obj.call("recibir_dano", cantidad_dano, self)
			elif obj.has_method("take_damage"):
				obj.call("take_damage", cantidad_dano)
			elif "salud_actual" in obj:
				obj.set("salud_actual", maxf(0.0, float(obj.get("salud_actual")) - cantidad_dano))

	print("Catapulta_Onagro_Era3: Impacto AoE en %s (Radio: %.1fm). Objetivos alcanzados: %d." % [pos_impacto, radio, afectados.size()])
	return afectados
