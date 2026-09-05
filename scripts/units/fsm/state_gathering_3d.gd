## StateGathering3D — Estado de Recolección y Depósito 3D (GDScript 2.0 / Godot 4).
##
## Resuelve el bucle automático infinito RTS:
## 1. Desplazamiento hacia el nodo de recurso.
## 2. Extracción progresiva hasta MAX_CARGA (15 unidades) con animación y prop en mano.
## 3. Al llenarse la carga, activa la cesta/fardo en "BackAttachment".
## 4. Busca el Centro de Ciudad (Town Center) más cercano y navega hacia él.
## 5. Deposita los recursos en el Town Center (incrementando el Autoload ResourceManager).
## 6. Oculta el fardo de la espalda y regresa automáticamente a recolectar si el recurso sigue activo.

class_name StateGathering3D
extends StateBase3D

# ─── Exports ───────────────────────────────────────────────────────────────────
# ─── Exports ───────────────────────────────────────────────────────────────────
@export var gather_range: float = 1.8
@export var deposit_range: float = 4.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _resource_node: Node3D = null
var _town_center: Node3D = null
var _gather_timer: float = 0.0
var _last_resource_type: String = "wood"

var _is_waiting_for_slot: bool = false
var _wait_check_timer: float = 0.0
var _just_deposited: bool = false

# ─── Variables de Protocolo de Apertura de Paso (Yield Pass) ─────────────────
var _is_yielding_pass: bool = false
var _yield_original_pos: Vector3 = Vector3.ZERO
var _yield_timer: float = 0.0
var _yielding_for_villager: Node3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	state_name = &"Gathering"

func enter(context: Dictionary = {}) -> void:
	var villager := unit as Villager3D
	print("ENTER GATHERING: unit=%s villager=%s context=%s" % [unit, villager, context])
	if not villager:
		state_machine.change_state(&"Idle")
		return

	# Siempre resetear el timer al entrar en el estado
	_gather_timer = 0.0
	_is_waiting_for_slot = bool(context.get("is_waiting", false))
	_just_deposited = false
	_is_yielding_pass = false
	_yield_original_pos = Vector3.ZERO
	_yield_timer = 0.0
	_yielding_for_villager = null

	# CASO 1: Llegada al Centro de Ciudad para depositar recursos
	if context.has("deposit_target"):
		_just_deposited = true
		var raw_tc = context.get("deposit_target", null)
		var tc: Node3D = raw_tc as Node3D if is_instance_valid(raw_tc) else null
		if is_instance_valid(tc):
			_deposit_to_town_center(tc)

		# Recuperar el nodo de recurso original
		var raw_res = context.get("target_node", null)
		_resource_node = raw_res as Node3D if is_instance_valid(raw_res) else null
		if not is_instance_valid(_resource_node) and is_instance_valid(villager.last_resource_node):
			_resource_node = villager.last_resource_node

		if is_instance_valid(_resource_node) and _resource_node.has_method("get_resource_type"):
			_last_resource_type = _resource_node.get_resource_type()
		elif not villager.carried_resource_type.is_empty():
			_last_resource_type = villager.carried_resource_type
		elif not villager.last_resource_type.is_empty():
			_last_resource_type = villager.last_resource_type

		# Si el recurso sigue existiendo y no está agotado, SIEMPRE navegar de regreso automáticamente
		if is_instance_valid(_resource_node) and not (_resource_node.has_method("is_depleted") and _resource_node.is_depleted()):
			_navigate_to_resource(_resource_node)
			return
		else:
			# Si el recurso se agotó, buscar el recurso más cercano del mismo tipo a 35m
			var next_resource := _find_nearest_resource_node()
			if is_instance_valid(next_resource):
				_navigate_to_resource(next_resource)
				return
			else:
				villager.set_status_text("")
				state_machine.change_state(&"Idle")
				return

	# CASO 2: Orden directa de recolectar un nodo de recurso
	if context.has("target_node"):
		var raw_target = context.get("target_node", null)
		_resource_node = raw_target as Node3D if is_instance_valid(raw_target) else null
		if is_instance_valid(_resource_node) and _resource_node.has_method("get_resource_type"):
			var new_type: String = _resource_node.get_resource_type()
			if villager.carried_resource_type != new_type and villager.carried_amount > 0:
				villager.clear_inventory()

	if not is_instance_valid(_resource_node):
		state_machine.change_state(&"Idle")
		return

	# Si el aldeano está esperando turno (el nodo estaba en cupo 6/6)
	if _is_waiting_for_slot:
		villager.set_gathering_animation(false)
		villager.set_status_text("⏳ Esperando turno (Lleno 6/6)")
		return

	# Si el aldeano ya está lleno de carga antes de recolectar, ir a depositar primero
	if villager.is_inventory_full():
		_go_to_deposit()
		return

	# Si ya llegó vía Move o está al alcance del recurso (dist <= max_reach)
	var is_arrived: bool = bool(context.get("arrived", false))
	var dist_to_res := villager.global_position.distance_to(_resource_node.global_position)
	var is_bld_res: bool = (_resource_node is Farm3D or _resource_node is BuildingBase3D or _resource_node.is_in_group("farms") or _resource_node.is_in_group("buildings"))
	var max_reach: float = 4.8 if is_bld_res else 1.8
	if is_arrived or dist_to_res <= max_reach:
		_start_gathering_visuals()
	else:
		_navigate_to_resource(_resource_node)

