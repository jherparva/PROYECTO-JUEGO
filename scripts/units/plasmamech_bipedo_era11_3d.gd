## PlasmaMech_Bípedo — Robot Titán de Combate (Edad Nano-Futurista / Era 11).
##
## Coloso definitivo terrestre de Era 11. Robot bípedo masivo de 4 metros de altura provisto
## de 600 HP, velocidad de 4.8 m/s e inmunidad total al stun, a la supresión y al hackeo.
## Su cañón pesado de plasma inflige un multiplicador estricto de x3.0 contra búnkeres o murallas
## y un daño AoE esférico de 4.5m desde su ProjectileMuzzle.
class_name PlasmaMech_Bipedo
extends "res://scripts/units/soldier_3d.gd"

signal impacto_canon_plasma(epicentro: Vector3, objetivos_alcanzados: int)

@export var radio_aoe_plasma: float = 4.5
@export var altura_titan: float = 4.0

func _init() -> void:
	unit_id = "plasmamech_bipedo_era11"
	unit_name = "PlasmaMech Bípedo"
	attack_type = "ranged"
	weapon_type = "plasma_cannon"
	impact_type = "ENERGY"
	projectile_type = "plasma"
	is_stun_immune = true
	is_slow_immune = true
	is_hack_immune = true
	_salud_base = 600.0
	salud_maxima = 600.0
	salud_actual = 600.0
	_daño_base = 65.0
	daño = 65.0
	rango_ataque = 20.0
	velocidad_ataque = 1.5
	speed = 4.8
	era_entrenada = 11

func _ready() -> void:
	super._ready()
	add_to_group("mechs")
	add_to_group("heavy_units")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_mech_visuals()

func _setup_mech_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 2.5, -1.5)
		add_child(muzzle)

	if not has_node("HeavyPlasmaCannon"):
		var cannon := MeshInstance3D.new()
		cannon.name = "HeavyPlasmaCannon"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.35
		cyl.height = 2.4
		cannon.mesh = cyl
		cannon.rotation_degrees = Vector3(90, 0, 0)
		cannon.position = Vector3(0.8, 2.4, -0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.6, 0.95) # Azul reactor cuántico
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.7, 1.0)
		mat.emission_energy_multiplier = 3.5
		cannon.material_override = mat
		add_child(cannon)

## Dispara el cañón de plasma contra un objetivo singular con multiplicadores de edificio
func disparar_canon_plasma(target: Node3D) -> float:
	if not is_instance_valid(target) or is_dead:
		return 0.0

	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "energy", self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif target.has_method("recibir_daño"):
		target.call("recibir_daño", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	var muzzle_pos: Vector3 = global_position
	var muzzle := get_node_or_null("ProjectileMuzzle") as Marker3D
	if is_instance_valid(muzzle):
		muzzle_pos = muzzle.global_position if muzzle.is_inside_tree() else (global_position + muzzle.position)
	aplicar_canon_plasma_aoe(muzzle_pos, radio_aoe_plasma, daño)
	return dmg

## Aplica detonación de plasma con radio esférico de 4.5m
func aplicar_canon_plasma_aoe(epicentro: Vector3 = Vector3.ZERO, radio: float = 4.5, dano_base: float = 65.0) -> Array[Node3D]:
	var hit_targets: Array[Node3D] = []
	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root
	elif Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root:
		root_node = (Engine.get_main_loop() as SceneTree).root
	elif get_parent():
		root_node = get_parent()

	if not is_instance_valid(root_node):
		return hit_targets

	# Buscar unidades en radio de 4.5m
	var grupo_enemigo := "enemy_units" if bando == Bando.PLAYER else "player_units"
	var posibles: Array = []
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		posibles.append_array(tree.get_nodes_in_group(grupo_enemigo))
		posibles.append_array(tree.get_nodes_in_group("units_3d"))
		posibles.append_array(tree.get_nodes_in_group("buildings_3d"))
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if is_instance_valid(child) and child is Node3D and not posibles.has(child):
					posibles.append(child)
	elif is_instance_valid(get_parent()):
		for child in get_parent().get_children():
			if is_instance_valid(child) and child is Node3D and not posibles.has(child):
				posibles.append(child)

	# Deduplicar
	var checked: Dictionary = {}
	for obj in posibles:
		if not is_instance_valid(obj) or not (obj is Node3D) or obj == self:
			continue
		if checked.has(obj):
			continue
		checked[obj] = true

		var obj_3d := obj as Node3D
		var obj_pos: Vector3 = obj_3d.position if obj_3d.position != Vector3.ZERO else (obj_3d.global_position if obj_3d.is_inside_tree() else obj_3d.position)
		if epicentro.distance_to(obj_pos) <= radio:
			hit_targets.append(obj_3d)
			var dmg: float = CombatDamageCalculator.calcular_dano(dano_base, "energy", self, obj)
			if obj.has_method("recibir_dano"):
				obj.call("recibir_dano", dmg)
			elif obj.has_method("recibir_daño"):
				obj.call("recibir_daño", dmg)
			elif "salud_actual" in obj:
				obj.set("salud_actual", maxf(0.0, float(obj.get("salud_actual")) - dmg))

	impacto_canon_plasma.emit(epicentro, hit_targets.size())
	return hit_targets
