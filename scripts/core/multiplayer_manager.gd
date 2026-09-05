## MultiplayerManager — Gestor Multijugador Híbrido LAN/IP con Slots de Bots IA (GDScript 2.0 / Godot 4).
##
## Administra la infraestructura de red ENetMultiplayerPeer en Godot 4.3 para hasta 8 slots:
## - Slots Mixtos: "human" (Peer ID), "bot" (IA Skirmish) y "open" (Libre).
## - Autoridad Exclusiva de IA en Servidor: El Host (ID 1) simula los RTSEnemyAI para evitar duplicación.
## - Replicación de Spawns con MultiplayerSpawner.
## - Transmisión de Órdenes RTS mediante RPCs fiables.

extends Node

signal peer_connected_to_lobby(id: int)
signal peer_disconnected_from_lobby(id: int)
signal lobby_slots_updated()
signal connection_succeeded()
signal connection_failed_event()
signal server_disconnected_event()

const DEFAULT_PORT: int = 4242
const MAX_SLOTS: int = 8

enum SlotType { OPEN, HUMAN, BOT, CLOSED }

var enet_peer: ENetMultiplayerPeer = null
var is_host: bool = false

# ─── Array de 8 Slots Híbridos y Matriz Diplomática ───────────────────────────
var lobby_slots: Array[Dictionary] = []
var alliances_matrix: Dictionary = {}

signal diplomatic_status_changed(peer_a: int, peer_b: int, new_status: String)

# ─── Instancia Autoload / Acceso Global ─────────────────────────────────────────
static var instance: MultiplayerManager = null

func _ready() -> void:
	instance = self
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("multiplayer_manager")

	_init_default_slots()
	_connect_native_multiplayer_signals()

func _init_default_slots() -> void:
	lobby_slots.clear()
	for i in range(MAX_SLOTS):
		lobby_slots.append({
			"slot_index": i,
			"type": SlotType.OPEN,
			"status": "OPEN",
			"peer_id": 0,
			"name": "Slot %d (Libre)" % (i + 1),
			"bando": i % 2, # Alternar equipos por defecto (0: Player/Aliado, 1: Enemigo)
			"ai_difficulty": "normal"
		})

func _connect_native_multiplayer_signals() -> void:
	var mp: MultiplayerAPI = get_multiplayer() if is_inside_tree() else null
	if mp == null:
		return
	if not mp.peer_connected.is_connected(_on_peer_connected):
		mp.peer_connected.connect(_on_peer_connected)
	if not mp.peer_disconnected.is_connected(_on_peer_disconnected):
		mp.peer_disconnected.connect(_on_peer_disconnected)
	if not mp.connected_to_server.is_connected(_on_connected_to_server):
		mp.connected_to_server.connect(_on_connected_to_server)
	if not mp.connection_failed.is_connected(_on_connection_failed):
		mp.connection_failed.connect(_on_connection_failed)
	if not mp.server_disconnected.is_connected(_on_server_disconnected):
		mp.server_disconnected.connect(_on_server_disconnected)

# ─── API de Conexión y Servidor ENet ──────────────────────────────────────────

func crear_servidor(puerto: int = DEFAULT_PORT) -> Error:
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_server(puerto, MAX_SLOTS)
	if err != OK:
		push_error("MultiplayerManager: Error al crear servidor en puerto %d." % puerto)
		return err

	var mp: MultiplayerAPI = get_multiplayer() if is_inside_tree() else null
	if mp != null:
		mp.multiplayer_peer = enet_peer
	is_host = true

	var my_id: int = mp.get_unique_id() if mp != null else 1
	_init_default_slots()

	# Asignar Host al Slot 0
	lobby_slots[0]["type"] = SlotType.HUMAN
	lobby_slots[0]["status"] = "HUMANO"
	lobby_slots[0]["peer_id"] = my_id
	lobby_slots[0]["name"] = "Host (Jugador 1)"
	lobby_slots[0]["bando"] = 0

	# Asignar un Bot IA por defecto en Slot 1 para escaramuza
	lobby_slots[1]["type"] = SlotType.BOT
	lobby_slots[1]["status"] = "BOT_IA"
	lobby_slots[1]["name"] = "Bot IA (Normal)"
	lobby_slots[1]["bando"] = 1

	print("MultiplayerManager: Servidor Host ENet (8 Slots) creado en puerto %d." % puerto)
	lobby_slots_updated.emit()
	return OK

