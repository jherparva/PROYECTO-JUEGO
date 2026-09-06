## SteamTank_Era6 — Tanque de Vapor de Hierro Remachado (Edad Industrial / Era 6).
##
## Primer súper blindado autopropulsado pesado de la simulación.
## Salud masiva de 450.0 HP. Tipo de impacto 'GUNPOWDER/Asedio'.
## Equipado con cañón principal de calderas que inflige multiplicador estricto de x2.5 vs estructuras
## y daño AoE de 3.5 metros. Cuenta con inmunidad total contra el aturdimiento (is_stun_immune = true).
class_name SteamTank_Era6
extends "res://scripts/units/soldier_3d.gd"

signal salva_vapor_disparada(impact_pos: Vector3, objetivos_alcanzados: int)

var radio_aoe: float = 3.5
var is_vehicle: bool = true

func _init() -> void:
	unit_id = "steamtank_era6"
	unit_name = "Tanque de Vapor"
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "GUNPOWDER"
	projectile_type = "fire_stone"
	is_cavalry = true
	is_stun_immune = true
	_salud_base = 450.0
	salud_maxima = 450.0
	salud_actual = 450.0
	_daño_base = 90.0
	daño = 90.0
	rango_ataque = 22.0
	velocidad_ataque = 3.2
	speed = 2.6
	era_entrenada = 6

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("steamtanks")
	add_to_group("tanks")
	add_to_group("vehicles")
	add_to_group("vehicles_3d")
	add_to_group("siege_units")
	add_to_group("units_3d")
	_setup_steamtank_visuals()

func _setup_steamtank_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.3, -2.2)
		add_child(muzzle)

	if not has_node("IronChassis"):
		var chassis := MeshInstance3D.new()
		chassis.name = "IronChassis"
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 1.4, 3.8)
		chassis.mesh = box
		chassis.position = Vector3(0.0, 0.7, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.22, 0.24, 0.25) # Placas de hierro remachadas
		mat.metallic = 0.85
		mat.roughness = 0.4
		chassis.material_override = mat
		add_child(chassis)

	if not has_node("BoilerTurret"):
		var boiler := MeshInstance3D.new()
		boiler.name = "BoilerTurret"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.8
		cyl.bottom_radius = 0.9
		cyl.height = 1.2
		boiler.mesh = cyl
		boiler.position = Vector3(0.0, 1.7, -0.2)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.18, 0.19, 0.20)
		mat_b.metallic = 0.9
		boiler.material_override = mat_b
		add_child(boiler)

	if not has_node("MainCannonBarrel"):
		var cannon := MeshInstance3D.new()
		cannon.name = "MainCannonBarrel"
		var cyl_c := CylinderMesh.new()
		cyl_c.top_radius = 0.16
		cyl_c.bottom_radius = 0.2
		cyl_c.height = 1.8
		cannon.mesh = cyl_c
		cannon.position = Vector3(0.0, 1.5, -1.5)
		cannon.rotation_degrees = Vector3(90, 0, 0)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.14, 0.14, 0.15)
		mat_c.metallic = 0.95
		cannon.material_override = mat_c
		add_child(cannon)

## Dispara el cañón principal de calderas y aplica daño AoE en un radio de 3.5m
func disparar_canon_vapor(target_pos: Vector3) -> Array[Node3D]:
	var hit_nodes: Array[Node3D] = []
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
		var dist: float = pos_o.distance_to(target_pos)
		if dist <= radio_aoe:
			hit_nodes.append(obj_3d)
			var mult: float = 2.5 if (obj_3d.is_in_group("buildings") or obj_3d.is_in_group("buildings_3d") or obj_3d.is_in_group("walls")) else 1.0
			var dano_total: float = daño * mult
			if obj.has_method("recibir_dano"):
				obj.call("recibir_dano", dano_total, self)
			elif obj.has_method("take_damage"):
				obj.call("take_damage", dano_total)
			elif "salud_actual" in obj:
				obj.set("salud_actual", maxf(0.0, float(obj.get("salud_actual")) - dano_total))

	salva_vapor_disparada.emit(target_pos, hit_nodes.size())
	print("SteamTank_Era6 '%s': Cañón de caldera detonado en %s (Radio %.1fm). Impactos: %d." % [name, str(target_pos), radio_aoe, hit_nodes.size()])
	return hit_nodes
