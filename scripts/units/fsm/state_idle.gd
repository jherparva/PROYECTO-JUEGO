## StateIdle — Unidad en reposo, opcionalmente deambula por el área.
##
## Transiciones salientes:
##   → Move       si wander_enabled y el timer de deambulación expira
##
## Para deshabilitar el deambulado, deja wander_enabled = false (default).
## El estado externo puede forzar transición llamando state_machine.change_state().

class_name StateIdle
extends StateBase

# ─── Exports ───────────────────────────────────────────────────────────────────
func _init() -> void:
	state_name = &"Idle"

## Si es true, la unidad se mueve aleatoriamente dentro de wander_radius.
@export var wander_enabled: bool = false
## Radio máximo de deambulado en píxeles.
@export var wander_radius: float = 64.0
## Tiempo base entre movimientos de deambulado (con variación aleatoria ±1s).
@export var wander_interval: float = 4.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _wander_timer: float = 0.0
var _origin: Vector2 = Vector2.ZERO

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func enter(_context: Dictionary = {}) -> void:
	_origin = unit.global_position if unit else Vector2.ZERO
	_wander_timer = wander_interval
	if unit and unit.has_method("play_animation"):
		unit.play_animation("idle")

func update(delta: float) -> void:
	if not wander_enabled:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = wander_interval + randf_range(-1.0, 1.0)
		_wander()

func exit() -> void:
	_wander_timer = 0.0

# ─── Interno ───────────────────────────────────────────────────────────────────

func _wander() -> void:
	var angle := randf_range(0.0, TAU)
	var dist  := randf_range(0.0, wander_radius)
	var target := _origin + Vector2(cos(angle), sin(angle)) * dist
	state_machine.change_state(&"Move", {"target_position": target, "return_to_idle": true})