func unirse_a_servidor(ip: String = "127.0.0.1", puerto: int = DEFAULT_PORT) -> Error:
	enet_peer = ENetMultiplayerPeer.new()
	var err := enet_peer.create_client(ip, puerto)
	if err != OK:
		return err

	var mp: MultiplayerAPI = get_multiplayer() if is_inside_tree() else null
	if mp != null:
		mp.multiplayer_peer = enet_peer
	is_host = false
	print("MultiplayerManager: Conectando cliente a %s:%d..." % [ip, puerto])
	return OK

func cerrar_conexion() -> void:
	if is_instance_valid(enet_peer):
		enet_peer.close()
		enet_peer = null
	var mp: MultiplayerAPI = get_multiplayer() if is_inside_tree() else null
	if mp != null and mp.has_multiplayer_peer():
		mp.multiplayer_peer = null
	_init_default_slots()
	is_host = false

# ─── Gestión Híbrida de Slots (Host Controls) ─────────────────────────────────

func toggle_slot_type(slot_index: int) -> void:
	if not is_host or slot_index <= 0 or slot_index >= MAX_SLOTS:
		return

	var current_type: int = lobby_slots[slot_index]["type"]
	match current_type:
		SlotType.OPEN:
			lobby_slots[slot_index]["type"] = SlotType.BOT
			lobby_slots[slot_index]["status"] = "BOT_IA"
			lobby_slots[slot_index]["peer_id"] = 0
			lobby_slots[slot_index]["name"] = "Bot IA (%d)" % (slot_index + 1)
			lobby_slots[slot_index]["bando"] = 1
		SlotType.BOT:
			lobby_slots[slot_index]["type"] = SlotType.CLOSED
			lobby_slots[slot_index]["status"] = "CERRADO"
			lobby_slots[slot_index]["name"] = "Slot %d (Cerrado)" % (slot_index + 1)
		_:
			lobby_slots[slot_index]["type"] = SlotType.OPEN
			lobby_slots[slot_index]["status"] = "OPEN"
			lobby_slots[slot_index]["peer_id"] = 0
			lobby_slots[slot_index]["name"] = "Slot %d (Libre)" % (slot_index + 1)

	# Sincronizar tabla de slots con los clientes
	rpc("rpc_sincronizar_slots", lobby_slots)
	lobby_slots_updated.emit()

# ─── Callbacks Nativos de Red Godot 4 ─────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	print("MultiplayerManager: Peer conectado -> ID %d" % id)
	if is_host:
		# Asignar el nuevo jugador humano en la primera ranura libre
		for idx in range(1, MAX_SLOTS):
			if lobby_slots[idx]["type"] == SlotType.OPEN or lobby_slots[idx]["type"] == SlotType.CLOSED:
				lobby_slots[idx]["type"] = SlotType.HUMAN
				lobby_slots[idx]["status"] = "HUMANO"
				lobby_slots[idx]["peer_id"] = id
				lobby_slots[idx]["name"] = "Jugador_%d" % id
				lobby_slots[idx]["bando"] = 1
				break
		rpc("rpc_sincronizar_slots", lobby_slots)
		lobby_slots_updated.emit()
	peer_connected_to_lobby.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("MultiplayerManager: Peer desconectado -> ID %d" % id)
	if is_host:
		for idx in range(MAX_SLOTS):
			if lobby_slots[idx]["peer_id"] == id:
				lobby_slots[idx]["type"] = SlotType.OPEN
				lobby_slots[idx]["status"] = "OPEN"
				lobby_slots[idx]["peer_id"] = 0
				lobby_slots[idx]["name"] = "Slot %d (Libre)" % (idx + 1)
		rpc("rpc_sincronizar_slots", lobby_slots)
		lobby_slots_updated.emit()
	peer_disconnected_from_lobby.emit(id)

func _on_connected_to_server() -> void:
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	cerrar_conexion()
	connection_failed_event.emit()

