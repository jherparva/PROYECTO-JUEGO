## StateMachine — Motor genérico de Máquina de Estados Finita (FSM).
##
## Agrégalo como hijo de cualquier unidad. Puebla con nodos StateBase como hijos.
## El nodo dueño (owner) de la escena es inyectado en cada estado como `unit`.
##
## Patrón: State Pattern
## Uso:
##   state_machine.change_state(&"Attacking", {"target": enemy_node})
##   state_machine.is_in_state(&"Idle")

class_name StateMachine
extends Node

# ─── Señales ───────────────────────────────────────────────────────────────────
## Emitida cada vez que se realiza una transición de estado.
signal state_changed(old_state: StringName, new_state: StringName)

# ─── Exports ───────────────────────────────────────────────────────────────────
## Estado inicial (NodePath al hijo StateBase). Si vacío, usa el primer hijo.
@export var initial_state: NodePath = NodePath("")

# ─── Estado Interno ────────────────────────────────────────────────────────────
var current_state: StateBase = null
var previous_state: StateBase = null

## Mapa de nombre → instancia de estado para O(1) lookup.
var _states: Dictionary = {}

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Registrar todos los hijos StateBase y darles referencias
	for child in get_children():
		if child is StateBase:
			_states[child.state_name] = child
			child.state_machine = self
			child.unit = owner   # La unidad propietaria de la escena

	# Transicionar al estado inicial
	var init: StateBase = null
	if initial_state != NodePath(""):
		init = get_node_or_null(initial_state)
	if init == null and not _states.is_empty():
		init = _states.values()[0]

	if init != null:
		_transition_to(init, {})
	else:
		push_error("StateMachine en '%s': no se encontraron estados hijos." % owner.name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# ─── API Pública ───────────────────────────────────────────────────────────────

## Transiciona a un estado por nombre, con payload de contexto opcional.
## [br]context puede contener: target_position, target_node, target, etc.
func change_state(state_name: StringName, context: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("StateMachine ('%s'): estado desconocido '%s'." % [owner.name, state_name])
		return
	if current_state != null and current_state.state_name == state_name:
		return  # Ya estamos en ese estado, no re-entrar innecesariamente
	_transition_to(_states[state_name], context)

## Retorna el nombre del estado actual, o StringName vacío si no hay ninguno.
func get_state_name() -> StringName:
	return current_state.state_name if current_state else &""

## Retorna true si actualmente se está en el estado indicado.
func is_in_state(state_name: StringName) -> bool:
	return current_state != null and current_state.state_name == state_name

## Retorna true si el estado anterior fue el indicado.
func came_from(state_name: StringName) -> bool:
	return previous_state != null and previous_state.state_name == state_name

# ─── Interno ───────────────────────────────────────────────────────────────────

func _transition_to(new_state: StateBase, context: Dictionary) -> void:
	var old_name := get_state_name()

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state
	current_state.enter(context)

	state_changed.emit(old_name, current_state.state_name)
