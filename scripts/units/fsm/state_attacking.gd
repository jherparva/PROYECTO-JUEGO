## StateAttacking — La unidad persigue y ataca a un objetivo enemigo.
##
## Flujo:
##   1. Si el objetivo muere o escapa más allá de chase_range → Idle.
##   2. Si está fuera de attack_range → Move con retorno a Attacking.
##   3. En rango → aplica daño cada attack_cooldown segundos.
##
## El nodo objetivo debe implementar:
##   take_damage(amount: int, source: Node)
##   is_dead: bool  (propiedad, no función)
##
## Contexto de entrada:
##   target: Node — nodo del enemigo a atacar

class_name StateAttacking
extends StateBase

# ─── Exports ───────────────────────────────────────────────────────────────────
func _init() -> void:
	state_name = &"Attacking"

## Distancia máxima de persecución. Si el enemigo escapa más lejos → Idle.
@export var chase_range: float = 250.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target: Node = null
var _attack_timer: float = 0.0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func enter(context: Dictionary = {}) -> void:
	_target       = context.get("target", null)
	_attack_timer = 0.0

	if unit and unit.has_method("play_animation"):
		unit.play_animation("walk")

func update(delta: float) -> void:
	# Validar objetivo
	if not _is_target_valid():
		state_machine.change_state(&"Idle")
		return

	var dist: float = unit.global_position.distance_to(_target.global_position)

	# El objetivo escapó demasiado lejos
	if dist > chase_range:
		state_machine.change_state(&"Idle")
		return

	var attack_range: float = unit.attack_range if "attack_range" in unit else 40.0

	if dist > attack_range:
		# Perseguir con retorno automático a Attacking al llegar
		state_machine.change_state(&"Move", {
			"target_node":        _target,
			"on_arrival_state":   &"Attacking",
			"on_arrival_context": {"target": _target},
		})
		return

	# En rango de ataque — atacar
	if unit and unit.has_method("play_animation"):
		unit.play_animation("attack")

	var cooldown: float = unit.attack_cooldown if "attack_cooldown" in unit else 1.2
	_attack_timer += delta
	if _attack_timer >= cooldown:
		_attack_timer -= cooldown  # Resta para mantener cadencia correcta
		_deal_damage()

func exit() -> void:
	_target       = null
	_attack_timer = 0.0

# ─── Combate ───────────────────────────────────────────────────────────────────

func _deal_damage() -> void:
	if not _is_target_valid():
		return
	var dmg: int = unit.attack_damage if "attack_damage" in unit else 5
	
	# Verificar si es un ataque a distancia con proyectil
	if "projectile_scene" in unit and unit.projectile_scene != null:
		var proj = unit.projectile_scene.instantiate() as Projectile
		if proj:
			proj.damage = dmg
			proj.target = _target
			proj.source_unit = unit
			proj.global_position = unit.global_position
			
			if "aoe_radius" in unit:
				proj.aoe_radius = unit.aoe_radius
				
			var parent = unit.get_parent()
			if parent:
				parent.add_child(proj)
			else:
				unit.get_tree().root.add_child(proj)
	else:
		# Ataque cuerpo a cuerpo / directo
		if _target.has_method("take_damage"):
			_target.take_damage(dmg, unit)

func _is_target_valid() -> bool:
	if not is_instance_valid(_target):
		return false
	if "is_dead" in _target and _target.is_dead:
		return false
	return true