func _on_server_disconnected() -> void:
	cerrar_conexion()
	server_disconnected_event.emit()

# ─── RPCs de Sincronización y Arranque Híbrido ────────────────────────────────

@rpc("authority", "call_local", "reliable")
func rpc_sincronizar_slots(slots_data: Array) -> void:
	lobby_slots.clear()
	for s in slots_data:
		if s is Dictionary:
			lobby_slots.append((s as Dictionary).duplicate(true))
	lobby_slots_updated.emit()

## RPC fiable que sincroniza los parámetros de GameSettings a TODOS los peers
## antes de cargar el mapa, garantizando que todos arranquen en la misma Era.
@rpc("any_peer", "call_local", "reliable")
func rpc_establecer_configuracion_partida(config_data: Dictionary) -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(gs):
		var t := get_tree()
		if is_instance_valid(t) and is_instance_valid(t.root):
			gs = t.root.get_node_or_null("GameSettings")
	if not is_instance_valid(gs):
		var gs_script = load("res://scripts/core/game_settings.gd")
		if is_instance_valid(gs_script) and "instance" in gs_script and is_instance_valid(gs_script.instance):
			gs = gs_script.instance
	if is_instance_valid(gs):
		for key in config_data:
			if key in gs:
				gs.set(key, config_data[key])
	
	if config_data.has("game_speed_modifier"):
		var spd_mod: float = float(config_data.get("game_speed_modifier", 1.0))
		Engine.time_scale = maxf(0.1, spd_mod)

	# Propagar era al ResourceManager local para que los HUDs de cada cliente reflejen la era correcta
	var era: int = config_data.get("starting_era", 0)
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("_aplicar_nueva_era"):
		rm.call("_aplicar_nueva_era", era)
	print("MultiplayerManager: ✅ Configuración de partida recibida y aplicada.")

@rpc("authority", "call_local", "reliable")
func rpc_cargar_mapa_multijugador() -> void:
	print("MultiplayerManager: Cargando mapa multijugador sincrónicamente...")
	var err := get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
	if err == OK:
		_esperar_y_configurar_escena_multijugador()

func _esperar_y_configurar_escena_multijugador() -> void:
	var retries := 0
	while is_instance_valid(get_tree()) and (get_tree().current_scene == null or get_tree().current_scene.name != "Main3D") and retries < 60:
		await get_tree().process_frame
		retries += 1
	_setup_multiplayer_spawners_and_ai()

func iniciar_partida_hibrida() -> void:
	if not is_host:
		return
	# ── Paso 1: Transmitir configuración a TODOS los peers ANTES de cargar el mapa ──
	var gs: Node = get_node_or_null("/root/GameSettings")
	if is_instance_valid(gs):
		var config_data: Dictionary = {
			"starting_era": gs.get("starting_era") if "starting_era" in gs else 0,
			"game_speed": gs.get("game_speed") if "game_speed" in gs else 1.0,
			"game_speed_modifier": gs.get("game_speed_modifier") if "game_speed_modifier" in gs else 1.0,
			"starting_villagers": gs.get("starting_villagers") if "starting_villagers" in gs else 5,
			"ai_difficulty": gs.get("ai_difficulty") if "ai_difficulty" in gs else "normal",
			"slot_colors": gs.get("slot_colors") if "slot_colors" in gs else [],
			"slot_teams": gs.get("slot_teams") if "slot_teams" in gs else [],
			"max_population_limit": gs.get("max_population_limit") if "max_population_limit" in gs else 200,
			"starting_resources": gs.get("starting_resources") if "starting_resources" in gs else "normal",
			"map_seed": gs.get("map_seed") if "map_seed" in gs else 0,
			"map_size_preset": gs.get("map_size_preset") if "map_size_preset" in gs else 1,
			"map_biome": gs.get("map_biome") if "map_biome" in gs else 0,
			"map_type": gs.get("map_type") if "map_type" in gs else "aleatorio",
			"show_map": gs.get("show_map") if "show_map" in gs else false,
			"custom_civ": gs.get("custom_civ") if "custom_civ" in gs else true,
			"lock_teams": gs.get("lock_teams") if "lock_teams" in gs else true,
			"cheat_codes": gs.get("cheat_codes") if "cheat_codes" in gs else false
		}
		rpc("rpc_establecer_configuracion_partida", config_data)
	# ── Paso 2: Ordenar la carga del mapa a todos los peers ──
	rpc("rpc_cargar_mapa_multijugador")

