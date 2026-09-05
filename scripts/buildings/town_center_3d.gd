## TownCenter3D — Centro de Ciudad 3D con Puntos de Reunión (Rally Points) (GDScript 2.0 / Godot 4).
##
## Permite establecer Puntos de Reunión (Rally Points) en el suelo o en nodos de recursos.
## Al entrenar unidades las despacha de forma inteligente en el mismo frame de aparición.
## Incluye el Sistema de Evolución por Eras: inicia la transición vía iniciar_evolucion_era()
## con un temporizador de 15 segundos, descuenta recursos y emite era_evolucionada al completar.

class_name TownCenter3D
extends "res://scripts/buildings/building_base_3d.gd"


# ─── Señales ───────────────────────────────────────────────────────────────────
signal resource_deposited(resource_type: String, amount: int, villager: Node3D)
signal unit_queued(unit_type: String, queue_size: int)
signal queue_progress_updated(progress: float, current_unit_type: String)
signal unit_spawned(unit_instance: Node3D)
## Emitida cada frame durante la cuenta atrás de evolución (para barra de progreso en HUD).
signal era_progreso_actualizado(progreso: float, era_destino: String)
## Emitida si la evolución se cancela (fondos insuficientes o condición inválida).
signal era_evolucion_cancelada(motivo: String)

# ─── Configuración de Producción ───────────────────────────────────────────────
@export_group("Entrenamiento de Aldeanos")
@export var villager_cost: Dictionary = {"food": 50}
@export var villager_train_time: float = 5.0
@export var spawn_offset: Vector3 = Vector3(4.8, 0.0, 4.8)
@export var villager_scene: PackedScene = null

# ─── Configuración de Evolución de Era ─────────────────────────────────────────
@export_group("Sistema de Eras")
## Duracion de transicion base entre eras (se sobreescribe por ERA_BUILD_TIMES_SECONDS).
@export var era_transition_time: float = 125.0

# --- Tiempos de Construccion de Era (dbupgrade.dat) ---------------------------
## Tiempo real en segundos para completar la transicion a cada era.
## Datos extraidos de dbupgrade.dat de Empire Earth original.
const ERA_BUILD_TIMES_SECONDS: Dictionary = {
	0: 125.0,  ## Prehistoria -> Piedra      (125s segun dbupgrade.dat)
	1: 130.0,  ## Piedra -> Bronce            (130s)
	2: 135.0,  ## Bronce -> Hierro            (135s)
	3: 140.0,  ## Hierro -> Medieval          (140s)
	4: 145.0,  ## Medieval -> Renacimiento    (145s)
	5: 150.0,  ## Renacimiento -> Industrial  (150s)
	6: 155.0,  ## Industrial -> Atomica       (155s)
	7: 165.0,  ## Atomica -> Digital          (165s)
	8: 175.0,  ## Digital -> Nano-Futurista   (175s)
	9: 185.0,  ## Era maxima (sentinel)       (185s)
}

## Nombres de era completos para los 10 periodos historicos del juego.
const NOMBRES_ERA_TC: Dictionary = {
	0: "Edad Prehistorica",
	1: "Edad de Piedra",
	2: "Edad de Bronce",
	3: "Edad de Hierro",
	4: "Edad Media",
	5: "Era del Renacimiento",
	6: "Era Industrial",
	7: "Era Atomica",
	8: "Era Digital",
	9: "Era Nano-Futurista",
}

# ─── Estado de la Cola de Producción ───────────────────────────────────────────
var production_queue: Array[Dictionary] = []
var current_train_timer: float = 0.0

# ─── Estado de la Evolución de Era ─────────────────────────────────────────────
## true mientras la transición de era está en curso.
var esta_evolucionando: bool = false
var evolucionando: bool:
	get:
		return esta_evolucionando
	set(val):
		esta_evolucionando = val
## Timer de Godot que gestiona los 15 segundos de transición.
var _era_timer: Timer = null
## Tiempo transcurrido de la transición actual (para barra de progreso en HUD).
var _era_elapsed: float = 0.0
## Nombre de la era de destino para mostrar en la UI.
var _era_destino_nombre: String = ""
## Valor enum de la era de destino al completar el temporizador.
var _era_destino_valor: int = -1

func _ensure_era_timer() -> void:
	if not is_instance_valid(_era_timer):
		_era_timer = get_node_or_null("EraEvolutionTimer") as Timer
	if not is_instance_valid(_era_timer):
		_era_timer = Timer.new()
		_era_timer.name = "EraEvolutionTimer"
		_era_timer.one_shot = true
		_era_timer.autostart = false
		_era_timer.wait_time = era_transition_time
		if not _era_timer.timeout.is_connected(_on_era_timer_timeout):
			_era_timer.timeout.connect(_on_era_timer_timeout)
		add_child(_era_timer)


# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()
	building_name = "TownCenter3D"
	max_hp = 1200
	hp = max_hp

	add_to_group("town_centers")
	add_to_group("town_centers_3d")
	radio_vision = 48.0

	# Asignación estricta de Autoridad de Red y Bando
	if is_multiplayer_authority():
		bando = Bando.PLAYER
		add_to_group("player_buildings")
		if is_in_group("enemy_buildings"):
			remove_from_group("enemy_buildings")
	else:
		bando = Bando.ENEMY
		add_to_group("enemy_buildings")
		if is_in_group("player_buildings"):
			remove_from_group("player_buildings")

	if villager_scene == null:
		villager_scene = load("res://scenes/units/villager_3d.tscn") as PackedScene

	# Sincronización Inmediata con la Era Inicial configurada (Runtime Mesh Swap)
	var gs: Node = get_node_or_null("/root/GameSettings")
	var rm: Node = get_node_or_null("/root/ResourceManager")
	var era_val: int = 0
	if is_instance_valid(gs) and "starting_era" in gs:
		era_val = int(gs.get("starting_era"))
	elif is_instance_valid(rm) and "era_actual" in rm:
		era_val = int(rm.era_actual)

	if is_instance_valid(rm) and "era_actual" in rm and int(rm.era_actual) != era_val:
		rm.set("era_actual", era_val)
		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", era_val)

	_actualizar_modelo_visual_era(era_val)

	# Establecer rally_point por defecto
	rally_point = global_position + spawn_offset

	# Crear el Timer del sistema de evolución de era (one-shot, no autostart)
	_era_timer = Timer.new()
	_era_timer.name = "EraEvolutionTimer"
	_era_timer.one_shot = true
	_era_timer.autostart = false
	_era_timer.wait_time = era_transition_time
	_era_timer.timeout.connect(_on_era_timer_timeout)
	add_child(_era_timer)

	call_deferred("_spawn_initial_units_authority")

var _initial_units_spawned: bool = false

## Rutina de inicialización que lee estrictamente el bando de su autoridad.
## Si el dueño es Humano (PLAYER), nacen ÚNICAMENTE 5 Villager3D pacíficos.
## Si es Bot de IA (ENEMY), respeta su base militar en su propia esquina calculada.
func _spawn_initial_units_authority() -> void:
	if _initial_units_spawned:
		return

	# Solo el servidor o la autoridad local despacha el spawn
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server() and not is_multiplayer_authority():
		return

	var unit_container: Node = null
	if get_tree() and get_tree().current_scene:
		unit_container = get_tree().current_scene.get_node_or_null("World/Units")
		if not unit_container:
			unit_container = get_tree().current_scene.get_node_or_null("Units")
		if not unit_container:
			unit_container = get_tree().current_scene
	if not unit_container:
		unit_container = get_parent()

	# Verificar si ya existen unidades generadas en un radio de 16m
	var existing_units := get_tree().get_nodes_in_group("units_3d") if get_tree() else []
	var nearby_count: int = 0
	for u in existing_units:
		if is_instance_valid(u) and u is Node3D:
			if (u as Node3D).global_position.distance_to(global_position) <= 16.0:
				nearby_count += 1

	if nearby_count >= 5:
		_initial_units_spawned = true
		return

	# Si el Capitolio es Humano / Jugador Local
	if is_multiplayer_authority() or bando == Bando.PLAYER:
		if villager_scene == null:
			villager_scene = load("res://scenes/units/villager_3d.tscn") as PackedScene

		var needed: int = 5 - nearby_count
		for i in range(needed):
			var vil_node: Node = null
			if is_instance_valid(villager_scene):
				vil_node = villager_scene.instantiate()
			else:
				var v_fallback := Villager3D.new()
				v_fallback.name = "Villager3D"
				vil_node = v_fallback

			if is_instance_valid(vil_node) and vil_node is Node3D:
				var v3d := vil_node as Node3D
				v3d.name = "Vil_H_Init_%d" % (nearby_count + i + 1)
				var angle := float(i) * (TAU / maxf(float(needed), 1.0))
				var spawn_p := global_position + Vector3(cos(angle) * 4.5, 0.0, sin(angle) * 4.5)
				v3d.position = spawn_p
				if v3d.has_method("set_multiplayer_authority"):
					v3d.call("set_multiplayer_authority", get_multiplayer_authority())
				if "owner_peer_id" in v3d:
					v3d.set("owner_peer_id", owner_peer_id)
				if "bando" in v3d:
					v3d.set("bando", 0)
				v3d.add_to_group("player_units")
				v3d.add_to_group("unidades")
				v3d.add_to_group("units_3d")
				v3d.add_to_group("villagers")
				v3d.add_to_group("civilian_units")
				if is_instance_valid(unit_container):
					unit_container.add_child(v3d)
				else:
					add_child(v3d)
				v3d.global_position = spawn_p

				var rm_node: Node = _get_resource_manager()
				var cur_era_spawn: int = int(rm_node.era_actual) if is_instance_valid(rm_node) and "era_actual" in rm_node else 0
				if v3d.has_method("_actualizar_modelo_visual_era"):
					v3d.call("_actualizar_modelo_visual_era", cur_era_spawn)

		_initial_units_spawned = true
		print("TownCenter3D '%s': ✅ 5 Villager3D pacíficos nacidos bajo Bando.PLAYER." % name)
	else:
		_initial_units_spawned = true
		print("TownCenter3D '%s': Capitolio de IA configurado en su esquina (Bando.ENEMY)." % name)

