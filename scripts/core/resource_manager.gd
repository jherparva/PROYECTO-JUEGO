## ResourceManager — Script Global de Autoload para la Economía RTS (GDScript 2.0 / Godot 4).
##
## Administra los 5 recursos centrales del juego: "wood", "food", "stone", "iron" y "gold".
## Proporciona las funciones de adición, verificación de costo, deducción y el
## Sistema de Eras histórico inspirado en Empire Earth.

class_name GlobalResourceManager
extends Node

# ─── Sistema de Eras ───────────────────────────────────────────────────────────

## Enumeración de las 10 Eras históricas (estilo Empire Earth).
enum Era {
	PREHISTORICA = 0,  ## Edad de Piedra primitiva — era inicial.
	PIEDRA       = 1,  ## Edad de Piedra.
	BRONCE       = 2,  ## Edad de Bronce.
	HIERRO       = 3,  ## Edad de Hierro.
	MEDIEVAL     = 4,  ## Edad Media.
	RENACIMIENTO = 5,  ## Era del Renacimiento / Pólvora.
	INDUSTRIAL   = 6,  ## Era Industrial / Imperial.
	ATOMICA      = 7,  ## Era Atómica (1ª y 2ª Guerra Mundial).
	DIGITAL      = 8,  ## Era Digital / Moderna.
	NANO_FUTURISTA = 9 ## Era Nano / Cyberpunk / Espacial.
}

## Nombres en cadena para mostrar en el HUD.
const NOMBRE_ERA: Dictionary = {
	Era.PREHISTORICA: "Edad Prehistórica",
	Era.PIEDRA:       "Edad de Piedra",
	Era.BRONCE:       "Edad de Bronce",
	Era.HIERRO:       "Edad de Hierro",
	Era.MEDIEVAL:     "Edad Media",
	Era.RENACIMIENTO: "Era del Renacimiento",
	Era.INDUSTRIAL:   "Era Industrial",
	Era.ATOMICA:      "Era Atómica",
	Era.DIGITAL:      "Era Digital",
	Era.NANO_FUTURISTA: "Era Nano-Futurista",
}

## Coste de evolución para avanzar DESDE cada era a la siguiente (dbtechtree.dat).
const COSTE_EVOLUCION: Dictionary = {
	Era.PREHISTORICA: { "food": 850 },
	Era.PIEDRA:       { "food": 750, "gold": 400, "stone": 400 },
	Era.BRONCE:       { "food": 1000, "gold": 500, "stone": 500 },
	Era.HIERRO:       { "food": 1200, "gold": 625, "iron": 625 },
	Era.MEDIEVAL:     { "food": 1450, "gold": 725, "iron": 725 },
	Era.RENACIMIENTO: { "food": 1650, "gold": 825, "iron": 825 },
	Era.INDUSTRIAL:   { "food": 1800, "gold": 900, "iron": 900 },
	Era.ATOMICA:      { "food": 2200, "gold": 1100, "iron": 1100 },
	Era.DIGITAL:      { "food": 2675, "gold": 1350, "iron": 1350 },
}

## Multiplicadores de atributos globales por era.
const MULTIPLICADORES_ERA: Dictionary = {
	Era.PREHISTORICA: { "gather_rate": 1.0, "building_hp": 1.0, "attack": 1.0, "speed": 1.0 },
	Era.PIEDRA:       { "gather_rate": 1.5, "building_hp": 1.3, "attack": 1.2, "speed": 1.1 },
	Era.BRONCE:       { "gather_rate": 2.0, "building_hp": 1.7, "attack": 1.5, "speed": 1.2 },
	Era.HIERRO:       { "gather_rate": 2.8, "building_hp": 2.2, "attack": 2.0, "speed": 1.3 },
	Era.MEDIEVAL:     { "gather_rate": 3.5, "building_hp": 3.0, "attack": 2.8, "speed": 1.4 },
	Era.RENACIMIENTO: { "gather_rate": 4.2, "building_hp": 3.8, "attack": 3.5, "speed": 1.5 },
	Era.INDUSTRIAL:   { "gather_rate": 5.0, "building_hp": 4.5, "attack": 4.2, "speed": 1.6 },
	Era.ATOMICA:      { "gather_rate": 6.0, "building_hp": 5.5, "attack": 5.0, "speed": 1.7 },
	Era.DIGITAL:      { "gather_rate": 7.5, "building_hp": 6.8, "attack": 6.0, "speed": 1.8 },
	Era.NANO_FUTURISTA: { "gather_rate": 9.5, "building_hp": 8.5, "attack": 7.5, "speed": 2.0 },
}