# ─── Continuación de Partidas Guardadas Multijugador ──────────────────────────

func cargar_partida_guardada_en_lobby(slot_name: String = "quicksave.json") -> bool:
	if not is_host:
		return false

	var path := "user://saves/" + slot_name
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not is_instance_valid(file):
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var data: Dictionary = json.data as Dictionary
		if "multiplayer_lobby_state" in data and data["multiplayer_lobby_state"] is Array:
			lobby_slots = (data["multiplayer_lobby_state"] as Array).duplicate(true)
			rpc("rpc_sincronizar_slots", lobby_slots)
			lobby_slots_updated.emit()
			print("MultiplayerManager: slots recuperados del guardado JSON '%s'." % slot_name)
			return true

	return false

func continuar_partida_guardada_multijugador(slot_name: String = "quicksave.json") -> void:
	if not is_host:
		return
	rpc("rpc_continuar_partida_guardada_multijugador", slot_name)

@rpc("authority", "call_local", "reliable")
func rpc_continuar_partida_guardada_multijugador(slot_name: String) -> void:
	print("MultiplayerManager: Reanudando partida multijugador guardada '%s'..." % slot_name)
	var err := get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
	if err == OK:
		call_deferred("_apply_loaded_multiplayer_game", slot_name)

func _apply_loaded_multiplayer_game(slot_name: String) -> void:
	if multiplayer.is_server():
		var sm: Node = get_node_or_null("/root/SaveManager")
		if is_instance_valid(sm) and sm.has_method("cargar_partida"):
			sm.call("cargar_partida", slot_name)

		_setup_multiplayer_spawners_and_ai()
		_assign_network_authorities_to_restored_units()

func _assign_network_authorities_to_restored_units() -> void:
	if not multiplayer.is_server():
		return

	for u in get_tree().get_nodes_in_group("units_3d"):
		if is_instance_valid(u) and "bando" in u:
			var bando_val: int = int(u.get("bando"))
			for slot in lobby_slots:
				if int(slot.get("bando", 0)) == bando_val and int(slot.get("type", 0)) == SlotType.HUMAN:
					var target_peer := int(slot.get("peer_id", 1))
					u.set_multiplayer_authority(target_peer)
					break

# ─── Instanciación de Autoridad de IA en el Servidor ──────────────────────────