func _get_resource_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		var rm := get_tree().root.get_node_or_null("ResourceManager")
		if is_instance_valid(rm):
			return rm
	if is_instance_valid(get_parent()):
		var rm := get_parent().get_node_or_null("ResourceManager")
		if is_instance_valid(rm):
			return rm
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree and (main_loop as SceneTree).root:
		var rm := (main_loop as SceneTree).root.get_node_or_null("ResourceManager")
		if is_instance_valid(rm):
			return rm
	return null

var mock_time_left: float = -1.0

func get_era_progress_percentage() -> int:
	if not (evolucionando or esta_evolucionando):
		return 0
	if mock_time_left >= 0.0:
		var wt: float = _era_timer.wait_time if is_instance_valid(_era_timer) and _era_timer.wait_time > 0.0 else era_transition_time
		return int((1.0 - (mock_time_left / wt)) * 100)
	if is_instance_valid(_era_timer) and not _era_timer.is_stopped() and _era_timer.wait_time > 0.0:
		return int((1.0 - (_era_timer.time_left / _era_timer.wait_time)) * 100)
	return 0

func get_era_progress_fraction() -> float:
	if not (evolucionando or esta_evolucionando):
		return 0.0
	if mock_time_left >= 0.0:
		var wt: float = _era_timer.wait_time if is_instance_valid(_era_timer) and _era_timer.wait_time > 0.0 else era_transition_time
		return clampf(1.0 - (mock_time_left / wt), 0.0, 1.0)
	if is_instance_valid(_era_timer) and not _era_timer.is_stopped() and _era_timer.wait_time > 0.0:
		return clampf(1.0 - (_era_timer.time_left / _era_timer.wait_time), 0.0, 1.0)
	return 0.0

func _process(delta: float) -> void:
	# ── Progreso de la evolución de era ────────────────────────────────────────
	if (evolucionando or esta_evolucionando):
		var tiene_timer_activo: bool = is_instance_valid(_era_timer) and not _era_timer.is_stopped() and _era_timer.wait_time > 0.0
		if tiene_timer_activo or mock_time_left >= 0.0:
			var wt: float = _era_timer.wait_time if is_instance_valid(_era_timer) and _era_timer.wait_time > 0.0 else era_transition_time
			var tl: float = mock_time_left if mock_time_left >= 0.0 else _era_timer.time_left
			var porcentaje: int = int((1.0 - (tl / wt)) * 100)
			var progreso: float = clampf(1.0 - (tl / wt), 0.0, 1.0)
			_era_elapsed += delta
			era_progreso_actualizado.emit(progreso, _era_destino_nombre)
			var rm: Node = _get_resource_manager()
			if is_instance_valid(rm) and rm.has_signal("evolucion_en_progreso"):
				rm.evolucion_en_progreso.emit(maxf(0.0, tl), _era_destino_nombre)

			# Actualizar el Label3D flotante sobre el Capitolio
			var era_lbl: Label3D = get_node_or_null("EraProgressLabel3D") as Label3D
			if is_instance_valid(era_lbl):
				era_lbl.text = "⏳ Evolucionando... (%d%%)\n%s" % [porcentaje, _era_destino_nombre]

			# Inyectar directamente al panel de la UI del cliente local
			var act_panel: Node = null
			if is_inside_tree() and get_tree() and get_tree().current_scene:
				act_panel = get_tree().current_scene.find_child("ActionPanel", true, false)
			if not is_instance_valid(act_panel) and is_inside_tree() and get_tree():
				act_panel = get_tree().get_first_node_in_group("rts_action_panel")
			if is_instance_valid(act_panel) and act_panel.has_method("actualizar_progreso_era"):
				act_panel.call("actualizar_progreso_era", self, porcentaje, progreso)

	# ── Producción de unidades (bloqueada durante evolución de era) ─────────────
	if is_under_construction or is_dead or production_queue.is_empty() or esta_evolucionando:
		current_train_timer = 0.0
		return

	var current_order: Dictionary = production_queue[0]
	var total_time: float = float(current_order.get("train_time", villager_train_time))

	current_train_timer += delta
	var progress := clampf(current_train_timer / total_time, 0.0, 1.0)
	queue_progress_updated.emit(progress, String(current_order.get("unit_type", "villager")))

	if current_train_timer >= total_time:
		current_train_timer = 0.0
		var completed_order: Dictionary = production_queue.pop_front()
		_spawn_unit(completed_order)

