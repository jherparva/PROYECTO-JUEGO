## Canon_Culebrina_Era5 — Cañón Culebrina de Asedio (Edad del Renacimiento / Era 5).
##
## Artillería pesada de asedio con proyectiles pesados de hierro.
## Aplica multiplicador de daño x3.0 contra edificios y daño AoE esférico de 3.0m.
## Requiere alineación y disparo desde el socket 'ProjectileMuzzle'.
class_name Canon_Culebrina_Era5
extends "res://scripts/units/soldier_3d.gd"

signal disparo_canon_ejecutado(pos_destino: Vector3)

var radio_aoe: float = 3.0

func _init() -> void:
	unit_id = "canon_culebrina_era5"
	unit_name = "Cañón Culebrina"
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "GUNPOWDER"
	projectile_type = "fire_stone"
	_salud_base = 250.0
	salud_maxima = 250.0
	salud_actual = 250.0
	_daño_base = 110.0
	daño = 110.0
	rango_ataque = 28.0
	velocidad_ataque = 3.5
	speed = 2.4 # Marcha lenta de artillería con cureña
	era_entrenada = 5

func _ready() -> void:
	super._ready()
	add_to_group("artillery")
	add_to_group("siege_units")
	add_to_group("cannons")
	add_to_group("units_3d")
	_setup_culebrina_visuals()

func _setup_culebrina_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.7, -1.8)
		add_child(muzzle)

	if not has_node("CannonBarrel"):
		var barrel := MeshInstance3D.new()
		barrel.name = "CannonBarrel"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.18
		cyl.height = 2.4
		barrel.mesh = cyl
		barrel.rotation_degrees = Vector3(90, 0, 0)
		barrel.position = Vector3(0.0, 0.7, -0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.22) # Bronce de cañón oscuro / hierro
		mat.metallic = 0.95
		mat.roughness = 0.3
		barrel.material_override = mat
		add_child(barrel)

	if not has_node("WoodenCarriage"):
		var carriage := MeshInstance3D.new()
		carriage.name = "WoodenCarriage"
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 0.6, 1.8)
		carriage.mesh = box
		carriage.position = Vector3(0.0, 0.35, -0.2)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.38, 0.25, 0.15) # Madera de cureña
		carriage.material_override = mat_c
		add_child(carriage)

## Ejecuta disparo balístico y detona el daño AoE de 3.0m
func disparar_canon(pos_impacto: Vector3) -> Array[Node3D]:
	disparo_canon_ejecutado.emit(pos_impacto)
	return aplicar_dano_aoe_artilleria(pos_impacto, radio_aoe, daño)

## Aplica daño de área esférico de 3.0 metros
func aplicar_dano_aoe_artilleria(pos_impacto: Vector3, radio: float = 3.0, cantidad_dano: float = 110.0) -> Array[Node3D]:
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
		candidatos.append_array(tree.get_nodes_in_group("units_3d"))
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

	for obj in candidatos:
		if not is_instance_valid(obj) or obj == self:
			continue
		if not (obj is Node3D):
			continue
		var obj_3d := obj as Node3D
		var pos_o: Vector3 = obj_3d.position if obj_3d.position != Vector3.ZERO else obj_3d.global_position
		var dist: float = pos_o.distance_to(pos_impacto)
		if dist <= radio:
			afectados.append(obj_3d)
			var mult: float = 3.0 if (obj_3d.is_in_group("buildings") or obj_3d.is_in_group("buildings_3d") or obj_3d.is_in_group("walls")) else 1.0
			var dano_total: float = cantidad_dano * mult
			if obj.has_method("recibir_dano"):
				obj.call("recibir_dano", dano_total, self)
			elif obj.has_method("take_damage"):
				obj.call("take_damage", dano_total)
			elif "salud_actual" in obj:
				obj.set("salud_actual", maxf(0.0, float(obj.get("salud_actual")) - dano_total))

	print("Canon_Culebrina_Era5 '%s': Salva de hierro en %s (Radio 3m). Impactos: %d." % [name, pos_impacto, afectados.size()])
	return afectados
