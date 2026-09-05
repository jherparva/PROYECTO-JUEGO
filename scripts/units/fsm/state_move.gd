## StateMove — Navega la unidad hacia una posición o nodo destino.
##
## Soporta dos modos:
##   1. Navegación directa (sin NavigationAgent2D): interpolación lineal simple.
##   2. Navegación con agente (con NavigationAgent2D hijo en la unidad): pathfinding.
##
## Transiciones salientes:
##   → Idle         al llegar al destino (si no hay on_arrival_state)
##   → [cualquiera] al llegar, si on_arrival_state está definido en el contexto
##
## Contexto de entrada:
##   target_position   : Vector2  — posición destino
##   target_node       : Node2D  — nodo a seguir (se actualiza cada frame)
##   on_arrival_state  : StringName — estado al que transicionar al llegar
##   on_arrival_context: Dictionary — contexto para el estado de llegada

class_name StateMove
extends StateBase

# ─── Exports ───────────────────────────────────────────────────────────────────
func _init() -> void:
	state_name = &"Move"

## Distancia en píxeles para considerar que llegó al destino.
@export var arrival_threshold: float = 8.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target_position: Vector2 = Vector2.ZERO
var _target_node: Node2D = null
var _on_arrival_state: StringName = &""
var _on_arrival_context: Dictionary = {}
var _nav_agent: NavigationAgent2D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func enter(context: Dictionary = {}) -> void:
	_target_node          = context.get("target_node", null)
	_target_position      = context.get("target_position", unit.global_position if unit else Vector2.ZERO)
	_on_arrival_state     = context.get("on_arrival_state", &"")
	_on_arrival_context   = context.get("on_arrival_context", {})

	# Buscar NavigationAgent2D en la unidad (opcional)
	_nav_agent = unit.get_node_or_null("NavigationAgent2D") if unit else null

	if unit and unit.has_method("play_animation"):
		unit.play_animation("walk")

	_update_navigation_target()

func physics_update(_delta: float) -> void:
	if not is_instance_valid(unit):
		return

	# Si seguimos un nodo dinámico, actualizamos el destino cada frame
	if is_instance_valid(_target_node):
		_target_position = _target_node.global_position
		_update_navigation_target()

	if _nav_agent:
		_move_with_nav_agent()
	else:
		_move_direct()

func exit() -> void:
	_target_node = null
	_nav_agent   = null

# ─── Movimiento ────────────────────────────────────────────────────────────────

func _move_direct() -> void:
	var to_target: Vector2 = _target_position - unit.global_position
	if to_target.length() <= arrival_threshold:
		_on_arrived()
		return
	var speed: float = unit.speed if "speed" in unit else 100.0
	unit.velocity = to_target.normalized() * speed
	unit.move_and_slide()

func _move_with_nav_agent() -> void:
	if _nav_agent.is_navigation_finished():
		_on_arrived()
		return
	if _nav_agent.is_target_reachable() == false:
		# Destino inalcanzable — volver a Idle
		_on_arrived()
		return
	var next_pos := _nav_agent.get_next_path_position()
	var direction: Vector2 = (next_pos - unit.global_position).normalized()
	var speed: float = unit.speed if "speed" in unit else 100.0
	unit.velocity = direction * speed
	unit.move_and_slide()

func _update_navigation_target() -> void:
	if _nav_agent:
		_nav_agent.target_position = _target_position

func _on_arrived() -> void:
	if _on_arrival_state != &"":
		state_machine.change_state(_on_arrival_state, _on_arrival_context)
	else:
		state_machine.change_state(&"Idle")