# ─── Manejo de Clics y Actualización de Rally Point ────────────────────────────

# (Manejo de Rally Point y Bandera ahora heredados directamente de BuildingBase3D)

# ─── Instanciación y Despacho Inteligente en el Spawn ──────────────────────────

func _spawn_unit(order: Dictionary) -> void:
	var pscene: PackedScene = order.get("scene", null) as PackedScene
	if pscene == null:
		pscene = load("res://scenes/units/villager_3d.tscn") as PackedScene

	var spawn_pos := global_position + spawn_offset
	var spawn_marker := get_node_or_null("SpawnPoint") as Node3D
	if is_instance_valid(spawn_marker):
		spawn_pos = spawn_marker.global_position

	var unit_inst: Node3D = null
	if is_instance_valid(pscene):
		unit_inst = pscene.instantiate() as Node3D
	else:
		var vil := Villager3D.new()
		vil.name = "Villager3D"
		unit_inst = vil

	var units_parent: Node = null
	if get_tree() and get_tree().current_scene:
		units_parent = get_tree().current_scene.get_node_or_null("World/Units")
		if not units_parent:
			units_parent = get_tree().current_scene.get_node_or_null("Units")
		if not units_parent:
			units_parent = get_tree().current_scene
	if not units_parent:
		units_parent = get_parent()

	# Añadir al árbol de nodos primero
	units_parent.add_child(unit_inst)
	unit_inst.global_position = spawn_pos

	unit_inst.add_to_group("unidades")
	unit_inst.add_to_group("units")
	unit_inst.add_to_group("units_3d")

	# DESPACHO INTELIGENTE INMEDIATO (Mismo Frame)
	_dispatch_newborn_unit(unit_inst)

	unit_spawned.emit(unit_inst)

var _spawn_counter: int = 0

func _dispatch_newborn_unit(unit_inst: Node3D) -> void:
	var is_villager := unit_inst is Villager3D or unit_inst.has_method("command_gather")

	# a) Si hay un recurso válido asignado como Rally Target y la unidad es ALDEANO
	if is_villager and is_instance_valid(rally_target_node) and (rally_target_node is ResourceNode3D or rally_target_node.is_in_group("resources")):
		if unit_inst.has_method("command_gather"):
			unit_inst.command_gather(rally_target_node)
		elif "state_machine" in unit_inst and unit_inst.state_machine:
			unit_inst.state_machine.change_state(&"Gathering", {"target_node": rally_target_node})
		return

	# b) Si hay bandera de destino explícita colocada por el jugador
	if rally_point_set and rally_point != Vector3.ZERO:
		if unit_inst.has_method("command_move"):
			unit_inst.command_move(rally_point)
		elif "state_machine" in unit_inst and unit_inst.state_machine:
			unit_inst.state_machine.change_state(&"Move", {"target_position": rally_point})
		return

	# c) Si NO se seleccionó bandera, dispersar en anillo alrededor del Capitolio
	var spawn_radius := 6.2
	var angle := float(_spawn_counter % 8) * (TAU / 8.0)
	var ring := floorf(float(_spawn_counter) / 8.0) * 1.8
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * (spawn_radius + ring)
	_spawn_counter += 1
	var target_p := global_position + offset
	if unit_inst.has_method("command_move"):
		unit_inst.command_move(target_p)
	elif "state_machine" in unit_inst and unit_inst.state_machine:
		unit_inst.state_machine.change_state(&"Move", {"target_position": target_p})

# ─── Cola de Producción ────────────────────────────────────────────────────────

func train_villager() -> void:
	crear_aldeano()

func get_training_progress() -> float:
	if production_queue.is_empty():
		return 0.0
	var total: float = float(production_queue[0].get("train_time", villager_train_time))
	return clampf(current_train_timer / total, 0.0, 1.0) if total > 0.0 else 0.0

