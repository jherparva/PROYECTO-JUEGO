## Hut3D — Choza Prehistórica 3D (Aumenta la población máxima en +5).
class_name Hut3D
extends "res://scripts/buildings/building_base_3d.gd"

@export var population_bonus: int = 5
var resource_manager: Node = null
var _population_applied: bool = false

func _init() -> void:
	building_name = "Choza Prehistórica"
	salud_maxima = 350.0
	salud_actual = 1.0
	starts_under_construction = true
	esta_construido = false
	is_under_construction = true
	progreso_construccion = 0.0
	if not construction_completed.is_connected(_on_construction_completed):
		construction_completed.connect(_on_construction_completed)

func _ready() -> void:
	building_name = "Choza Prehistórica"
	salud_maxima = 350.0
	salud_actual = salud_maxima if not starts_under_construction else 1.0
	super._ready()
	if not construction_completed.is_connected(_on_construction_completed):
		construction_completed.connect(_on_construction_completed)
	if esta_construido and not is_under_construction:
		_on_construction_completed()

func _get_resource_manager() -> Node:
	if is_instance_valid(resource_manager):
		return resource_manager
	if get_parent():
		for child in get_parent().get_children():
			if child is GlobalResourceManager or child.name.begins_with("ResourceManager") or child.is_in_group("resource_manager"):
				return child
	var tree := get_tree() if get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		for node in tree.get_nodes_in_group("resource_manager"):
			if is_instance_valid(node):
				return node
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if child is GlobalResourceManager or child.name.begins_with("ResourceManager") or child.is_in_group("resource_manager"):
					return child
	var rm := get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		return rm
	return null

func _on_construction_completed() -> void:
	if _population_applied:
		return
	_population_applied = true
	var rm := _get_resource_manager()
	if is_instance_valid(rm) and rm.has_method("change_max_population"):
		rm.change_max_population(population_bonus)

func _destroy() -> void:
	_remove_population()
	super._destroy()

func _exit_tree() -> void:
	_remove_population()

func _remove_population() -> void:
	if _population_applied:
		_population_applied = false
		var rm := _get_resource_manager()
		if is_instance_valid(rm) and rm.has_method("change_max_population"):
			rm.change_max_population(-population_bonus)
