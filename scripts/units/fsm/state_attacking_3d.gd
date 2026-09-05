## StateAttacking3D — Estado de Combate y Ataque Militar 3D (GDScript 2.0 / Godot 4).
##
## Implementa la lógica completa de persecución, cálculo de distancia 3D,
## orientación y aplicación de daño regular en ticks mediante `velocidad_ataque`.

class_name StateAttacking3D
extends StateBase3D

const CombatDamageCalculator = preload("res://scripts/core/combat_damage_calculator.gd")


# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target: Node3D = null
var _attack_timer: float = 0.0

# Flag que se activa cuando el jugador emite una orden manual de movimiento
# mientras la unidad está peleando. Se comprueba en physics_update para ceder el control.
var _manual_move_override: bool = false

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	state_name = &"Attacking"

func enter(context: Dictionary = {}) -> void:
	# Iniciar con temporizador listo para asestar el primer golpe inmediatamente al entrar en rango
	_attack_timer = 999.0
	_manual_move_override = false
	var raw_tgt = context.get("target", null)
	_target = raw_tgt as Node3D if is_instance_valid(raw_tgt) else null

	# BLOQUEO ESTRICTO DE FUEGO AMIGO en la entrada del estado
	if is_instance_valid(_target) and is_instance_valid(unit):
		if not _is_valid_enemy_target(_target):
			_target = null

	if not _is_valid_enemy_target(_target):
		var new_enemy := _find_nearest_enemy()
		if is_instance_valid(new_enemy):
			_target = new_enemy
		else:
			state_machine.change_state(&"Idle")
			return

	# Si es aldeano y el objetivo es fauna salvaje, activar modo cacería con lanza
	if unit is Villager3D:
		var is_fauna: bool = (_target is FaunaAnimal3D or _target.is_in_group("fauna") or _target.is_in_group("animals_3d")) if is_instance_valid(_target) else false
		if is_fauna or bool(context.get("is_hunting", false)):
			unit.set_hand_prop("spear")
			if unit.has_method("set_status_text"):
				unit.set_status_text("🏹 Cazando animal...", 2.5)

	if unit and unit.nav_agent:
		unit.nav_agent.target_desired_distance = 2.2

func physics_update(delta: float) -> void:
	if not is_instance_valid(unit):
		return

	if "is_stunned" in unit and unit.is_stunned:
		unit.velocity = Vector3.ZERO
		return

	# Override de movimiento manual: romper el bucle de persecución y transicionar inmediatamente a StateMove3D
	if _manual_move_override or (is_instance_valid(unit) and unit.has_meta("new_move_command")):
		var move_ctx: Dictionary = {}
		if is_instance_valid(unit) and unit.has_meta("new_move_command"):
			var dest = unit.get_meta("new_move_command")
			if dest is Vector3:
				move_ctx["target_position"] = dest
			unit.remove_meta("new_move_command")
		elif is_instance_valid(unit) and "_guard_position" in unit:
			move_ctx["target_position"] = unit.get("_guard_position")

		_target = null
		_manual_move_override = false
		if state_machine.has_state(&"Move"):
			state_machine.change_state(&"Move", move_ctx)
		elif state_machine.has_state(&"StateMove3D"):
			state_machine.change_state(&"StateMove3D", move_ctx)
		else:
			state_machine.change_state(&"Moving", move_ctx)
		return

	# Inyección de guarda de seguridad de instancia anti-previously freed (Dangling Pointer Lock)
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	# Si el objetivo murió o dejó de ser válido en la escena
	if not _is_valid_enemy_target(_target):
		_on_target_lost_or_dead(_target)
		return

	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	# a) Calcular distancia 3D hacia el objetivo
	var current_distance: float = unit.global_position.distance_to(_target.global_position)
	var effective_range: float = unit.rango_ataque

	# Si el objetivo es un edificio (tienen mayor tamaño), compensar radio del centroide
	if _target is BuildingBase3D or _target.is_in_group("buildings_3d") or _target.is_in_group("buildings"):
		effective_range += 3.5

	# b) Si está fuera del rango efectivo, perseguir
	if current_distance > effective_range:
		_pursue_target(delta, effective_range)
		return

	# c) Si está dentro del rango, golpear y dañar
	_execute_attack(delta)