func get_queue_count() -> int:
	return production_queue.size()

func crear_aldeano() -> void:
	if is_under_construction or is_dead:
		push_warning("TownCenter3D '%s': No se pueden entrenar unidades mientras está en construcción o destruido." % name)
		return

	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm) and rm.has_method("has_population_room") and not rm.has_population_room(1):
		push_warning("TownCenter3D: Límite de población alcanzado.")
		return

	var success := false
	if is_instance_valid(rm):
		if rm.has_method("gastar_recursos"):
			success = rm.gastar_recursos(villager_cost)
		elif rm.has_method("spend_resources"):
			success = rm.spend_resources(villager_cost)
			
	if not success:
		print("TownCenter3D: Recursos insuficientes.")
		return

	var order: Dictionary = {
		"unit_type": "villager",
		"train_time": villager_train_time,
		"scene": villager_scene
	}
	production_queue.append(order)
	unit_queued.emit("villager", production_queue.size())

# ─── API de Depósito de Recursos ───────────────────────────────────────────────

func deposit_resources(resource_type: String, amount: int, villager: Node3D = null) -> void:
	# No aceptar recursos mientras el edificio está en construcción, muerto o la carga es inválida
	if is_dead or is_under_construction or amount <= 0 or resource_type.is_empty():
		return

	if bando == Bando.PLAYER:
		var rm: Node = _get_resource_manager()
		if is_instance_valid(rm):
			if rm.has_method("agregar_recursos"):
				rm.agregar_recursos({resource_type: amount})
			elif rm.has_method("add_resources"):
				rm.add_resources(resource_type, amount)
			elif "resources" in rm and rm.resources is Dictionary:
				rm.resources[resource_type] = int(rm.resources.get(resource_type, 0)) + amount
	else:
		var tree_inst: SceneTree = get_tree() if is_inside_tree() else null
		if not tree_inst:
			var ml := Engine.get_main_loop()
			if ml is SceneTree:
				tree_inst = ml as SceneTree
		var enemy_ais := tree_inst.get_nodes_in_group("enemy_ai") if is_instance_valid(tree_inst) else []
		for ai in enemy_ais:
			if is_instance_valid(ai) and ai.has_method("agregar_recursos_ia"):
				ai.agregar_recursos_ia({resource_type: amount})

	resource_deposited.emit(resource_type, amount, villager)

# ─── Sistema de Evolución por Eras ────────────────────────────────────────────

## Inicia el proceso de evolución a la siguiente era histórica.
##
## Flujo:
##   1. Verifica que el edificio esté operativo y ResourceManager disponible.
##   2. Comprueba que no haya otra evolución en curso (bloqueo global en ResourceManager).
##   3. Verifica que el jugador tenga los recursos requeridos y los descuenta.
##   4. Inicia el Timer de [era_transition_time] segundos (por defecto 15s).
##   5. Al expirar el timer, llama a ResourceManager._aplicar_nueva_era() y emite la señal.
func iniciar_evolucion_era() -> void:
	# Guard: El edificio debe estar construido y vivo
	if is_under_construction or is_dead:
		push_warning("TownCenter3D: No se puede evolucionar mientras está en construcción o destruido.")
		era_evolucion_cancelada.emit("edificio_no_operativo")
		return

	# Guard: ResourceManager disponible
	var rm: Node = _get_resource_manager()
	if not is_instance_valid(rm):
		push_error("TownCenter3D: ResourceManager no disponible.")
		era_evolucion_cancelada.emit("resource_manager_no_encontrado")
		return

	# Guard: No evolucionar si ya hay una transición activa
	var esta_ev: bool = ("evolucionando" in rm and rm.evolucionando) or esta_evolucionando
	if esta_ev:
		push_warning("TownCenter3D: Ya hay una evolución de era en curso.")
		era_evolucion_cancelada.emit("evolucion_ya_en_curso")
		return

	# Guard: Verificar que no estemos en la era máxima
	if rm.has_method("puede_evolucionar") and not rm.puede_evolucionar():
		var motivo: String = "era_maxima_alcanzada" if ("era_actual" in rm and int(rm.era_actual) >= 2) else "fondos_insuficientes"
		push_warning("TownCenter3D: No se puede evolucionar — %s." % motivo)
		era_evolucion_cancelada.emit(motivo)
		return

	# Obtener coste y era de destino
	var costo: Dictionary = {}
	if rm.has_method("consulta_coste_era"):
		costo = rm.consulta_coste_era()
	var era_siguiente: int = (int(rm.era_actual) if "era_actual" in rm else 0) + 1
	_era_destino_valor = era_siguiente
	_era_destino_nombre = NOMBRES_ERA_TC.get(era_siguiente, "Era Desconocida") as String

	# Usar el tiempo de construccion real de Empire Earth (dbupgrade.dat)
	var build_time: float = float(ERA_BUILD_TIMES_SECONDS.get(era_siguiente - 1, 125.0))
	era_transition_time = build_time

	# Descontar recursos
	var exito: bool = false
	if rm.has_method("gastar_recursos"):
		exito = rm.gastar_recursos(costo)
	if not exito:
		push_warning("TownCenter3D: Recursos insuficientes para evolucionar a %s." % _era_destino_nombre)
		era_evolucion_cancelada.emit("fondos_insuficientes")
		return

	# Bloquear nuevas evoluciones concurrentes
	if "evolucionando" in rm:
		rm.evolucionando = true
	esta_evolucionando = true
	_era_elapsed = 0.0

	# Iniciar el temporizador de transición
	_ensure_era_timer()
	if is_instance_valid(_era_timer):
		_era_timer.wait_time = era_transition_time
		_era_timer.start()

	print("TownCenter3D: ¡Evolución iniciada! → %s (en %.0f segundos)" % [
		_era_destino_nombre, era_transition_time
	])
	# Mostrar UI de progreso sobre el Capitolio
	_mostrar_ui_progreso_era(_era_destino_nombre)

