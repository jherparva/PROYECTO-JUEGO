## StateMove3D — Estado de Movimiento y Navegación 3D (GDScript 2.0 / Godot 4).
##
## Utiliza NavigationAgent3D para evitar obstáculos en 3D y realiza rotación
## fluida hacia el vector de dirección/velocidad.

class_name StateMove3D
extends StateBase3D

# ─── Exports ───────────────────────────────────────────────────────────────────
@export var arrival_threshold: float = 1.2

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target_position: Vector3 = Vector3.ZERO
var _target_node: Node3D = null
var _on_arrival_state: StringName = &""
var _on_arrival_context: Dictionary = {}
var _stopping_distance: float = 1.0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	state_name = &"Move"

var _facing_direction: Vector3 = Vector3.ZERO
var _has_custom_target_pos: bool = false
var _stuck_timer: float = 0.0
var _context: Dictionary = {}

func enter(context: Dictionary = {}) -> void:
	_context            = context
	_target_node        = context.get("target_node", null) as Node3D
	_on_arrival_state   = context.get("on_arrival_state", &"")
	_on_arrival_context = context.get("on_arrival_context", {})
	_stopping_distance  = context.get("stopping_distance", arrival_threshold)
	_facing_direction   = context.get("facing_direction", Vector3.ZERO)
	_stuck_timer        = 0.0

	if context.has("target_position"):
		_target_position = context.get("target_position")
		_has_custom_target_pos = true
	elif is_instance_valid(_target_node):
		_target_position = _target_node.global_position
		_has_custom_target_pos = false
		if not context.has("stopping_distance"):
			if _target_node is BuildingBase3D or _target_node.is_in_group("buildings"):
				if _target_node.has_method("get_perimeter_stop_distance"):
					_stopping_distance = _target_node.get_perimeter_stop_distance()
				else:
					var is_tc := (_target_node is TownCenter3D or _target_node.is_in_group("town_centers"))
					_stopping_distance = 3.8 if is_tc else 4.0
			elif _target_node is ResourceNode3D or _target_node.is_in_group("resources"):
				_stopping_distance = 1.6
	else:
		_target_position = unit.global_position if unit else Vector3.ZERO
		_has_custom_target_pos = false

	if unit:
		unit.play_animation("walk")
		if unit.nav_agent:
			unit.nav_agent.target_position = _target_position
			unit.nav_agent.target_desired_distance = _stopping_distance

func physics_update(delta: float) -> void:
	if not is_instance_valid(unit):
		return

	if "is_stunned" in unit and unit.is_stunned:
		unit.velocity = Vector3.ZERO
		return

	# Si perseguimos una unidad móvil (characterbody), actualizar su posición objetivo
	if is_instance_valid(_target_node) and not _has_custom_target_pos:
		if _target_node is CharacterBody3D:
			_target_position = _target_node.global_position
			if unit.nav_agent:
				unit.nav_agent.target_position = _target_position

	# 1. Comprobar distancia de llegada a la posición objetivo
	var dist_to_target := unit.global_position.distance_to(_target_position)
	if dist_to_target <= _stopping_distance:
		_on_arrived()
		return

	# 2. Comprobar distancia directa al centro del nodo objetivo (edificio o recurso)
	# Si se definió una posición personalizada explícita (ranura exacta de granja o recurso), se respeta sin corte prematuro
	if is_instance_valid(_target_node) and not _has_custom_target_pos:
		var dist_to_node := unit.global_position.distance_to(_target_node.global_position)
		var node_stop_dist: float = _stopping_distance
		if not _context.has("stopping_distance"):
			if _target_node is BuildingBase3D or _target_node.is_in_group("buildings"):
				if _target_node.has_method("get_perimeter_stop_distance"):
					node_stop_dist = _target_node.get_perimeter_stop_distance()
				else:
					node_stop_dist = 3.8 if (_target_node is TownCenter3D or _target_node.is_in_group("town_centers")) else 4.0
			elif _target_node is ResourceNode3D or _target_node.is_in_group("resources"):
				node_stop_dist = 1.6

		if dist_to_node <= node_stop_dist:
			_on_arrived()
			return

	# 3. Detección anti-atascamiento al colisionar con cajas de colisión 3D
	if unit.get_slide_collision_count() > 0:
		_stuck_timer += delta
		if _stuck_timer >= 0.35:
			_stuck_timer = 0.0
			if is_instance_valid(_target_node):
				var dist_col := unit.global_position.distance_to(_target_node.global_position)
				if dist_col <= 6.0:
					_on_arrived()
					return
	else:
		_stuck_timer = 0.0

	if unit.nav_agent:
		_move_with_nav_agent(delta)
	else:
		_move_direct(delta)

func exit() -> void:
	_target_node = null
	if unit and unit.nav_agent:
		unit.velocity = Vector3.ZERO

# ─── Movimiento y Rotación ────────────────────────────────────────────────────

