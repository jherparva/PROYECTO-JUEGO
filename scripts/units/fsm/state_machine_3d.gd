## StateMachine3D — Motor de Máquina de Estados Finita 3D (GDScript 2.0 / Godot 4).
##
## Administra el ciclo de vida y transiciones entre estados 3D (Idle, Move, Gathering, etc.).

class_name StateMachine3D
extends Node

# ─── Señales ───────────────────────────────────────────────────────────────────
signal state_changed(old_state: StringName, new_state: StringName)

# ─── Exports y Estado Interno ──────────────────────────────────────────────────
@export var initial_state: NodePath = NodePath("")

var current_state: StateBase3D = null
var previous_state: StateBase3D = null
var _states: Dictionary = {}

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	setup_states()

func setup_states() -> void:
	if not _states.is_empty():
		return

	var target_unit: Node = owner if owner != null else get_parent()
	for child in get_children():
		if child is StateBase3D:
			_states[child.state_name] = child
			_states[StringName(child.name)] = child
			child.state_machine = self
			if target_unit is CharacterBody3D:
				child.unit = target_unit as CharacterBody3D

	var init: StateBase3D = null
	if initial_state != NodePath(""):
		init = get_node_or_null(initial_state) as StateBase3D
	if init == null and not _states.is_empty():
		init = _states.values()[0]

	if init != null and current_state == null:
		_transition_to(init, {})
	elif init == null and _states.is_empty():
		var owner_name: String = target_unit.name if is_instance_valid(target_unit) else "Unknown"
		push_error("StateMachine3D en '%s': no se encontraron estados 3D." % owner_name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# ─── API Pública ───────────────────────────────────────────────────────────────

func change_state(state_name: StringName, context: Dictionary = {}) -> void:
	if _states.is_empty():
		setup_states()

	if not _states.has(state_name):
		var target_name: String = owner.name if owner != null else (get_parent().name if get_parent() else "Unknown")
		push_error("StateMachine3D ('%s'): estado desconocido '%s'." % [target_name, state_name])
		return
	if current_state != null and current_state.state_name == state_name and context.is_empty():
		return
	_transition_to(_states[state_name], context)

func get_state_name() -> StringName:
	return current_state.state_name if current_state else &""

func is_in_state(state_name: StringName) -> bool:
	return current_state != null and current_state.state_name == state_name

func has_state(state_name: StringName) -> bool:
	if _states.is_empty():
		setup_states()
	return _states.has(state_name)

# ─── Interno ───────────────────────────────────────────────────────────────────

func _transition_to(new_state: StateBase3D, context: Dictionary) -> void:
	var old_name := get_state_name()

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state
	current_state.enter(context)

	state_changed.emit(old_name, current_state.state_name)