## Cancela la evolución en curso y devuelve los recursos gastados al jugador.
func cancelar_evolucion_era() -> void:
	if not esta_evolucionando:
		return

	if is_instance_valid(_era_timer) and not _era_timer.is_stopped():
		_era_timer.stop()

	esta_evolucionando = false
	_era_elapsed = 0.0

	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm):
		if "evolucionando" in rm:
			rm.evolucionando = false
		# Devolver los recursos que se gastaron
		if rm.has_method("consulta_coste_era") and rm.has_method("add_resources"):
			var costo: Dictionary = rm.consulta_coste_era()
			for res: String in costo:
				rm.add_resources(res, int(costo[res]))

	era_evolucion_cancelada.emit("cancelado_por_jugador")
	print("TownCenter3D: Evolución cancelada. Recursos devueltos.")

## Callback del Timer: aplica la nueva era al sistema global y la difunde por red.
func _on_era_timer_timeout() -> void:
	esta_evolucionando = false
	_era_elapsed = era_transition_time

	# Emitir progreso al 100% antes de aplicar
	era_progreso_actualizado.emit(1.0, _era_destino_nombre)

	var target_era: int = _era_destino_valor
	_era_destino_nombre = ""
	_era_destino_valor  = -1

	var target_peer: int = owner_peer_id
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		target_peer = multiplayer.get_unique_id()

	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm) and rm.has_method("notificar_avance_era"):
		rm.notificar_avance_era(target_peer, target_era)
	else:
		_aplicar_evolucion_era_local(target_era)

@rpc("any_peer", "call_local", "reliable")
func rpc_notificar_avance_era(target_player_id: int, era_destino: int) -> void:
	if owner_peer_id == target_player_id:
		_actualizar_modelo_visual_era(era_destino)
	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm) and rm.has_method("rpc_notificar_avance_era"):
		rm.rpc_notificar_avance_era(target_player_id, era_destino)

@rpc("any_peer", "call_local", "reliable")
func rpc_difundir_era_evolucionada(nueva_era_idx: int) -> void:
	var target_peer: int = owner_peer_id
	rpc_notificar_avance_era(target_peer, nueva_era_idx)

func _aplicar_evolucion_era_local(nueva_era_idx: int) -> void:
	var target_peer: int = owner_peer_id
	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm) and rm.has_method("notificar_avance_era"):
		rm.notificar_avance_era(target_peer, nueva_era_idx)
	else:
		_actualizar_modelo_visual_era(nueva_era_idx)
	print("TownCenter3D '%s': ✅ Era evolucionada aplicada localmente y en red (Era %d)" % [name, nueva_era_idx])
	# Mostrar texto de era completada
	_mostrar_ui_era_completada(NOMBRES_ERA_TC.get(nueva_era_idx, "Era %d" % nueva_era_idx))

# ─── UI de Avance de Era ────────────────────────────────────────────────────────────