# ─── Señales ───────────────────────────────────────────────────────────────────
## Emitida cada vez que la cantidad de recursos cambia.
signal recursos_actualizados(recursos: Dictionary)
## Señal alias para compatibilidad con la UI / HUD existente.
signal resources_changed(current_resources: Dictionary)
## Señal para avisar a la UI del cambio de población.
signal population_changed(current_pop: int, max_pop: int)
## Emitida cuando un jugador avanza de era. Propaga el ID del peer/jugador y el índice de la nueva era.
signal era_evolucionada(player_id: int, nueva_era: int)
## Emitida durante la transición de era (cuenta regresiva activa).
@warning_ignore("unused_signal")
signal evolucion_en_progreso(segundos_restantes: float, era_destino: String)

# ─── Diccionario Central de Recursos ───────────────────────────────────────────
var resources: Dictionary = {
	"wood": 200,
	"food": 200,
	"stone": 150,
	"iron": 0,
	"gold": 0
}

var recursos: Dictionary:
	get: return resources
	set(v): resources = v

# ─── Estado de Era ─────────────────────────────────────────────────────────────
## Era actual del jugador.
var era_actual: Era = Era.PREHISTORICA
## Indica si hay una transición de era en curso (bloquea nuevos intentos).
var evolucionando: bool = false

# ─── Multiplicadores activos (inicializados a era PREHISTORICA) ────────────────
var multiplicador_recoleccion: float = 1.0
var multiplicador_hp_edificio: float = 1.0
var multiplicador_ataque:      float = 1.0
var multiplicador_velocidad:   float = 1.0

# ─── Modificadores de Civilización (dbpremadecivs.dat + dbcivilization.dat) ───
var civilization_actual: String = "ninguna"
var civ_gather_mult: Dictionary = {
	"food": 1.0,
	"wood": 1.0,
	"stone": 1.0,
	"gold": 1.0,
	"iron": 1.0
}
var civ_tech_cost_mult: float = 1.0
var civ_population_bonus: int = 0
var civ_attack_mult: float = 1.0
var civ_speed_mult: float = 1.0
var civ_building_hp_mult: float = 1.0

# ─── Control de Población ──────────────────────────────────────────────────────
var current_population: int = 0
var max_population: int = 10

# ─── Presets Oficiales Empire Earth (dbstartingresources.dat) ────────────────
const PRESETS_RECURSOS_INICIALES: Dictionary = {
	0: { "name": "Tournament - Low",       "food": 200,   "wood": 175,   "stone": 210,  "iron": 0,     "gold": 0 },
	1: { "name": "Tournament - Defensive", "food": 200,   "wood": 175,   "stone": 500,  "iron": 0,     "gold": 0 },
	2: { "name": "Standard - Low",         "food": 500,   "wood": 400,   "stone": 630,  "iron": 0,     "gold": 0 },
	3: { "name": "Standard - High",        "food": 800,   "wood": 750,   "stone": 800,  "iron": 100,   "gold": 100 },
	4: { "name": "Death Match",            "food": 15000, "wood": 15000, "stone": 5000, "iron": 10000, "gold": 10000 }
}

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	add_to_group("resource_manager")

func _ready() -> void:
	add_to_group("resource_manager")
	aplicar_configuracion_partida()
	call_deferred("emit_all_signals")