func _setup_multiplayer_spawners_and_ai() -> void:
	if not multiplayer.is_server():
		return # Únicamente el Servidor gestiona la instanciación de spawns e IAs

	print("MultiplayerManager: Servidor distribuyendo bases territoriales de forma separada...")

	# Bloque de seguridad reforzado contra punteros nulos
	var root: Node = null
	if get_tree() and is_instance_valid(get_tree().current_scene):
		root = get_tree().current_scene
	elif get_tree() and is_instance_valid(get_tree().root):
		if get_tree().root.get_child_count() > 0:
			root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
		else:
			root = get_tree().root

	if not is_instance_valid(root):
		push_error("MultiplayerManager: Error crítico — No se encontró escena/nodo raíz válido para instanciar partida.")
		return

	# 1. Limpiar nodos estáticos/placeholder de la escena inicial para evitar superposición en (0, 0, 0)
	var old_tcs := get_tree().get_nodes_in_group("town_centers") if get_tree() else []
	for old_tc in old_tcs:
		if is_instance_valid(old_tc) and old_tc is Node3D:
			if old_tc.get_parent():
				old_tc.get_parent().remove_child(old_tc)
			old_tc.queue_free()

	var old_ais := get_tree().get_nodes_in_group("enemy_ai") if get_tree() else []
	for old_ai in old_ais:
		if is_instance_valid(old_ai) and old_ai is Node3D:
			if old_ai.get_parent():
				old_ai.get_parent().remove_child(old_ai)
			old_ai.queue_free()

	var old_vils := get_tree().get_nodes_in_group("units_3d") if get_tree() else []
	for old_vil in old_vils:
		if is_instance_valid(old_vil) and old_vil is Node3D:
			if old_vil.get_parent():
				old_vil.get_parent().remove_child(old_vil)
			old_vil.queue_free()

	# Leer variables de configuración (FUENTE DE VERDAD ÚNICA)
	var gs: Node = get_node_or_null("/root/GameSettings")
	var era_inicial: int = int(gs.get("starting_era")) if (is_instance_valid(gs) and "starting_era" in gs) else 0
	var map_size_idx: int = int(gs.get("map_size_preset")) if (is_instance_valid(gs) and "map_size_preset" in gs) else 1
	var slot_colors_arr: Array = gs.get("slot_colors") if (is_instance_valid(gs) and "slot_colors" in gs) else []

	# Aplicar la era al ResourceManager del Servidor — establece multiplicadores y emite señal
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("_aplicar_nueva_era"):
		rm.call("_aplicar_nueva_era", era_inicial)

	# Bono industrial/futurista (Era >= 6)
	if era_inicial >= 6 and is_instance_valid(rm):
		var bono_base: int = 3000 if era_inicial >= 8 else 1500
		if rm.has_method("add_resources"):
			rm.call("add_resources", "gold", bono_base)
			rm.call("add_resources", "iron", bono_base)
		print("MultiplayerManager: Bono de Era Avanzada (Era %d) → +%d Oro +%d Hierro aplicados." % [era_inicial, bono_base, bono_base])

	# Buscar contenedores de edificios y unidades
	var bld_container: Node = root.get_node_or_null("World/Buildings")
	if not is_instance_valid(bld_container):
		bld_container = root

	var unit_container: Node = root.get_node_or_null("World/Units")
	if not is_instance_valid(unit_container):
		unit_container = root

	var villager_scene: PackedScene = load("res://scenes/units/villager_3d.tscn") as PackedScene

	# ── 1. Filtrar Ranuras Activas con Candado Estricto (SLOT BYPASS LOGIC) ──────
	var active_slot_indices: Array[int] = []
	for idx in range(lobby_slots.size()):
		var slot: Dictionary = lobby_slots[idx]
		var status_str: String = str(slot.get("status", "")).to_upper()
		var slot_type_val: int = int(slot.get("type", 0))

		# Comprobación condicional obligatoria (Slot Bypass):
		if status_str == "CERRADO" or status_str == "OPEN" or status_str == "CLOSED" or slot_type_val == SlotType.CLOSED or slot_type_val == SlotType.OPEN:
			continue

		# El Servidor SOLO calculará y spawneará si la ranura tiene estado explícito de "HUMANO" o "BOT_IA":
		var es_humano: bool = (status_str == "HUMANO" or status_str == "HUMAN" or slot_type_val == SlotType.HUMAN)
		var es_bot: bool = (status_str == "BOT_IA" or status_str == "BOT" or slot_type_val == SlotType.BOT)
		if es_humano or es_bot:
			active_slot_indices.append(idx)

	var total_active := active_slot_indices.size()
	if total_active == 0:
		# Salvaguarda: Slot 0 (Host Humano)
		active_slot_indices.append(0)
		total_active = 1

	# 2. Calcular posiciones de spawn circulares distribuidas ÚNICAMENTE para las ranuras activas
	var base_map_size: float = 300.0
	match map_size_idx:
		0: base_map_size = 150.0
		1: base_map_size = 300.0
		2: base_map_size = 600.0
		3: base_map_size = 1200.0
	
	var dist_centro: float = base_map_size * 0.38
	dist_centro = maxf(dist_centro, 85.0)

	var spawn_points: Array[Vector3] = []
	if total_active == 1:
		spawn_points.append(Vector3.ZERO)
	else:
		for i in range(total_active):
			var angulo: float = (float(i) * TAU) / float(total_active)
			spawn_points.append(Vector3(cos(angulo), 0.0, sin(angulo)) * dist_centro)

	for active_i in range(total_active):
		var slot_idx := active_slot_indices[active_i]
		var slot: Dictionary = lobby_slots[slot_idx]
		var status_str: String = str(slot.get("status", "")).to_upper()
		var slot_type_val: int = int(slot.get("type", 0))

		# Doble candado estricto por ranura:
		if status_str == "CERRADO" or status_str == "OPEN" or status_str == "CLOSED" or slot_type_val == SlotType.CLOSED or slot_type_val == SlotType.OPEN:
			continue

		var es_humano: bool = (status_str == "HUMANO" or status_str == "HUMAN" or slot_type_val == SlotType.HUMAN)
		var es_bot: bool = (status_str == "BOT_IA" or status_str == "BOT" or slot_type_val == SlotType.BOT)
		if not (es_humano or es_bot):
			continue

		var bando_val: int = int(slot.get("bando", 0 if es_humano else 1))
		var spawn_pos: Vector3 = spawn_points[active_i]

		# 3. Instanciar TownCenter3D exclusivo para la ranura activa e INYECTAR ERA
		var tc_scene := load("res://scenes/buildings/town_center_3d.tscn") as PackedScene
		var tc: TownCenter3D = tc_scene.instantiate() as TownCenter3D if tc_scene else TownCenter3D.new()
		tc.name = "TownCenter_Slot_%d" % slot_idx

		# Asignar posición ANTES de colgar del árbol para que _ready() lea la coordenada correcta
		tc.position = spawn_pos

		# ── Inyección de Era en TownCenter3D ──────────────────────────────────
		if "era_actual" in tc:
			tc.set("era_actual", era_inicial)
		if tc.has_method("_actualizar_modelo_visual_era"):
			tc.call("_actualizar_modelo_visual_era", era_inicial)

		if es_humano:
			var target_peer: int = int(slot.get("peer_id", 1))
			tc.set_multiplayer_authority(target_peer)
			tc.bando = BuildingBase3D.Bando.PLAYER
			tc.is_under_construction = false
			tc.esta_construido = true
			bld_container.add_child(tc)
			tc.global_position = spawn_pos

			# Instanciar 5 aldeanos humanos físicos estrictamente en su esquina
			if is_instance_valid(villager_scene):
				for v in range(5):
					var vil: Node = villager_scene.instantiate()
					if is_instance_valid(vil) and vil is Node3D:
						var vil3d := vil as Node3D
						vil3d.name = "Vil_H_%d_%d" % [slot_idx, v]
						var offset_v := Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
						vil3d.position = spawn_pos + offset_v
						if vil3d.has_method("set_multiplayer_authority"):
							vil3d.call("set_multiplayer_authority", target_peer)
						if "bando" in vil3d:
							vil3d.set("bando", bando_val)
						if slot_idx < slot_colors_arr.size() and "color_bando" in vil3d:
							vil3d.set("color_bando", slot_colors_arr[slot_idx])
						unit_container.add_child(vil3d)
						vil3d.global_position = spawn_pos + offset_v

			# Centrar la cámara RTS en la posición de inicio del jugador local
			if target_peer == 1 or target_peer == multiplayer.get_unique_id():
				var cam := get_tree().get_first_node_in_group("rts_camera") as Node3D
				if is_instance_valid(cam):
					cam.global_position = spawn_pos

			print("MultiplayerManager: Slot %d (Humano Peer %d) instanciado en %s (Era %d)" % [slot_idx, target_peer, str(spawn_pos), era_inicial])

		elif es_bot:
			tc.set_multiplayer_authority(1000 + slot_idx) # Autoridad no local de IA
			tc.bando = BuildingBase3D.Bando.ENEMY
			tc.is_under_construction = false
			tc.esta_construido = true
			bld_container.add_child(tc)
			tc.global_position = spawn_pos

			var ai := RTSEnemyAI.new()
			ai.name = "RTSEnemyAI_Slot_%d" % slot_idx
			ai.position = spawn_pos # Asignar ANTES de colgar del árbol para registrar _posicion_base
			var diff_val: String = str(slot.get("ai_difficulty", "normal"))
			ai.set("bando", bando_val)
			ai.set("ai_difficulty", diff_val)
			# ── Inyección de Era en la IA ──────────────────────────────────────
			if "era_actual" in ai:
				ai.set("era_actual", era_inicial)

			if slot_idx < slot_colors_arr.size() and slot_colors_arr[slot_idx] is Color:
				ai.set("ai_color", slot_colors_arr[slot_idx])

			root.add_child(ai)
			ai.global_position = spawn_pos
			ai.set("_posicion_base", spawn_pos)

			# Instanciar 5 aldeanos bot físicos estrictamente en su esquina
			if is_instance_valid(villager_scene):
				for v in range(5):
					var vil: Node = villager_scene.instantiate()
					if is_instance_valid(vil) and vil is Node3D:
						var vil3d := vil as Node3D
						vil3d.name = "Vil_B_%d_%d" % [slot_idx, v]
						var offset_v := Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
						vil3d.position = spawn_pos + offset_v
						if vil3d.has_method("set_multiplayer_authority"):
							vil3d.call("set_multiplayer_authority", 1)
						if "bando" in vil3d:
							vil3d.set("bando", bando_val)
						if slot_idx < slot_colors_arr.size() and "color_bando" in vil3d:
							vil3d.set("color_bando", slot_colors_arr[slot_idx])
						unit_container.add_child(vil3d)
						vil3d.global_position = spawn_pos + offset_v

			print("MultiplayerManager: Slot %d (Bot IA Bando %d) instanciados en %s (Era %d)" % [slot_idx, bando_val, str(spawn_pos), era_inicial])

