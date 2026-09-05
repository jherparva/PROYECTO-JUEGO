## StateGathering — El aldeano se acerca a un recurso y lo recolecta periódicamente.
##
## Flujo:
##   1. Si está lejos → transiciona a Move con retorno a Gathering al llegar.
##   2. En rango → anima y extrae recursos cada gather_interval segundos.
##   3. Al llenarse (carry_capacity) o si el recurso se agota → entrega y vuelve a Idle.
##
## El nodo de recurso debe implementar:
##   extract(amount: int) → int     (retorna cuánto pudo extraer realmente)
##   is_depleted() → bool
##   get_resource_type() → String   (ej: "wood", "food", "gold", "iron", "stone")
##
## Contexto de entrada:
##   target_node: Node — nodo del recurso a recolectar

class_name StateGathering
extends StateBase

# ─── Exports ───────────────────────────────────────────────────────────────────
func _init() -> void:
	state_name = &"Gathering"

## Distancia máxima para recolectar sin tener que acercarse.
@export var gather_range: float = 32.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _resource_node: Node = null
var _gather_timer: float = 0.0
var _gather_interval: float = 1.0
var _carrying: int = 0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func enter(context: Dictionary = {}) -> void:
	_resource_node = context.get("target_node", null)
	_carrying      = 0
	_gather_timer  = 0.0

	# Calcular intervalo de recolección desde la stat gather_rate de la unidad
	if "gather_rate" in unit and unit.gather_rate > 0.0:
		_gather_interval = 1.0 / unit.gather_rate
	else:
		_gather_interval = 1.0

	if unit and unit.has_method("play_animation"):
		unit.play_animation("walk")

func update(delta: float) -> void:
	if not is_instance_valid(_resource_node):
		state_machine.change_state(&"Idle")
		return

	var dist: float = unit.global_position.distance_to(_resource_node.global_position)

	if dist > gather_range:
		# Alejado del recurso → mover con retorno automático
		state_machine.change_state(&"Move", {
			"target_node":        _resource_node,
			"on_arrival_state":   &"Gathering",
			"on_arrival_context": {"target_node": _resource_node},
		})
		return

	# En rango de recolección
	if unit and unit.has_method("play_animation"):
		unit.play_animation("gather")

	_gather_timer += delta
	if _gather_timer >= _gather_interval:
		_gather_timer -= _gather_interval  # Resta para mantener acumulado correcto
		_do_gather()

func exit() -> void:
	# Entregar lo que lleve al salir del estado
	if _carrying > 0:
		_deliver()
	_resource_node = null
	_gather_timer  = 0.0

# ─── Recolección ───────────────────────────────────────────────────────────────

func _do_gather() -> void:
	if not is_instance_valid(_resource_node):
		return

	var capacity: int = unit.carry_capacity if "carry_capacity" in unit else 10
	var to_extract := mini(capacity - _carrying, capacity)

	if _resource_node.has_method("extract"):
		_carrying += _resource_node.extract(to_extract)

	# Verificar si el recurso se agotó
	if _resource_node.has_method("is_depleted") and _resource_node.is_depleted():
		_deliver()
		state_machine.change_state(&"Idle")
		return

	# Ir a entregar si la carga está llena
	if _carrying >= capacity:
		_deliver()

func _deliver() -> void:
	if _carrying <= 0 or not is_instance_valid(_resource_node):
		return

	if _resource_node.has_method("get_resource_type"):
		var rtype: String = _resource_node.get_resource_type()
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and rm.has_method("add_resources"):
			rm.add_resources(rtype, _carrying)

	_carrying = 0