## Aplica los presets de recursos y era inicial configurados en GameSettings
func aplicar_configuracion_partida() -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	var preset_idx: int = 2 # Por defecto Standard - Low
	var start_era: int = 0

	if is_instance_valid(gs):
		if "resource_preset" in gs:
			preset_idx = int(gs.get("resource_preset"))
		elif "initial_resources" in gs:
			preset_idx = int(gs.get("initial_resources"))
		if "starting_era" in gs:
			start_era = int(gs.get("starting_era"))

	# Si es Death Match (preset 4), se aplican los 15,000 fijos de EE
	if preset_idx == 4:
		var dm: Dictionary = PRESETS_RECURSOS_INICIALES[4]
		resources["food"]  = int(dm["food"])
		resources["wood"]  = int(dm["wood"])
		resources["stone"] = int(dm["stone"])
		resources["iron"]  = int(dm["iron"])
		resources["gold"]  = int(dm["gold"])
	else:
		var base_p: Dictionary = PRESETS_RECURSOS_INICIALES.get(preset_idx, PRESETS_RECURSOS_INICIALES[2])
		resources["food"]  = int(base_p["food"])
		resources["wood"]  = int(base_p["wood"])
		resources["stone"] = int(base_p["stone"])
		resources["iron"]  = int(base_p["iron"])
		resources["gold"]  = int(base_p["gold"])

		# Si se inicia en una era avanzada (>0), inyectar los minerales y escalas de la era
		if start_era > 0:
			configurar_balance_recursos_era_inicial(start_era)

	if start_era > 0:
		_aplicar_nueva_era(start_era)

	_aplicar_civilizacion_seleccionada()
	_notify_resource_changes()

## Aplica los modificadores nativos de la civilización seleccionada en GameSettings (dbpremadecivs.dat)
func _aplicar_civilizacion_seleccionada() -> void:
	var civ_id: String = "ninguna"
	var presets: Dictionary = {}
	var gs: Node = get_node_or_null("/root/GameSettings")
	if is_instance_valid(gs):
		if "civilization" in gs:
			civ_id = str(gs.get("civilization")).to_lower()
		if "CIV_PRESETS" in gs:
			presets = gs.get("CIV_PRESETS") as Dictionary
	else:
		var gs_class = load("res://scripts/core/game_settings.gd")
		if gs_class:
			var temp_gs = gs_class.new()
			if "civilization" in temp_gs:
				civ_id = str(temp_gs.civilization).to_lower()
			if "CIV_PRESETS" in temp_gs:
				presets = temp_gs.CIV_PRESETS
			temp_gs.free()

	civilization_actual = civ_id

	if presets.has(civ_id):
		var p: Dictionary = presets[civ_id]
		civ_gather_mult["food"]  = float(p.get("gather_food", 1.0))
		civ_gather_mult["wood"]  = float(p.get("gather_wood", 1.0))
		civ_gather_mult["stone"] = float(p.get("gather_stone", 1.0))
		civ_gather_mult["gold"]  = float(p.get("gather_gold", 1.0))
		civ_gather_mult["iron"]  = float(p.get("gather_iron", 1.0))
		civ_tech_cost_mult       = float(p.get("tech_cost_mult", 1.0))
		civ_population_bonus     = int(p.get("population", 0))
		civ_attack_mult          = float(p.get("attack", 1.0))
		civ_speed_mult           = float(p.get("speed", 1.0))
		max_population += civ_population_bonus
		print("GlobalResourceManager: Civilización '%s' activada (Pop +%d, TechCost x%.2f)" % [
			civ_id, civ_population_bonus, civ_tech_cost_mult
		])

# ─── API Principal de Recursos ─────────────────────────────────────────────────

## Suma una cantidad de recursos al inventario global y emite las señales de actualización.
func add_resources(resource_type: String, amount: int) -> void:
	if amount <= 0:
		return

	var key := resource_type.to_lower()
	var mult: float = float(civ_gather_mult.get(key, 1.0))
	var effective_amount: int = int(round(float(amount) * mult))

	if resources.has(key):
		resources[key] += effective_amount
	else:
		resources[key] = effective_amount

	_notify_resource_changes()