# ─── RPCs de Órdenes RTS Transmitidas ──────────────────────────────────────────

@rpc("any_peer", "call_local", "reliable")
func rpc_ordenar_movimiento(unit_paths: Array[NodePath], target_position: Vector3) -> void:
	for path in unit_paths:
		var node := get_node_or_null(path)
		if is_instance_valid(node) and node.has_method("command_move"):
			node.call("command_move", target_position)

@rpc("any_peer", "call_local", "reliable")
func rpc_ordenar_ataque(unit_paths: Array[NodePath], target_path: NodePath) -> void:
	var target_node := get_node_or_null(target_path)
	if not is_instance_valid(target_node):
		return
	for path in unit_paths:
		var node := get_node_or_null(path)
		if is_instance_valid(node) and node.has_method("command_attack"):
			node.call("command_attack", target_node)

@rpc("any_peer", "call_local", "reliable")
func rpc_ordenar_recoleccion(unit_paths: Array[NodePath], resource_path: NodePath) -> void:
	var res_node := get_node_or_null(resource_path)
	if not is_instance_valid(res_node):
		return
	for path in unit_paths:
		var node := get_node_or_null(path)
		if is_instance_valid(node) and node.has_method("command_gather"):
			node.call("command_gather", res_node)

# ─── Sistema de Alianzas Diplomáticas Dinámicas ──────────────────────────────