func exit() -> void:
	_attack_timer = 0.0
	_target = null
	_manual_move_override = false
	if unit:
		unit.velocity = Vector3.ZERO
		if "is_attacking" in unit:
			unit.is_attacking = false
		if unit is Villager3D:
			(unit as Villager3D).set_gathering_animation(false)

# ─── Comportamientos de Combate ────────────────────────────────────────────────

func _pursue_target(delta: float, effective_range: float = 3.0) -> void:
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	unit.play_animation("walk")

	# Si ya estamos al alcance efectivo, pasar directo a atacar
	var current_distance: float = unit.global_position.distance_to(_target.global_position)
	if current_distance <= effective_range:
		_execute_attack(delta)
		return

	if unit.nav_agent:
		unit.nav_agent.target_position = _target.global_position
		if not unit.nav_agent.is_navigation_finished():
			var next_pos: Vector3 = unit.nav_agent.get_next_path_position()
			var move_dir: Vector3 = (next_pos - unit.global_position)
			move_dir.y = 0.0
			if move_dir.length_squared() > 0.001:
				move_dir = move_dir.normalized()
				unit.velocity = move_dir * unit.speed
				unit.rotate_towards_direction(unit.velocity, delta)
			else:
				_move_direct_towards_target(delta)
		else:
			_move_direct_towards_target(delta)
	else:
		_move_direct_towards_target(delta)

	unit.move_and_slide()

func _move_direct_towards_target(delta: float) -> void:
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	var move_dir := (_target.global_position - unit.global_position)
	move_dir.y = 0.0
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()
		unit.velocity = move_dir * unit.speed
		unit.rotate_towards_direction(unit.velocity, delta)
	else:
		unit.velocity = Vector3.ZERO

func _execute_attack(delta: float) -> void:
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	unit.velocity = Vector3.ZERO

	# Orientar al guerrero hacia la víctima en plano horizontal
	var dir_to_victim := (_target.global_position - unit.global_position)
	dir_to_victim.y = 0.0
	if dir_to_victim.length_squared() > 0.01:
		unit.rotate_towards_direction(dir_to_victim, delta)

	_attack_timer += delta
	var cooldown := maxf(0.1, unit.velocidad_ataque)

	if _attack_timer >= cooldown:
		_attack_timer = 0.0
		unit.play_animation("attack")
		if unit.has_method("set_status_text"):
			unit.set_status_text("⚔️ ¡Ataque!", 0.8)

		var weapon_str: String = "melee"
		if "weapon_type" in unit:
			weapon_str = str(unit.get("weapon_type"))
		elif "attack_type" in unit:
			weapon_str = str(unit.get("attack_type"))

		var damage_amount: float = CombatDamageCalculator.calcular_dano(unit.daño, weapon_str, unit, _target)
		if unit is Villager3D:
			(unit as Villager3D).set_gathering_animation(true)

		if _target.has_method("recibir_daño"):
			_target.call("recibir_daño", damage_amount, unit)
		elif _target.has_method("take_damage"):
			_target.call("take_damage", int(damage_amount), unit)

		# ── Efectos de Combate (SFX y VFX) ──────────────────────────────────
		var sm_inst: Node = get_node_or_null("/root/SoundManager")
		if is_instance_valid(sm_inst) and sm_inst.has_method("play_hit_sound"):
			sm_inst.call("play_hit_sound", _target.global_position)
		HitVFX3D.create_at(get_tree().current_scene if get_tree() else unit.get_parent(), _target.global_position)

		# Comprobar inmediatamente si la víctima murió con este golpe
		if not _is_valid_enemy_target(_target):
			var victim := _target
			_on_target_lost_or_dead(victim)
			return

