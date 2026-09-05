## ProductionQueue — Cola FIFO de órdenes de producción de unidades.
##
## Gestiona: verificación de recursos, timers, spawn de unidades,
## cancelación con reembolso y señales para la UI.
##
## Patrón: Command Pattern (cada ProductionOrder es un comando encapsulado).
##
## API compatible con ResourceManager del usuario (string-keyed resources):
##   spend_resources(cost)        en lugar de spend()
##   has_population_room()        en lugar de can_train()
##   add_resources(name, amount)  en lugar de add_batch()

class_name ProductionQueue
extends Node

# ─── Señales ───────────────────────────────────────────────────────────────────
signal production_started(order: ProductionOrder)
signal production_completed(order: ProductionOrder)
signal production_cancelled(order: ProductionOrder, refunded: bool)
signal queue_changed(queue: Array)
signal progress_updated(order: ProductionOrder, progress: float)

# ─── Constantes ────────────────────────────────────────────────────────────────
const MAX_QUEUE_SIZE: int = 5

# ─── Clase Interna: ProductionOrder ────────────────────────────────────────────

class ProductionOrder:
	var unit_data: UnitData
	var elapsed: float = 0.0
	var id: int

	func _init(data: UnitData, order_id: int) -> void:
		unit_data = data
		id        = order_id

	## Retorna el progreso normalizado (0.0–1.0).
	func get_progress() -> float:
		if unit_data.production_time <= 0.0:
			return 1.0
		return clampf(elapsed / unit_data.production_time, 0.0, 1.0)

	## Retorna true si la orden está completa.
	func is_complete() -> bool:
		return elapsed >= unit_data.production_time

# ─── Estado ────────────────────────────────────────────────────────────────────

var _queue: Array[ProductionOrder] = []
var _next_id: int = 0

## NodePath al nodo de spawn (punto de entrenamiento del edificio).
@export var spawn_point: NodePath = NodePath("")

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _queue.is_empty():
		return

	var current: ProductionOrder = _queue[0]
	current.elapsed += delta
	progress_updated.emit(current, current.get_progress())

	if current.is_complete():
		_complete_order(current)

# ─── API Pública ───────────────────────────────────────────────────────────────

## Intenta encolar una nueva orden de producción.
## [br]Retorna el ID de la orden en éxito, -1 en fracaso.
func enqueue(unit_data: UnitData) -> int:
	if _queue.size() >= MAX_QUEUE_SIZE:
		push_warning("ProductionQueue: cola llena (%d/%d)." % [_queue.size(), MAX_QUEUE_SIZE])
		return -1

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_method("has_population_room") and not rm.has_population_room():
			push_warning("ProductionQueue: límite de población alcanzado.")
			return -1

		if rm.has_method("can_afford") and not rm.can_afford(unit_data.cost):
			push_warning("ProductionQueue: recursos insuficientes para '%s'." % unit_data.unit_name)
			return -1

		# Descontar recursos al encolar (como en Empire Earth)
		if rm.has_method("spend_resources") and not rm.spend_resources(unit_data.cost):
			return -1

	var order := ProductionOrder.new(unit_data, _next_id)
	_next_id += 1
	_queue.append(order)

	if _queue.size() == 1:
		production_started.emit(order)

	queue_changed.emit(_queue.duplicate())
	return order.id

## Cancela una orden por ID.
## [br]always_refund=true reembolsa incluso si está en producción activa.
func cancel(order_id: int, always_refund: bool = false) -> bool:
	for i in _queue.size():
		var order: ProductionOrder = _queue[i]
		if order.id != order_id:
			continue

		var is_active := (i == 0)
		var should_refund := always_refund or not is_active

		_queue.remove_at(i)
		production_cancelled.emit(order, should_refund)

		if should_refund:
			_refund(order.unit_data.cost)

		queue_changed.emit(_queue.duplicate())

		if is_active and not _queue.is_empty():
			production_started.emit(_queue[0])

		return true

	push_warning("ProductionQueue: orden con id %d no encontrada." % order_id)
	return false

## Cancela todas las órdenes en cola.
## [br]refund_active=true también reembolsa la que está en producción.
func cancel_all(refund_active: bool = false) -> void:
	var i := _queue.size() - 1
	while i >= 0:
		var order: ProductionOrder = _queue[i]
		var is_active := (i == 0)
		var should_refund := (not is_active) or refund_active
		_queue.remove_at(i)
		production_cancelled.emit(order, should_refund)
		if should_refund:
			_refund(order.unit_data.cost)
		i -= 1
	queue_changed.emit(_queue.duplicate())

## Retorna una copia de la cola actual.
func get_queue() -> Array:
	return _queue.duplicate()

## Retorna el progreso de la orden activa (0.0–1.0).
func get_active_progress() -> float:
	return _queue[0].get_progress() if not _queue.is_empty() else 0.0

## Retorna cuántas órdenes hay en cola.
func queue_size() -> int:
	return _queue.size()

# ─── Interno ───────────────────────────────────────────────────────────────────

func _complete_order(order: ProductionOrder) -> void:
	_queue.remove_at(0)
	_spawn_unit(order)
	production_completed.emit(order)
	queue_changed.emit(_queue.duplicate())

	if not _queue.is_empty():
		production_started.emit(_queue[0])

## Reembolsa los recursos de un costo usando add_resources() del ResourceManager.
## El costo es un dict con claves de string: { "wood": 50, "food": 30 }
func _refund(cost: Dictionary) -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("add_resources"):
		for resource_name in cost:
			rm.add_resources(resource_name, cost[resource_name])

func _spawn_unit(order: ProductionOrder) -> void:
	if order.unit_data.scene_path.is_empty():
		push_error("ProductionQueue: scene_path vacía en '%s'." % order.unit_data.unit_name)
		return

	var scene: PackedScene = load(order.unit_data.scene_path)
	if not scene:
		push_error("ProductionQueue: no se pudo cargar '%s'." % order.unit_data.scene_path)
		return

	var unit: Node = scene.instantiate()

	var spawn_node: Node = get_node_or_null(spawn_point) if spawn_point != NodePath("") else null
	var spawn_pos: Vector2
	if is_instance_valid(spawn_node) and spawn_node is Node2D:
		spawn_pos = (spawn_node as Node2D).global_position
	elif owner is Node2D:
		spawn_pos = (owner as Node2D).global_position + Vector2(60.0, 0.0)
	else:
		spawn_pos = Vector2.ZERO

	get_tree().root.add_child(unit)

	if unit is Node2D:
		(unit as Node2D).global_position = spawn_pos

	if unit.has_method("apply_unit_data"):
		unit.apply_unit_data(order.unit_data)