## Verifica si el jugador posee recursos suficientes para cubrir `costos`.
func puede_permitirse(costos: Dictionary) -> bool:
	for res_name: String in costos:
		var required_val: int = int(costos[res_name])
		var current_val: int  = int(resources.get(res_name.to_lower(), 0))
		if current_val < required_val:
			return false
	return true

## Intenta gastar los recursos requeridos. Retorna true si tuvo éxito.
func gastar_recursos(costos: Dictionary) -> bool:
	if not puede_permitirse(costos):
		return false

	for res_name: String in costos:
		var cost_val: int = int(costos[res_name])
		var key := res_name.to_lower()
		resources[key] -= cost_val

	_notify_resource_changes()
	return true

# ─── Métodos Alias para Compatibilidad ────────────────────────────────────────

func can_afford(cost: Dictionary) -> bool:
	return puede_permitirse(cost)

func spend_resources(cost: Dictionary) -> bool:
	return gastar_recursos(cost)

# ─── API del Sistema de Eras ───────────────────────────────────────────────────

## Retorna el diccionario de costos para evolucionar desde la era actual.
func consulta_coste_era() -> Dictionary:
	var base_cost: Dictionary = COSTE_EVOLUCION.get(int(era_actual), {}) as Dictionary
	if civ_tech_cost_mult != 1.0 and not base_cost.is_empty():
		var discounted: Dictionary = {}
		for res_k: String in base_cost:
			discounted[res_k] = int(round(float(base_cost[res_k]) * civ_tech_cost_mult))
		return discounted
	return base_cost

## Retorna el nombre en texto de la era actual.
func get_nombre_era_actual() -> String:
	return NOMBRE_ERA.get(int(era_actual), "Era Desconocida") as String

## Retorna true si se puede evolucionar (no está al máximo, no está evolucionando, tiene fondos).
func puede_evolucionar() -> bool:
	if evolucionando:
		return false
	var siguiente: int = int(era_actual) + 1
	if siguiente > int(Era.NANO_FUTURISTA):
		return false
	var costo: Dictionary = consulta_coste_era()
	if costo.is_empty():
		return false
	return puede_permitirse(costo)

## Aplica el cambio de era internamente y lo difunde a la sala.
func _aplicar_nueva_era(nueva_era: Variant, player_id: int = 1) -> void:
	var era_val: int = int(nueva_era)
	var nombre: String = NOMBRE_ERA.get(era_val, "Era Desconocida") as String
	print("▶ GlobalResourceManager: _aplicar_nueva_era → %s (Index %d) para jugador %d" % [
		nombre, era_val, player_id
	])
	notificar_avance_era(player_id, era_val)

## Difunde el avance de era a todas las máquinas de la sesión (Replicación Asíncrona Individual).
func notificar_avance_era(target_player_id: int, era_destino: int) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc("rpc_notificar_avance_era", target_player_id, era_destino)
	else:
		rpc_notificar_avance_era(target_player_id, era_destino)

## RPC confiable ejecutado en todos los clientes y servidor.
@rpc("any_peer", "call_local", "reliable")
func rpc_notificar_avance_era(target_player_id: int, era_destino: int) -> void:
	var local_id: int = 1
	if multiplayer.has_multiplayer_peer():
		local_id = multiplayer.get_unique_id()

	# Si es el jugador local, actualizar era_actual, multiplicadores y emitir cambios de HUD
	if target_player_id == local_id:
		era_actual = int(era_destino) as Era
		evolucionando = false
		_actualizar_multiplicadores_locales(int(era_actual))
		_notify_resource_changes()

	# Emitir la señal asíncrona con el peer_id y la nueva era
	era_evolucionada.emit(target_player_id, era_destino)

	# El Servidor procesa la extinción ecológica local de la fauna cercana
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_procesar_extincion_fauna(target_player_id, era_destino)

func _actualizar_multiplicadores_locales(era_idx: int) -> void:
	var base_mults: Dictionary = MULTIPLICADORES_ERA.get(era_idx, MULTIPLICADORES_ERA[Era.PREHISTORICA]) as Dictionary
	multiplicador_recoleccion = float(base_mults.get("gather_rate", 1.0))
	multiplicador_hp_edificio = float(base_mults.get("building_hp",  1.0))
	multiplicador_ataque      = float(base_mults.get("attack",       1.0))
	multiplicador_velocidad   = float(base_mults.get("speed",        1.0))