func physics_update(delta: float) -> void:
	var villager := unit as Villager3D
	if not villager or not is_instance_valid(_resource_node):
		state_machine.change_state(&"Idle")
		return

	# ─── 1. MANIOBRA DE APERTURA DE PASO ACTIVA (YIELD PASS) ─────────────────
	if _is_yielding_pass:
		_yield_timer += delta
		var companion_cleared: bool = false
		var v_cur_pos: Vector3 = villager.global_position if villager.global_position.length_squared() > 0.001 else villager.position
		if not is_instance_valid(_yielding_for_villager):
			companion_cleared = true
		elif _yield_timer >= 2.5:
			companion_cleared = true
		else:
			var ally_cur_pos: Vector3 = _yielding_for_villager.global_position if _yielding_for_villager.global_position.length_squared() > 0.001 else _yielding_for_villager.position
			if ally_cur_pos.distance_to(_yield_original_pos) > 2.6:
				companion_cleared = true

		if companion_cleared:
			# Reanudar de forma autónoma su posición de picado justa
			var step := villager.speed * delta * 1.5
			var next_p := v_cur_pos.move_toward(_yield_original_pos, step)
			villager.position = next_p
			villager.global_position = next_p
			if next_p.distance_to(_yield_original_pos) <= 0.08:
				villager.position = _yield_original_pos
				villager.global_position = _yield_original_pos
				_is_yielding_pass = false
				_yielding_for_villager = null
				_yield_timer = 0.0
				_start_gathering_visuals()
		return

	# Si está esperando cupo disponible
	if _is_waiting_for_slot:
		_wait_check_timer += delta
		if _wait_check_timer >= 1.0:
			_wait_check_timer = 0.0
			if _resource_node.has_method("request_gather_slot"):
				var slot_data: Dictionary = _resource_node.request_gather_slot(villager)
				if slot_data.get("has_slot", false):
					_is_waiting_for_slot = false
					_navigate_to_resource(_resource_node)
		return

	# ─── 2. DETECCIÓN DE COMPAÑERO CON FARDO LLENO (YIELD PASS TRIGGER) ──────
	# Si un aldeano aliado con inventory_full == true intenta salir hacia el Town Center,
	# interrumpir animación y retroceder exactamente 1.2m para despejar pasillo de escape.
	if is_instance_valid(villager) and not _is_waiting_for_slot:
		var my_bando: int = int(villager.get("bando")) if "bando" in villager else 0
		var villagers_candidates: Array = []
		var tree_inst := get_tree_safe()
		if is_instance_valid(tree_inst):
			villagers_candidates = tree_inst.get_nodes_in_group("villagers")
		elif is_instance_valid(villager) and is_instance_valid(villager.get_parent()):
			for ch in villager.get_parent().get_children():
				if ch.is_in_group("villagers"):
					villagers_candidates.append(ch)

		for ally_node in villagers_candidates:
				if ally_node == villager or not is_instance_valid(ally_node) or not (ally_node is Node3D):
					continue
				var ally := ally_node as Node3D
				var ally_bando: int = int(ally.get("bando")) if "bando" in ally else 0
				if ally_bando != my_bando:
					continue

				var ally_full := false
				if "inventory_full" in ally and bool(ally.get("inventory_full")):
					ally_full = true
				elif ally.has_method("is_inventory_full") and ally.call("is_inventory_full"):
					ally_full = true
				elif "carried_amount" in ally and int(ally.get("carried_amount")) >= 15:
					ally_full = true

				if ally_full:
					var v_pos: Vector3 = villager.global_position if villager.global_position.length_squared() > 0.001 else villager.position
					var ally_pos: Vector3 = ally.global_position if ally.global_position.length_squared() > 0.001 else ally.position
					var dist_to_companion := v_pos.distance_to(ally_pos)
					if dist_to_companion <= 1.8:
						_is_yielding_pass = true
						_yielding_for_villager = ally
						_yield_original_pos = v_pos
						_yield_timer = 0.0
						villager.set_gathering_animation(false)

						var escape_dir := (v_pos - ally_pos)
						escape_dir.y = 0.0
						if escape_dir.length_squared() < 0.001:
							escape_dir = -villager.transform.basis.z
							escape_dir.y = 0.0
						escape_dir = escape_dir.normalized()

						var new_p := _yield_original_pos + (escape_dir * 1.2)
						villager.position = new_p
						villager.global_position = new_p
						villager.set_status_text("🚶 Cediedo paso libre...", 1.2)
						return

	# Verificar si el recurso se agotó durante el proceso
	if _resource_node.has_method("is_depleted") and _resource_node.is_depleted():
		if villager.carried_amount > 0:
			_go_to_deposit()
		else:
			var next_node := _find_nearest_resource_node()
			if is_instance_valid(next_node):
				_navigate_to_resource(next_node)
			else:
				villager.set_status_text("")
				state_machine.change_state(&"Idle")
		return

	# Verificar si se alejó demasiado del recurso (distancia justa y cercana)
	var is_bld: bool = (_resource_node is Farm3D or _resource_node is BuildingBase3D or _resource_node.is_in_group("farms") or _resource_node.is_in_group("buildings"))
	var max_gather_dist: float = 5.2 if is_bld else 1.85
	var res_pos: Vector3 = _resource_node.global_position if _resource_node.global_position.length_squared() > 0.001 else _resource_node.position
	var cur_v_pos: Vector3 = villager.global_position if villager.global_position.length_squared() > 0.001 else villager.position
	var dist := cur_v_pos.distance_to(res_pos)
	if dist > max_gather_dist:
		_navigate_to_resource(_resource_node)
		return

	# Mantener al aldeano orientado hacia el nodo de recurso
	var dir_to_res := (_resource_node.global_position - villager.global_position)
	villager.rotate_towards_direction(dir_to_res, delta)

	# Ticks de extracción de recursos
	_gather_timer += delta
	var spd_mod := _get_game_speed_modifier()
	var interval := 1.0 / (villager.gather_rate * spd_mod)
	if _gather_timer >= interval:
		_gather_timer = 0.0
		_perform_gather_tick()