@rpc("any_peer", "call_local", "reliable")
func rpc_cambiar_estado_diplomatico(sender_peer: int, target_peer: int, nuevo_estado: String) -> void:
	var key := "%d_%d" % [sender_peer, target_peer]
	alliances_matrix[key] = nuevo_estado
	print("MultiplayerManager: Estado Diplomático [%d ➔ %d]: %s" % [sender_peer, target_peer, nuevo_estado])
	diplomatic_status_changed.emit(sender_peer, target_peer, nuevo_estado)

func es_aliado(peer_a: int, peer_b: int) -> bool:
	if peer_a == peer_b:
		return true
	var key := "%d_%d" % [peer_a, peer_b]
	var state: String = str(alliances_matrix.get(key, "Enemigo"))
	return state == "Aliado"

# ─── Reinicio de Sesión y Slots de Lobby (State Reset Loop) ───────────────────

## Limpia el diccionario y array de slots del lobby de red y reinicia estado de sesión.
func reiniciar_banco_partida() -> void:
	_init_default_slots()
	alliances_matrix.clear()
	if is_instance_valid(enet_peer):
		enet_peer.close()
	enet_peer = null
	var mp: MultiplayerAPI = get_multiplayer() if is_inside_tree() else null
	if mp != null and mp.has_multiplayer_peer():
		mp.multiplayer_peer = null
	is_host = false
	if has_signal("lobby_slots_updated"):
		lobby_slots_updated.emit()
	print("MultiplayerManager: ✅ reiniciar_banco_partida() ejecutado — Slots de lobby limpios.")