func _procesar_extincion_fauna(target_player_id: int, era_destino: int) -> void:
	var scene_tree := get_tree()
	if not is_instance_valid(scene_tree):
		return

	# Buscar Capitolio o estructuras pertenecientes al jugador que avanzó
	var player_structures: Array[Node3D] = []
	for tc in scene_tree.get_nodes_in_group("town_centers"):
		if is_instance_valid(tc) and tc is Node3D:
			var tc_owner: int = int(tc.get("owner_peer_id")) if tc.get("owner_peer_id") != null else int(tc.get_multiplayer_authority())
			if tc_owner == target_player_id or (target_player_id == 1 and tc.get("bando") == 0):
				player_structures.append(tc as Node3D)

	if player_structures.is_empty():
		for b in scene_tree.get_nodes_in_group("buildings"):
			if is_instance_valid(b) and b is Node3D:
				var b_owner: int = int(b.get("owner_peer_id")) if b.get("owner_peer_id") != null else int(b.get_multiplayer_authority())
				if b_owner == target_player_id:
					player_structures.append(b as Node3D)

	if player_structures.is_empty():
		return

	var spawner: Node = scene_tree.get_first_node_in_group("resource_spawner")
	var raw_creatures: Array[Node] = scene_tree.get_nodes_in_group("fauna_3d") + scene_tree.get_nodes_in_group("wild_creatures") + scene_tree.get_nodes_in_group("fauna")
	var checked: Dictionary = {}

	for node in raw_creatures:
		if not is_instance_valid(node) or checked.has(node):
			continue
		checked[node] = true

		if not (node is Node3D):
			continue

		var creature := node as Node3D
		if "is_animal_dead" in creature and creature.get("is_animal_dead"):
			continue

		# Bloque de era de la criatura (0: Primitiva 0-2, 1: Histórica 3-6, 2: Futurista 7-9)
		var c_bloque: int = 0
		if "era_bloque" in creature:
			c_bloque = int(creature.get("era_bloque"))
		elif creature.has_method("get_era_bloque"):
			c_bloque = int(creature.call("get_era_bloque"))

		var target_bloque: int = 0
		match era_destino:
			0, 1, 2: target_bloque = 0
			3, 4, 5, 6: target_bloque = 1
			_: target_bloque = 2

		# Si la criatura pertenece a un bloque inferior al destino
		if c_bloque < target_bloque:
			var min_dist: float = 999999.0
			for struct in player_structures:
				var d: float = creature.global_position.distance_to(struct.global_position)
				if d < min_dist:
					min_dist = d

			# Rango de extinción <= 80.0 metros respecto al centro urbano
			if min_dist <= 80.0:
				var death_pos: Vector3 = creature.global_position
				var was_aggro: bool = bool(creature.get("is_aggressive")) if "is_aggressive" in creature else false
				print("GlobalResourceManager: 🦣 Extinción ecológica de '%s' (dist: %.1fm) por avance de jugador %d a Era %d." % [
					creature.name, min_dist, target_player_id, era_destino
				])
				if creature.has_method("morir_por_extincion"):
					creature.call("morir_por_extincion")
				else:
					creature.queue_free()

				if is_instance_valid(spawner) and spawner.has_method("reemplazar_fauna_extinta"):
					spawner.call("reemplazar_fauna_extinta", death_pos, era_destino, was_aggro)