func _move_with_nav_agent(delta: float) -> void:
	if unit.nav_agent.is_navigation_finished():
		if unit.global_position.distance_to(_target_position) <= _stopping_distance + 0.8:
			_on_arrived()
			return
		else:
			# Fallback a movimiento directo si el agente reporta completado prematuramente
			_move_direct(delta)
			return

	var next_pos: Vector3 = unit.nav_agent.get_next_path_position()
	var move_dir: Vector3 = (next_pos - unit.global_position)
	move_dir.y = 0.0 # Mantener movimiento en plano horizontal XZ
	
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()
		# Aplicar amortiguación para rodear edificios a distancia segura
		move_dir = _apply_obstacle_clearance(move_dir)
		unit.velocity = move_dir * unit.speed
		unit.rotate_towards_direction(unit.velocity, delta)
	else:
		# Fallback a movimiento directo si el navmesh no está horneado
		_move_direct(delta)
		return

	unit.move_and_slide()

func _move_direct(delta: float) -> void:
	var to_target := (_target_position - unit.global_position)
	to_target.y = 0.0
	
	if to_target.length_squared() > 0.01:
		var move_dir := to_target.normalized()
		# Aplicar amortiguación predictiva antes de chocar
		move_dir = _apply_obstacle_clearance(move_dir)

		# Deslizamiento inteligente adicional al colisionar con troncos, rocas o edificios
		if unit.get_slide_collision_count() > 0:
			var collision := unit.get_slide_collision(0)
			var normal := collision.get_normal()
			normal.y = 0.0
			if normal.length_squared() > 0.01:
				normal = normal.normalized()
				var tangent_left := Vector3(-normal.z, 0.0, normal.x)
				var tangent_right := Vector3(normal.z, 0.0, -normal.x)
				var best_tangent := tangent_left if tangent_left.dot(move_dir) > tangent_right.dot(move_dir) else tangent_right
				move_dir = (move_dir * 0.2 + best_tangent * 0.8).normalized()

		unit.velocity = move_dir * unit.speed
		unit.rotate_towards_direction(unit.velocity, delta)
	else:
		unit.velocity = Vector3.ZERO
		
	unit.move_and_slide()

## Aplica una fuerza de dirección tangencial con distancia de seguridad ante edificios y obstáculos
func _apply_obstacle_clearance(raw_move_dir: Vector3) -> Vector3:
	var final_dir := raw_move_dir
	if not is_instance_valid(unit):
		return final_dir

	var my_pos := unit.global_position
	var buildings := get_tree().get_nodes_in_group("buildings_3d")

	# Determinar si el destino actual es un Town Center (depósito) para excluirlo del clearance
	var _target_is_tc: bool = is_instance_valid(_target_node) and (
		_target_node is TownCenter3D or _target_node.is_in_group("town_centers")
	)

	for obs in buildings:
		if not is_instance_valid(obs) or not (obs is Node3D):
			continue
		# Excluir el nodo destino del clearance para que el aldeano pueda acercarse directamente
		if obs == _target_node:
			continue
		# Si vamos a un TC, también excluir otros TCs del clearance para evitar deflexiones cruzadas
		if _target_is_tc and (obs is TownCenter3D or obs.is_in_group("town_centers")):
			continue
		var obs_pos: Vector3 = (obs as Node3D).global_position
		var to_obs := (obs_pos - my_pos)
		to_obs.y = 0.0
		var dist := to_obs.length()

		# Radio de seguridad: TC vecinos 4.5m (era 6.2), otros edificios 3.5m (era 4.2)
		var safe_radius: float = 4.5 if (obs is TownCenter3D or obs.is_in_group("town_centers")) else 3.5
		var buffer_dist: float = safe_radius + 1.5  # antes +2.2, reducido para evitar el bucle orbital

		if dist < buffer_dist and dist > 0.01:
			var obs_dir := to_obs / dist
			# Si el personaje se mueve en dirección al obstáculo
			var forward_dot := raw_move_dir.dot(obs_dir)
			if forward_dot > 0.05:
				var t_left := Vector3(-obs_dir.z, 0.0, obs_dir.x)
				var t_right := Vector3(obs_dir.z, 0.0, -obs_dir.x)
				var best_tangent := t_left if t_left.dot(raw_move_dir) > t_right.dot(raw_move_dir) else t_right
				var push_away := -obs_dir

				# Ponderación suave reducida para que el esquive sea menos agresivo
				var avoidance_weight := clampf((buffer_dist - dist) / 1.5, 0.2, 0.75)
				var steer := (best_tangent * 0.65 + push_away * 0.35).normalized()
				final_dir = (final_dir * (1.0 - avoidance_weight) + steer * avoidance_weight).normalized()

	return final_dir

func _on_arrived() -> void:
	unit.velocity = Vector3.ZERO
	if _on_arrival_state != &"":
		state_machine.change_state(_on_arrival_state, _on_arrival_context)
	else:
		state_machine.change_state(&"Idle", {"facing_direction": _facing_direction})
