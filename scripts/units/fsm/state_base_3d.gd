## StateBase3D — Clase base abstracta para todos los estados de unidad 3D (GDScript 2.0).
##
## Proporciona la interfaz virtual (enter, update, physics_update, exit) y
## mantiene las referencias inyectadas hacia la StateMachine3D y la unidad 3D.

class_name StateBase3D
extends Node

# ─── Identidad ─────────────────────────────────────────────────────────────────
@export var state_name: StringName = &"State"

# ─── Referencias Inyectadas ─────────────────────────────────────────────────────
var state_machine: Node:
	get:
		if not is_instance_valid(_state_machine):
			if get_parent() is StateMachine3D:
				_state_machine = get_parent()
		return _state_machine
	set(v):
		_state_machine = v
var _state_machine: Node = null

var unit: CharacterBody3D:
	get:
		if not is_instance_valid(_unit):
			if is_instance_valid(owner) and owner is CharacterBody3D:
				_unit = owner as CharacterBody3D
			elif is_instance_valid(state_machine) and is_instance_valid(state_machine.get_parent()) and state_machine.get_parent() is CharacterBody3D:
				_unit = state_machine.get_parent() as CharacterBody3D
			elif is_instance_valid(get_parent()) and is_instance_valid(get_parent().get_parent()) and get_parent().get_parent() is CharacterBody3D:
				_unit = get_parent().get_parent() as CharacterBody3D
		return _unit
	set(v):
		_unit = v
var _unit: CharacterBody3D = null

# ─── Métodos Virtuales ─────────────────────────────────────────────────────────

## Llamado al entrar a este estado con contexto opcional.
func enter(_context: Dictionary = {}) -> void:
	pass

## Llamado cada frame de proceso (_process).
func update(_delta: float) -> void:
	pass

## Llamado cada frame de física (_physics_process).
func physics_update(_delta: float) -> void:
	pass

## Llamado al salir de este estado.
func exit() -> void:
	pass

## Retorna de forma segura la instancia activa de SceneTree.
func get_tree_safe() -> SceneTree:
	if is_inside_tree() and get_tree() != null:
		return get_tree()
	if is_instance_valid(unit):
		if unit.is_inside_tree() and unit.get_tree() != null:
			return unit.get_tree()
		var p: Node = unit.get_parent()
		while is_instance_valid(p):
			if p.is_inside_tree() and p.get_tree() != null:
				return p.get_tree()
			p = p.get_parent()
	var p2: Node = get_parent()
	while is_instance_valid(p2):
		if p2.is_inside_tree() and p2.get_tree() != null:
			return p2.get_tree()
		p2 = p2.get_parent()
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop as SceneTree
	return null