func _on_target_lost_or_dead(dead_target: Node3D = null) -> void:
	if not is_instance_valid(dead_target) or dead_target.is_queued_for_deletion():
		_target = null
		if is_instance_valid(unit):
			unit.velocity = Vector3.ZERO
			if "is_attacking" in unit:
				unit.is_attacking = false
		if is_instance_valid(state_machine):
			state_machine.change_state(&"Idle")
		return

	# Si un aldeano estaba cazando y el animal murió, saltar inmediatamente a faenar la carne
	if unit is Villager3D and is_instance_valid(dead_target) and not dead_target.is_queued_for_deletion():
		var is_fauna: bool = dead_target is FaunaAnimal3D or dead_target.is_in_group("fauna") or dead_target.is_in_group("animals_3d")
		if is_fauna:
			_target = null
			unit.velocity = Vector3.ZERO
			if unit.has_method("set_status_text"):
				unit.set_status_text("🥩 Faenando carne...", 2.0)
			unit.command_gather(dead_target)
			return

	_target = null
	if is_instance_valid(unit):
		unit.velocity = Vector3.ZERO
		if "is_attacking" in unit:
			unit.is_attacking = false
	
	# Buscar un nuevo objetivo enemigo en las cercanías
	var next_enemy := _find_nearest_enemy()
	if is_instance_valid(next_enemy) and not next_enemy.is_queued_for_deletion():
		_target = next_enemy
	else:
		state_machine.change_state(&"Idle")

# ─── Helpers de Target ─────────────────────────────────────────────────────────

func _is_valid_enemy_target(target_node: Variant = null) -> bool:
	if not is_instance_valid(target_node):
		return false
	if not (target_node is Node3D):
		return false
	if (target_node as Node).is_queued_for_deletion():
		return false

	# Jamás auto-atacarse
	if target_node == unit:
		return false

	# Comprobar si el objetivo está muerto o destruido
	if "is_dead" in target_node and target_node.get("is_dead") == true:
		return false

	if "salud_actual" in target_node and float(target_node.get("salud_actual")) <= 0.0:
		return false

	# ─── BLOQUEO DE FUEGO AMIGO: No atacar aliados ni unidades del mismo bando ───
	if is_instance_valid(unit):
		var my_bando: int = int(unit.bando) if "bando" in unit else 0
		var tgt_bando: int = int(target_node.bando) if "bando" in target_node else -1

		# Si ambos tienen bando asignado y coinciden, no es un enemigo
		if tgt_bando != -1 and my_bando == tgt_bando:
			return false

		# Filtrado por grupos de afinidad
		if my_bando == 0: # Bando Jugador/Aliado
			if (target_node as Node).is_in_group("player_units") or (target_node as Node).is_in_group("player_buildings") or (target_node as Node).is_in_group("allies"):
				return false
		elif my_bando == 1: # Bando Enemigo
			if (target_node as Node).is_in_group("enemy_units") or (target_node as Node).is_in_group("enemy_buildings"):
				return false

	return true

func _find_nearest_enemy() -> Node3D:
	if not is_instance_valid(unit):
		return null
		
	var my_bando: int = int(unit.bando)
	var tree := get_tree_safe()
	if not is_instance_valid(tree):
		return null

	# 1. PASO 1: Prioridad absoluta a UNIDADES enemigas vivas (soldados/fauna)
	var best_unit: Node3D = null
	var min_unit_dist := INF
	var enemy_units := tree.get_nodes_in_group("enemy_units") if my_bando == 0 else tree.get_nodes_in_group("player_units")

	for candidate in enemy_units:
		if candidate is Node3D and is_instance_valid(candidate) and candidate != unit:
			if _is_valid_enemy_target(candidate):
				var dist := unit.global_position.distance_to((candidate as Node3D).global_position)
				if dist < min_unit_dist:
					min_unit_dist = dist
					best_unit = candidate as Node3D

	if is_instance_valid(best_unit) and min_unit_dist <= 35.0:
		return best_unit

	# 2. PASO 2: Si no hay tropas enemigas vivas cerca, buscar EDIFICIOS enemigos
	var best_building: Node3D = null
	var min_bld_dist := INF
	var enemy_blds := tree.get_nodes_in_group("enemy_buildings") if my_bando == 0 else tree.get_nodes_in_group("player_buildings")

	for candidate in enemy_blds:
		if candidate is Node3D and is_instance_valid(candidate):
			if _is_valid_enemy_target(candidate):
				var dist := unit.global_position.distance_to((candidate as Node3D).global_position)
				if dist < min_bld_dist:
					min_bld_dist = dist
					best_building = candidate as Node3D

	return best_building if is_instance_valid(best_building) else best_unit