const GameSettingsClass = preload("res://scripts/core/game_settings.gd")

func _get_game_speed_modifier() -> float:
	return GameSettingsClass.get_game_speed_mod()

func get_gather_interval(villager: Villager3D) -> float:
	return 1.0 / (villager.gather_rate * _get_game_speed_modifier())

func exit() -> void:
	_gather_timer = 0.0
	_is_waiting_for_slot = false
	_just_deposited = false
	var villager := unit as Villager3D
	if villager:
		villager.set_gathering_animation(false)
		if _is_yielding_pass and _yield_original_pos != Vector3.ZERO:
			villager.global_position = _yield_original_pos
		_is_yielding_pass = false
		_yield_original_pos = Vector3.ZERO
		_yielding_for_villager = null
		_yield_timer = 0.0
		if is_instance_valid(_resource_node) and _resource_node.has_method("release_gather_slot"):
			_resource_node.release_gather_slot(villager)

# ─── Bucle Interno de Recolección y Depósito ───────────────────────────────────

func _start_gathering_visuals() -> void:
	var villager := unit as Villager3D
	if not villager or not is_instance_valid(_resource_node):
		return
		
	var res_type: String = "wood"
	if _resource_node.has_method("get_resource_type"):
		res_type = _resource_node.get_resource_type()
		
	# Activar la herramienta correspondiente en "RightHandAttachment"
	var tool_name := _get_tool_name_for_resource(res_type)
	villager.update_hand_tool_visual(tool_name)
	villager.set_gathering_animation(true)
	var icon: String = _get_icon_for_resource(res_type)
	villager.set_status_text("%s Recolectando..." % icon)

func _perform_gather_tick() -> void:
	var villager := unit as Villager3D
	if not villager or not is_instance_valid(_resource_node):
		return

	var res_type: String = "wood"
	if _resource_node.has_method("get_resource_type"):
		res_type = _resource_node.get_resource_type()

	# Extraer unidades del nodo escaladas por el modificador de velocidad
	var spd_mod := _get_game_speed_modifier()
	var tick_increment: int = maxi(1, int(round(1.0 * spd_mod)))
	var extracted: int = 0
	if _resource_node.has_method("extract"):
		extracted = _resource_node.extract(tick_increment)

	if extracted > 0:
		villager.add_carried_resource(res_type, extracted)
		var icon: String = _get_icon_for_resource(res_type)
		villager.set_status_text("%s %d/%d" % [icon, villager.carried_amount, villager.MAX_CARGA])

	# Si alcanzamos la capacidad máxima (MAX_CARGA = 15) o se agotó el recurso
	if villager.is_inventory_full() or (_resource_node.has_method("is_depleted") and _resource_node.is_depleted()):
		_go_to_deposit()