## Muestra un Label3D flotante sobre el Capitolio indicando la era hacia la que avanza.
## La barra de progreso real se emite a través de la señal era_progreso_actualizado al HUD 2D.
func _mostrar_ui_progreso_era(era_nombre: String) -> void:
	# Mostrar/actualizar el Label3D de avance de era sobre el edificio
	var label: Label3D = get_node_or_null("EraProgressLabel3D") as Label3D
	if not is_instance_valid(label):
		label = Label3D.new()
		label.name = "EraProgressLabel3D"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 28
		label.modulate = Color(1.0, 0.85, 0.1, 1.0)  # Amarillo dórado
		label.position = Vector3(0.0, 5.5, 0.0)  # Flotando sobre el edificio
		add_child(label)
	label.text = "⏳ Avanzando a:\n" + era_nombre
	label.visible = true

	# Emitir sonido de inicio de era (si SoundManager lo soporta)
	var sm: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("era_advance_start")

	print("TownCenter3D '%s': ⏳ UI de avance de era mostrada → '%s'" % [name, era_nombre])

## Muestra el texto de "¡[Era] alcanzada!" y oculta el label de progreso.
func _mostrar_ui_era_completada(era_nombre: String) -> void:
	# Actualizar Label3D con el anuncio final
	var label: Label3D = get_node_or_null("EraProgressLabel3D") as Label3D
	if not is_instance_valid(label):
		label = Label3D.new()
		label.name = "EraProgressLabel3D"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 32
		label.position = Vector3(0.0, 5.5, 0.0)
		add_child(label)
	label.text = "⭐ ¡" + era_nombre + " alcanzada!"
	label.modulate = Color(0.2, 1.0, 0.4, 1.0)  # Verde celebratorio
	label.visible = true

	# Emitir sonido de era completada
	var sm: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("era_evolution")

	# Ocultar el label después de 5 segundos
	var hide_timer := Timer.new()
	hide_timer.wait_time = 5.0
	hide_timer.one_shot = true
	add_child(hide_timer)
	hide_timer.timeout.connect(func() -> void:
		if is_instance_valid(label):
			label.visible = false
		if is_instance_valid(hide_timer):
			hide_timer.queue_free()
	)
	hide_timer.start()

	# Anuncio en el chat de red
	var ncm: Node = get_node_or_null("/root/NetworkChatManager")
	if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
		ncm.call("enviar_mensaje_local", "⭐ ¡" + era_nombre + " alcanzada!")

	print("TownCenter3D '%s': ✅ ¡Era completada! Texto de celebración mostrado: '%s'" % [name, era_nombre])

## Conmutador de malla y estética histórica para el Capitolio / Centro Urbano
func _actualizar_modelo_visual_era(era_val: int) -> void:
	super._actualizar_modelo_visual_era(era_val)

	match era_val:
		0, 1, 2:
			building_name = "Choza Comunal Primitiva"
		3, 4, 5:
			building_name = "Foro de Mármol y Capitolio Clásico"
		6, 7:
			building_name = "Palacio de Gobierno Industrial"
		8, 9:
			building_name = "Centro de Mando Nano-Cibernético"

	var cap_prehistoria := get_node_or_null("CapitolioPrehistorico") as Node3D
	if is_instance_valid(cap_prehistoria):
		cap_prehistoria.visible = (era_val <= 2)

	var base_mesh := get_node_or_null("BaseMesh") as MeshInstance3D
	var roof_mesh := get_node_or_null("RoofMesh") as MeshInstance3D
	var campfire := get_node_or_null("Campfire") as Node3D
	var fire_light := get_node_or_null("FireLight") as OmniLight3D

	var is_ally: bool = (bando == Bando.PLAYER)

	# La fogata primitiva solo se muestra en épocas primitivas (0 a 2)
	if is_instance_valid(campfire):
		campfire.visible = (era_val <= 2)
	if is_instance_valid(fire_light):
		fire_light.visible = (era_val <= 2)

	if is_instance_valid(base_mesh):
		var mat_base := StandardMaterial3D.new()
		match era_val:
			0, 1, 2: # Primitivo: barro y madera
				mat_base.albedo_color = Color(0.65, 0.58, 0.48) if is_ally else Color(0.70, 0.45, 0.40)
				mat_base.roughness = 0.90
			3, 4, 5: # Clásico / Medieval: Mármol blanco y sillar de piedra
				mat_base.albedo_color = Color(0.88, 0.88, 0.84) if is_ally else Color(0.80, 0.65, 0.65)
				mat_base.roughness = 0.40
				mat_base.metallic = 0.10
			6, 7: # Industrial: Ladrillo rojo oscuro / hormigón y granito
				mat_base.albedo_color = Color(0.45, 0.38, 0.35) if is_ally else Color(0.55, 0.30, 0.30)
				mat_base.roughness = 0.60
				mat_base.metallic = 0.35
			8, 9: # Futurista: Compuesto cerámico blanco y titanio
				mat_base.albedo_color = Color(0.92, 0.95, 1.0) if is_ally else Color(0.95, 0.60, 0.60)
				mat_base.roughness = 0.15
				mat_base.metallic = 0.90
				mat_base.emission_enabled = true
				mat_base.emission = Color(0.0, 0.7, 1.0) if is_ally else Color(1.0, 0.3, 0.0)
				mat_base.emission_energy_multiplier = 0.5
		base_mesh.material_override = mat_base

	if is_instance_valid(roof_mesh):
		var mat_roof := StandardMaterial3D.new()
		match era_val:
			0, 1, 2: # Techo de paja / arcilla roja
				mat_roof.albedo_color = Color(0.68, 0.28, 0.22) if is_ally else Color(0.60, 0.20, 0.18)
				mat_roof.roughness = 0.85
			3, 4, 5: # Techo de teja romana de terracota brillante / cobre oxidado
				mat_roof.albedo_color = Color(0.78, 0.35, 0.20) if is_ally else Color(0.70, 0.25, 0.20)
				mat_roof.roughness = 0.50
				mat_roof.metallic = 0.20
			6, 7: # Cubierta de chapa de zinc / pizarra gris pizarra
				mat_roof.albedo_color = Color(0.28, 0.32, 0.36) if is_ally else Color(0.40, 0.25, 0.25)
				mat_roof.roughness = 0.40
				mat_roof.metallic = 0.60
			8, 9: # Cúpula de cristal fotovoltaico y plasma azulado
				mat_roof.albedo_color = Color(0.15, 0.65, 0.95, 0.85) if is_ally else Color(0.95, 0.20, 0.10, 0.85)
				mat_roof.roughness = 0.10
				mat_roof.metallic = 0.80
				mat_roof.emission_enabled = true
				mat_roof.emission = Color(0.1, 0.8, 1.0) if is_ally else Color(1.0, 0.2, 0.0)
				mat_roof.emission_energy_multiplier = 0.9
		roof_mesh.material_override = mat_roof

	var lbl: Label3D = get_node_or_null("BuildingNameLabel3D") as Label3D
	if is_instance_valid(lbl):
		lbl.text = "[Era %d] %s" % [era_val, building_name]