## Inyecta el balance de recursos iniciales acorde a la era avanzada configurada
## para que la IA Skirmish y el jugador humano tengan los minerales necesarios (Hierro/Oro/Piedra/Madera/Comida).
func configurar_balance_recursos_era_inicial(era_val: int) -> void:
	match era_val:
		0: # Prehistoria
			resources["wood"]  = maxi(int(resources.get("wood", 200)), 175)
			resources["food"]  = maxi(int(resources.get("food", 200)), 200)
			resources["stone"] = maxi(int(resources.get("stone", 150)), 150)
			resources["iron"]  = int(resources.get("iron", 0))
			resources["gold"]  = int(resources.get("gold", 0))
		1: # Piedra
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 350)
			resources["food"]  = maxi(int(resources.get("food", 0)), 350)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 300)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 50)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 50)
		2: # Bronce
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 500)
			resources["food"]  = maxi(int(resources.get("food", 0)), 500)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 400)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 250)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 150)
		3: # Hierro (Foro Clásico y Soldados de Hierro)
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 800)
			resources["food"]  = maxi(int(resources.get("food", 0)), 800)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 500)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 600)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 300)
		4: # Medieval
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 1200)
			resources["food"]  = maxi(int(resources.get("food", 0)), 1200)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 800)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 1000)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 600)
		5: # Renacimiento / Pólvora
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 1800)
			resources["food"]  = maxi(int(resources.get("food", 0)), 1800)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 1000)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 1500)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 1000)
		6, 7: # Industrial / Atómica
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 2500)
			resources["food"]  = maxi(int(resources.get("food", 0)), 2500)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 1500)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 2500)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 2000)
		8, 9: # Digital / Nano-Futurista
			resources["wood"]  = maxi(int(resources.get("wood", 0)), 4000)
			resources["food"]  = maxi(int(resources.get("food", 0)), 4000)
			resources["stone"] = maxi(int(resources.get("stone", 0)), 2500)
			resources["iron"]  = maxi(int(resources.get("iron", 0)), 4000)
			resources["gold"]  = maxi(int(resources.get("gold", 0)), 3500)

	_notify_resource_changes()
	print("GlobalResourceManager: ✅ Balance de recursos iniciales ajustado para Era %d." % era_val)

# ─── Gestión de Población ─────────────────────────────────────────────────────

func has_population_room(amount: int = 1) -> bool:
	return (current_population + amount) <= max_population

func change_current_population(amount: int) -> void:
	current_population = clamp(current_population + amount, 0, max_population)
	population_changed.emit(current_population, max_population)

func change_max_population(amount: int) -> void:
	max_population = max(0, max_population + amount)
	population_changed.emit(current_population, max_population)

# ─── Notificación Interna ──────────────────────────────────────────────────────

func _notify_resource_changes() -> void:
	recursos_actualizados.emit(resources)
	resources_changed.emit(resources)

func emit_all_signals() -> void:
	_notify_resource_changes()
	population_changed.emit(current_population, max_population)

# ─── Reinicio de Sesión (State Reset Loop) ────────────────────────────────────

## Restablece todos los valores del banco de recursos a valores iniciales y la era estrictamente a 0.
## Debe llamarse ANTES de 'change_scene_to_file' para evitar herencia de datos entre partidas.
func reiniciar_banco_partida() -> void:
	# Restablecer recursos a valores de arranque por defecto
	resources = {
		"wood":  200,
		"food":  200,
		"stone": 150,
		"iron":  0,
		"gold":  0
	}

	# Restablecer era al inicio absoluto estrictamente en 0
	era_actual     = Era.PREHISTORICA # int 0
	evolucionando  = false

	# Restablecer multiplicadores activos al estado PREHISTORICA
	multiplicador_recoleccion = 1.0
	multiplicador_hp_edificio = 1.0
	multiplicador_ataque      = 1.0
	multiplicador_velocidad   = 1.0

	# Restablecer población
	current_population = 0
	max_population     = 10

	# Restablecer bonos de recolección tecnológica
	if "tech_gather_bonuses" in self:
		set("tech_gather_bonuses", {
			"wood": 1.0,
			"food": 1.0,
			"stone": 1.0,
			"gold": 1.0,
			"iron": 1.0
		})

	# Emitir señales para refrescar cualquier HUD residual
	_notify_resource_changes()
	population_changed.emit(current_population, max_population)

	print("GlobalResourceManager: ✅ reiniciar_banco_partida() ejecutado — Sesión limpia, Era 0, Madera=200, Comida=200, Oro=0, Hierro=0.")