func _go_to_deposit() -> void:
	var villager := unit as Villager3D
	if not villager:
		return

	villager.set_gathering_animation(false)
	villager.update_back_prop_visual()
	villager.set_hand_prop("")
	villager.set_status_text("🎒 ¡Lleno! Llevando al Centro...")

	var tc := _find_nearest_town_center()
	if is_instance_valid(tc):
		_town_center = tc
		state_machine.change_state(&"Move", {
			"target_node": tc,
			"stopping_distance": deposit_range,
			"on_arrival_state": &"Gathering",
			"on_arrival_context": {
				"deposit_target": tc,
				"target_node": _resource_node
			}
		})
	else:
		state_machine.change_state(&"Idle")

func _deposit_to_town_center(tc: Node3D) -> void:
	var villager := unit as Villager3D
	if not villager:
		return

	var cargo := villager.clear_inventory()
	var res_type: String = cargo.get("type", "")
	var amount: int = cargo.get("amount", 0)

	if amount > 0 and not res_type.is_empty():
		var unit_bando: int = int(villager.get("bando")) if "bando" in villager else 0
		if unit_bando == 0:
			# Aldeano del jugador: depositar en TownCenter o GlobalResourceManager
			if tc.has_method("deposit_resources"):
				tc.deposit_resources(res_type, amount, villager)
			else:
				var tree_inst := get_tree_safe()
				var rm: Node = tree_inst.root.get_node_or_null("ResourceManager") if tree_inst and tree_inst.root else null
				if is_instance_valid(rm) and rm.has_method("add_resources"):
					rm.add_resources(res_type, amount)
		else:
			# Aldeano enemigo: depositar en la economía de la IA enemiga
			var tree_inst := get_tree_safe()
			var enemy_ais := tree_inst.get_nodes_in_group("enemy_ai") if is_instance_valid(tree_inst) else []
			for ai in enemy_ais:
				if is_instance_valid(ai) and ai.has_method("agregar_recursos_ia"):
					ai.agregar_recursos_ia({res_type: amount})

		villager.set_status_text("✨ +%d %s" % [amount, res_type.capitalize()], 2.5)