# ─── Sistema de Guarnición y Campana Urbana (Garrison & Town Bell) ───────────
var garrisoned_units: Array[Node3D] = []
@export var max_garrison_capacity: int = 15
var town_bell_active: bool = false

signal town_bell_rang(active: bool)

## Añade una unidad a la guarnición defensiva del edificio.
func add_garrison_unit(unit: Node3D) -> bool:
	if garrisoned_units.size() >= max_garrison_capacity:
		return false
	if not garrisoned_units.has(unit):
		garrisoned_units.append(unit)
		_update_defensive_stats()
		return true
	return false

## Libera una unidad de la guarnición.
func remove_garrison_unit(unit: Node3D) -> void:
	if garrisoned_units.has(unit):
		garrisoned_units.erase(unit)
		_update_defensive_stats()

## Desaloja a todos los aldeanos guarecidos y les ordena volver a sus tareas previas.
func expulsar_guarnicion() -> void:
	var units_to_ungarrison := garrisoned_units.duplicate()
	garrisoned_units.clear()
	for u in units_to_ungarrison:
		if is_instance_valid(u):
			if u.has_method("regresar_al_trabajo"):
				u.call("regresar_al_trabajo")
			elif "visible" in u:
				u.visible = true
	_update_defensive_stats()

## Activa o desactiva la alarma de la Campana Urbana en un radio de 80 metros.
func tocar_campana_urbana(activar: bool) -> void:
	town_bell_active = activar
	town_bell_rang.emit(town_bell_active)

	var snd: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(snd):
		if snd.get("instance") != null and snd.instance.has_method("play_attack_alert"):
			snd.instance.play_attack_alert()
		elif snd.has_method("play_attack_alert"):
			snd.play_attack_alert()

	var aldeanos := get_tree().get_nodes_in_group("player_units")
	for u in aldeanos:
		if is_instance_valid(u) and (u is Villager3D or u.has_method("guarecer_en")):
			var dist := global_position.distance_to((u as Node3D).global_position)
			if dist <= 80.0:
				if town_bell_active:
					u.call("guarecer_en", self)
				else:
					u.call("regresar_al_trabajo")

## Calcula el ataque defensivo del edificio (+1 proyectil y +5 daño por cada aldeano adentro).
func _update_defensive_stats() -> void:
	var extra_damage: float = float(garrisoned_units.size()) * 5.0
	var total_projectiles: int = 1 + garrisoned_units.size()
	print("TownCenter3D '%s': Guarnición %d/%d | Proyectiles: %d | Daño extra: +%.0f" % [
		name, garrisoned_units.size(), max_garrison_capacity, total_projectiles, extra_damage
	])
