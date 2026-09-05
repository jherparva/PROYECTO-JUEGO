## StateRepairing — El aldeano repara un edificio dañado en ticks periódicos.
##
## Flujo:
##   1. Si el edificio no existe o está a plena salud → Idle.
##   2. Si está lejos → Move con retorno a Repairing.
##   3. En rango → anima y aplica heal() al edificio cada repair_interval segundos.
##
## El nodo de edificio debe implementar:
##   hp: int, max_hp: int
##   repair(amount: int)   (o heal(amount))
##
## Contexto de entrada:
##   target: Node — nodo del edificio a reparar

class_name StateRepairing
extends StateBase

# ─── Exports ───────────────────────────────────────────────────────────────────
func _init() -> void:
	state_name = &"Repairing"

## Distancia máxima para reparar sin moverse.
@export var repair_range: float = 32.0
## Segundos entre cada tick de reparación.
@export var repair_interval: float = 0.5

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _building: Node = null
var _repair_timer: float = 0.0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func enter(context: Dictionary = {}) -> void:
	_building     = context.get("target", null)
	_repair_timer = 0.0

	if unit and unit.has_method("play_animation"):
		unit.play_animation("walk")

func update(delta: float) -> void:
	# Validar edificio
	if not is_instance_valid(_building):
		state_machine.change_state(&"Idle")
		return

	# Verificar si ya está a máxima salud
	if "hp" in _building and "max_hp" in _building:
		if _building.hp >= _building.max_hp:
			state_machine.change_state(&"Idle")
			return

	var dist: float = unit.global_position.distance_to(_building.global_position)

	if dist > repair_range:
		# Alejado — acercarse primero
		state_machine.change_state(&"Move", {
			"target_node":        _building,
			"on_arrival_state":   &"Repairing",
			"on_arrival_context": {"target": _building},
		})
		return

	# En rango de reparación
	if unit and unit.has_method("play_animation"):
		unit.play_animation("repair")

	_repair_timer += delta
	if _repair_timer >= repair_interval:
		_repair_timer -= repair_interval
		_do_repair()

func exit() -> void:
	_building     = null
	_repair_timer = 0.0

# ─── Reparación ────────────────────────────────────────────────────────────────

func _do_repair() -> void:
	if not is_instance_valid(_building):
		return
	var amount: int = int(unit.build_speed) if "build_speed" in unit else 5
	if _building.has_method("repair"):
		_building.repair(amount)
	elif _building.has_method("heal"):
		_building.heal(amount)
