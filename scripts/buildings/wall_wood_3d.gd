## WallWoodEra1 / WallWood3D — Empalizada Afilada Modular de Madera (Era 1 / Edad de Piedra).
##
## Fortificación perimetral de la Edad de Piedra:
## - Calibrada fielmente según las tablas 'dbupgrade.dat' (1200 HP de salud máxima).
## - Se conecta con el auto-tiling de 'building_placer.gd' y 'defense_wall_system.gd'.
## - Posee resistencia reforzada contra flechas e infantería desarmada.

class_name WallWoodEra1
extends "res://scripts/buildings/building_base_3d.gd"

const GRID_SIZE: float = 4.0

var wall_type: String = "straight" # "straight", "corner_l", "inter_t", "cross", "end"
var neighbors: Dictionary = {"N": false, "S": false, "E": false, "W": false}

func _init() -> void:
	building_name = "Empalizada Afilada de Madera"
	# Salud calibrada según dbupgrade.dat para empalizada de la Edad de Piedra
	salud_maxima = 1200.0
	salud_actual = 1200.0
	add_to_group("walls")
	add_to_group("walls_3d")
	add_to_group("walls_wood")
	add_to_group("walls_wood_era1")
	add_to_group("palisades")
	add_to_group("buildings")
	add_to_group("buildings_3d")

func _ready() -> void:
	super._ready()
	add_to_group("walls")
	add_to_group("walls_3d")
	add_to_group("walls_wood")
	add_to_group("walls_wood_era1")
	add_to_group("palisades")
	add_to_group("player_buildings" if bando == Bando.PLAYER else "enemy_buildings")

	# Auto-conectar vecinos al ser colocado
	call_deferred("actualizar_conexiones")

## Detecta muros contiguos en las 4 direcciones cardinales (N, S, E, W)
func actualizar_conexiones() -> void:
	neighbors = {"N": false, "S": false, "E": false, "W": false}
	var my_pos: Vector3 = global_position if is_inside_tree() else position

	var directions := {
		"N": Vector3(0.0, 0.0, -GRID_SIZE),
		"S": Vector3(0.0, 0.0, GRID_SIZE),
		"E": Vector3(GRID_SIZE, 0.0, 0.0),
		"W": Vector3(-GRID_SIZE, 0.0, 0.0)
	}

	var candidates: Array = []
	if is_inside_tree() and get_tree():
		candidates = get_tree().get_nodes_in_group("walls_3d")
	if get_parent():
		for child in get_parent().get_children():
			if child not in candidates:
				candidates.append(child)

	for dir_key in directions:
		var target_pos: Vector3 = my_pos + (directions[dir_key] as Vector3)
		for w in candidates:
			if is_instance_valid(w) and w != self and (w.is_in_group("walls_3d") or w is WallWoodEra1):
				var w_pos: Vector3 = w.global_position if w.is_inside_tree() else w.position
				if w_pos.distance_to(target_pos) < 1.2:
					neighbors[dir_key] = true
					break

	_determinar_malla_auto_tiling()

## Selecciona el tipo de malla visual según la disposición de vecinos
func _determinar_malla_auto_tiling() -> void:
	var count := 0
	for k in neighbors:
		if neighbors[k]:
			count += 1

	match count:
		0, 1:
			wall_type = "end"
		2:
			if (neighbors["N"] and neighbors["S"]) or (neighbors["E"] and neighbors["W"]):
				wall_type = "straight"
			else:
				wall_type = "corner_l"
		3:
			wall_type = "inter_t"
		4:
			wall_type = "cross"

	_actualizar_visibilidad_malla()

func _actualizar_visibilidad_malla() -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("Mesh_"):
			child.visible = false

	var mesh_node := get_node_or_null("Mesh_" + wall_type)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