func _get_pos(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	if node.global_position.length_squared() > 0.001:
		return node.global_position
	return node.position

func _navigate_to_resource(res_node: Node3D) -> void:
	_resource_node = res_node
	var villager := unit as Villager3D
	var res_type: String = _last_resource_type
	if res_node.has_method("get_resource_type"):
		res_type = res_node.get_resource_type()
		_last_resource_type = res_type

	var target_pos: Vector3 = _get_pos(res_node)
	var is_waiting := false

	if res_node.has_method("request_gather_slot") and villager:
		var slot_data: Dictionary = res_node.request_gather_slot(villager)
		if slot_data.get("has_slot", false):
			target_pos = slot_data.get("slot_pos", _get_pos(res_node))
		else:
			target_pos = slot_data.get("wait_pos", _get_pos(res_node) + Vector3(6.5, 0.0, 0.0))
			is_waiting = true
	else:
		var angle := randf() * TAU
		target_pos = _get_pos(res_node) + Vector3(cos(angle), 0.0, sin(angle)) * 3.0

	if villager:
		if is_waiting:
			villager.set_status_text("⏳ Esperando turno (Lleno 6/6)", 3.0)
		else:
			var icon: String = _get_icon_for_resource(res_type)
			villager.set_status_text("🚶 %s..." % icon)

	var is_bld_target: bool = (res_node is Farm3D or res_node is BuildingBase3D or res_node.is_in_group("farms") or res_node.is_in_group("buildings"))
	var stop_dist: float = 1.2 if is_waiting else (0.8 if is_bld_target else 0.45)

	state_machine.change_state(&"Move", {
		"target_node": res_node,
		"target_position": target_pos,
		"stopping_distance": stop_dist,
		"on_arrival_state": &"Gathering",
		"on_arrival_context": {
			"target_node": res_node,
			"is_waiting": is_waiting,
			"arrived": true
		}
	})

func _get_icon_for_resource(res_type: String) -> String:
	match res_type.to_lower():
		"wood":  return "🪵"
		"food":  return "🍖"
		"stone": return "🪨"
		"iron":  return "⚙️"
		"gold":  return "🪙"
	return "📦"

# ─── Helpers de Búsqueda ───────────────────────────────────────────────────────

func _find_nearest_town_center() -> Node3D:
	var best_tc: Node3D = null
	var min_dist := INF
	var unit_bando: int = int(unit.get("bando")) if "bando" in unit else 0
	var tree := get_tree_safe()
	var candidates: Array[Node] = []

	if is_instance_valid(tree):
		if unit_bando == 0:
			candidates.append_array(tree.get_nodes_in_group("town_centers"))
		else:
			for node in tree.get_nodes_in_group("town_centers"):
				var b: int = int(node.get("bando")) if "bando" in node else -1
				var under_const: bool = bool(node.get("esta_en_construccion")) if "esta_en_construccion" in node else false
				if b != 0 and not under_const:
					candidates.append(node)
		if candidates.is_empty():
			candidates.append_array(tree.get_nodes_in_group("enemy_ai"))

	if candidates.is_empty() and is_instance_valid(unit) and is_instance_valid(unit.get_parent()):
		for child in unit.get_parent().get_children():
			if child.is_in_group("town_centers") or (child is BuildingBase3D and child.name.contains("Capitolio")):
				candidates.append(child)

	var unit_pos := _get_pos(unit)
	for node in candidates:
		if node is Node3D and is_instance_valid(node):
			var dist := unit_pos.distance_to(_get_pos(node as Node3D))
			if dist < min_dist:
				min_dist = dist
				best_tc = node as Node3D

	return best_tc

func _find_nearest_resource_node() -> Node3D:
	var target_type := _last_resource_type
	if is_instance_valid(_resource_node) and _resource_node.has_method("get_resource_type"):
		target_type = _resource_node.get_resource_type()
	elif unit and ("carried_resource_type" in unit) and not str(unit.get("carried_resource_type")).is_empty():
		target_type = str(unit.get("carried_resource_type"))

	if target_type.is_empty():
		target_type = "wood"

	var best_res: Node3D = null
	var min_dist := INF
	var is_player_unit: bool = (int(unit.get("bando")) == 0) if "bando" in unit else true
	var tree := get_tree_safe()

	var fow: Node = tree.get_first_node_in_group("fog_of_war_manager") if is_instance_valid(tree) else null

	var candidates: Array[Node] = []
	if is_instance_valid(tree):
		candidates.append_array(tree.get_nodes_in_group("resources_3d"))
		candidates.append_array(tree.get_nodes_in_group("resources"))
		if target_type.to_lower() == "food":
			candidates.append_array(tree.get_nodes_in_group("fauna"))
			candidates.append_array(tree.get_nodes_in_group("animals_3d"))

	# Respaldo si los grupos no están indexados (por ejemplo en tests de scene tree no activo)
	if candidates.is_empty():
		var parent_node: Node = null
		if is_instance_valid(unit) and is_instance_valid(unit.get_parent()):
			parent_node = unit.get_parent()
		elif is_instance_valid(tree) and is_instance_valid(tree.root):
			parent_node = tree.root
		if is_instance_valid(parent_node):
			for child in parent_node.get_children():
				if child.is_in_group("resources_3d") or child.is_in_group("resources") or child is ResourceNode3D:
					candidates.append(child)

	var unit_pos := _get_pos(unit)
	for node in candidates:
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node != _resource_node:
			# Si es fauna animal, solo considerar carcasas muertas
			if node is FaunaAnimal3D or node.is_in_group("fauna"):
				var is_dead_animal: bool = bool(node.get("is_animal_dead")) if "is_animal_dead" in node else (bool(node.get("is_dead")) if "is_dead" in node else false)
				if not is_dead_animal:
					continue

			if node.has_method("is_depleted") and not node.is_depleted():
				if node.has_method("get_resource_type") and node.get_resource_type().to_lower() == target_type.to_lower():
					# Si es del jugador, verificar niebla de guerra si está activa
					if is_player_unit and is_instance_valid(fow) and fow.has_method("is_position_explored"):
						if not fow.is_position_explored(_get_pos(node as Node3D)):
							continue
					var dist := unit_pos.distance_to(_get_pos(node as Node3D))
					# Radio de escaneo autónomo: 35 metros
					if is_player_unit and dist > 35.0:
						continue
					if dist < min_dist:
						min_dist = dist
						best_res = node as Node3D

	return best_res

func _get_tool_name_for_resource(res_type: String) -> String:
	match res_type.to_lower():
		"wood": return "axe"
		"stone", "iron", "gold": return "pickaxe"
		"food": return "spear"
		_: return "axe"
