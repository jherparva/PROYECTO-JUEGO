## Barracks3D — Cuartel Militar 3D para Entrenamiento de Infantería (GDScript 2.0 / Godot 4).
##
## Edificio de producción militar que gestiona la cola de entrenamiento de unidades (Array de Strings, máx 5),
## temporizador $ProductionTimer, reembolso al cancelar, Marker3D de salida y evolución en 9 Eras.

class_name Barracks3D
extends "res://scripts/buildings/building_base_3d.gd"

# ─── Señales ───────────────────────────────────────────────────────────────────
signal unit_queued(unit_id: String, queue_size: int)
signal queue_progress_updated(progress: float, current_unit_id: String)
signal unit_spawned(unit_instance: Node3D)

# ─── 1. Catálogo Completo de Unidades Militares por Era y Edificio ──────────
@warning_ignore("inference_on_variant")
const CATALOGO_UNIDADES: Dictionary = {
	# ══ CUARTEL DE INFANTERÍA (building_type: "barracks") ══════════════════
	"brawler_primitivo": {
		"name": "Luchador a Mano Limpia", "building_type": "barracks",
		"type": "melee", "cost": {"food": 40},
		"train_time": 4.0, "era_min": 0, "era_max": 1,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"clubman_era0": {
		"name": "Guerrero con Garrote", "building_type": "barracks",
		"type": "melee", "cost": {"food": 60, "wood": 20},
		"train_time": 5.0, "era_min": 0, "era_max": 1,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"spearman_era0": {
		"name": "Lancero de Sílex", "building_type": "barracks",
		"type": "melee", "cost": {"food": 50, "wood": 20},
		"train_time": 5.0, "era_min": 0, "era_max": 1,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"piquero_antigregario": {
		"name": "Piquero Anti-Gregario", "building_type": "barracks",
		"type": "melee", "cost": {"food": 50, "wood": 40},
		"train_time": 5.5, "era_min": 2, "era_max": 4,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"maceman_bronze": {
		"name": "Macero de Cobre", "building_type": "barracks",
		"type": "melee", "cost": {"food": 65, "wood": 35},
		"train_time": 6.0, "era_min": 2, "era_max": 3,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"retiarius_gladiador": {
		"name": "Gladiador Lanzador de Redes", "building_type": "barracks",
		"type": "melee", "cost": {"food": 70, "wood": 30},
		"train_time": 6.5, "era_min": 2, "era_max": 3,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"espadachin": {
		"name": "Espadachín de Hierro", "building_type": "barracks",
		"type": "melee", "cost": {"food": 80, "iron": 40},
		"train_time": 7.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"espadachin_hierro": {
		"name": "Espadachín de Hierro", "building_type": "barracks",
		"type": "melee", "cost": {"food": 80, "iron": 40},
		"train_time": 7.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/espadachin_hierro_3d.tscn"
	},
	"legionary_era3": {
		"name": "Legionario Romano", "building_type": "barracks",
		"type": "melee", "cost": {"food": 90, "iron": 50},
		"train_time": 7.5, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/legionary_era3_3d.tscn"
	},
	"halberdier": {
		"name": "Halabardero Imperial", "building_type": "barracks",
		"type": "melee", "cost": {"food": 90, "iron": 50},
		"train_time": 7.5, "era_min": 4, "era_max": 6,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"mosquetero": {
		"name": "Mosquetero de Línea", "building_type": "barracks",
		"type": "ranged", "cost": {"food": 100, "iron": 70},
		"train_time": 8.5, "era_min": 5, "era_max": 7,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"soldado_asalto": {
		"name": "Soldado de Asalto Táctico", "building_type": "barracks",
		"type": "ranged", "cost": {"food": 130, "iron": 100},
		"train_time": 10.0, "era_min": 7, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"cyborg_militar": {
		"name": "Cyborg Combate Pesado", "building_type": "barracks",
		"type": "ranged", "cost": {"iron": 200, "gold": 150},
		"train_time": 12.0, "era_min": 8, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},

	# ══ CAMPO DE TIRO (building_type: "archery_range") ═════════════════════
	"hondero_primitivo": {
		"name": "Hondero Tribal", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 40, "wood": 20},
		"train_time": 4.5, "era_min": 0, "era_max": 1,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"lanzador_piedras": {
		"name": "Lanzador de Piedras", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 50, "wood": 35},
		"train_time": 6.0, "era_min": 0, "era_max": 2,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"bowman_era1": {
		"name": "Arquero de Piedra", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 40, "wood": 30},
		"train_time": 5.0, "era_min": 1, "era_max": 3,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"arquero_corto": {
		"name": "Arquero de Arco Corto", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 60, "wood": 40},
		"train_time": 6.5, "era_min": 2, "era_max": 4,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"arquero_largo": {
		"name": "Arquero de Tiro Largo", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 75, "wood": 40},
		"train_time": 7.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"ballestero": {
		"name": "Ballestero de Élite", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 90, "iron": 30},
		"train_time": 8.0, "era_min": 4, "era_max": 6,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"fusilero": {
		"name": "Fusilero de Asalto", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 120, "iron": 80},
		"train_time": 9.5, "era_min": 6, "era_max": 8,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"infiltrador_nano": {
		"name": "Infiltrador Óptico Camuflado", "building_type": "archery_range",
		"type": "ranged", "cost": {"food": 120, "gold": 100},
		"train_time": 11.0, "era_min": 8, "era_max": 9,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},
	"tirador_plasma": {
		"name": "Tirador Fotónico de Plasma", "building_type": "archery_range",
		"type": "ranged", "cost": {"gold": 200, "iron": 150},
		"train_time": 13.0, "era_min": 9, "era_max": 9,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	},

	# ══ ESTABLO REAL (building_type: "stable") ══════════════════════════════
	"jinete_primitivo": {
		"name": "Jinete Tribal", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 100, "wood": 50},
		"train_time": 7.0, "era_min": 0, "era_max": 3,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"caballero_ligero": {
		"name": "Caballero Ligero", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 120, "iron": 40},
		"train_time": 10.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"caballero_pesado": {
		"name": "Caballero Pesado Acorazado", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 150, "iron": 80},
		"train_time": 12.0, "era_min": 4, "era_max": 6,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"carro_primitivo": {
		"name": "Carro de Guerra Primitivo", "building_type": "stable",
		"type": "cavalry", "cost": {"wood": 80, "food": 60},
		"train_time": 9.0, "era_min": 2, "era_max": 4,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"cataphract_era3": {
		"name": "Catafracta de Hierro", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 120, "iron": 80},
		"train_time": 10.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/cataphract_era3_3d.tscn"
	},
	"war_elephant_era3": {
		"name": "Elefante de Guerra", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 180, "iron": 50},
		"train_time": 14.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/war_elephant_era3_3d.tscn"
	},
	"hussar": {
		"name": "Húsar de Reconocimiento", "building_type": "stable",
		"type": "cavalry", "cost": {"food": 140, "iron": 60},
		"train_time": 11.0, "era_min": 5, "era_max": 7,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"apc_blindado": {
		"name": "APC Transporte Blindado", "building_type": "stable",
		"type": "cavalry", "cost": {"iron": 180, "gold": 90},
		"train_time": 13.0, "era_min": 7, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"mech_walker": {
		"name": "Mech Walker de Combate", "building_type": "stable",
		"type": "cavalry", "cost": {"iron": 250, "gold": 180},
		"train_time": 15.0, "era_min": 8, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},

	# ══ TALLER DE ASEDIO (building_type: "siege_workshop") ═════════════════
	"chariot_archer_era2": {
		"name": "Carro de Guerra de Rango", "building_type": "siege_workshop",
		"type": "cavalry", "cost": {"wood": 90, "food": 70},
		"train_time": 8.0, "era_min": 2, "era_max": 4,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"ariete_carnero_era3": {
		"name": "Ariete de Carnero", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 120, "iron": 60},
		"train_time": 11.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/ariete_carnero_era3_3d.tscn"
	},
	"catapulta_onagro_era3": {
		"name": "Onagro de Torsión", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 150, "iron": 75},
		"train_time": 13.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/catapulta_onagro_era3_3d.tscn"
	},
	"balista_torsion_era3": {
		"name": "Balista de Torsión", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 130, "iron": 65},
		"train_time": 12.0, "era_min": 3, "era_max": 5,
		"scene_path": "res://scenes/units/balista_torsion_era3_3d.tscn"
	},
	"ariete_primitivo": {
		"name": "Ariete de Tronco Primitivo", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 80, "food": 40},
		"train_time": 9.0, "era_min": 0, "era_max": 2,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"ballista": {
		"name": "Ballesta de Asedio", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 120, "iron": 30},
		"train_time": 14.0, "era_min": 2, "era_max": 4,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"trebuchet": {
		"name": "Trebuchet Pesado", "building_type": "siege_workshop",
		"type": "siege", "cost": {"wood": 200, "iron": 60},
		"train_time": 18.0, "era_min": 4, "era_max": 6,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"canon_bronce": {
		"name": "Cañón de Bronce", "building_type": "siege_workshop",
		"type": "siege", "cost": {"iron": 150, "gold": 80},
		"train_time": 16.0, "era_min": 5, "era_max": 7,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"mortero_campo": {
		"name": "Mortero de Campaña", "building_type": "siege_workshop",
		"type": "siege", "cost": {"iron": 180, "gold": 100},
		"train_time": 14.0, "era_min": 6, "era_max": 8,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"artilleria_pesada": {
		"name": "Artillería Pesada Autopropulsada", "building_type": "siege_workshop",
		"type": "siege", "cost": {"iron": 220, "gold": 140},
		"train_time": 18.0, "era_min": 7, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"lanzacohetes": {
		"name": "Lanzacohetes Múltiple", "building_type": "siege_workshop",
		"type": "siege", "cost": {"iron": 250, "gold": 180},
		"train_time": 16.0, "era_min": 8, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"dron_titan": {
		"name": "Dron Titán de Bombardeo", "building_type": "siege_workshop",
		"type": "siege", "cost": {"iron": 300, "gold": 250},
		"train_time": 20.0, "era_min": 9, "era_max": 9,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	}
}

## Retorna unidades disponibles para la Era y tipo de edificio dados, garantizando cero duplicados.
static func get_unidades_disponibles_era(cur_era: int, btype: String = "barracks") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	for uid: String in CATALOGO_UNIDADES:
		var udata: Dictionary = CATALOGO_UNIDADES[uid]
		if str(udata.get("building_type", "barracks")) != btype:
			continue
		var e_min: int = int(udata.get("era_min", 0))
		var e_max: int = int(udata.get("era_max", 99))
		if cur_era >= e_min and cur_era <= e_max:
			var canon_id: String = "clubman_era0" if (uid == "garrotero" or uid == "clubman_era0") else uid
			if seen_ids.has(canon_id):
				continue
			seen_ids[canon_id] = true
			var entry: Dictionary = udata.duplicate()
			entry["id"] = canon_id
			result.append(entry)
	return result

# ─── Configuración y Estado de Producción ──────────────────────────────────────
@export var MAX_QUEUE_SIZE: int = 5
@export var spawn_offset: Vector3 = Vector3(3.5, 0.0, 3.5)

## Array de Strings liviano con los IDs de las unidades en cola
var production_queue: Array[String] = []
var cola_produccion: Array[String]:
	get:
		return production_queue
	set(v):
		production_queue = v

## Referencias a Nodos Hijos de Producción y Spawn
var production_timer: Timer = null
var spawn_point_marker: Marker3D = null

var _spawn_counter: int = 0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Cuartel Militar"
	salud_maxima = 650.0
	salud_actual = 650.0

func _ready() -> void:
	super._ready()
	add_to_group("barracks")
	add_to_group("barracks_3d")

	# Registrar en grupo especializado según el tipo de edificio (building_name)
	if "Campo de Tiro" in building_name or "Arquero" in building_name or "Tiro" in building_name:
		add_to_group("archery_ranges")
	elif "Establo" in building_name or "Caballeriz" in building_name or "Jinete" in building_name:
		add_to_group("stables")
	elif "Asedio" in building_name or "Taller" in building_name or "Catapulta" in building_name:
		add_to_group("siege_workshops")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	rally_point = global_position + spawn_offset

	# Obtener o crear el Marker3D de salida
	spawn_point_marker = get_node_or_null("SpawnPoint") as Marker3D

	# Obtener o crear el Timer de producción interno
	production_timer = get_node_or_null("ProductionTimer") as Timer
	if not is_instance_valid(production_timer):
		production_timer = Timer.new()
		production_timer.name = "ProductionTimer"
		production_timer.one_shot = true
		production_timer.autostart = false
		add_child(production_timer)

	if not production_timer.timeout.is_connected(_on_production_timer_timeout):
		production_timer.timeout.connect(_on_production_timer_timeout)

	# Escuchar cambio de era para swap visual y catálogo
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
	var cur_era: int = int(rm.era_actual) if is_instance_valid(rm) and "era_actual" in rm else era
	_actualizar_modelo_visual_era(cur_era)

func _process(_delta: float) -> void:
	if not is_instance_valid(production_timer) or production_timer.is_stopped() or production_queue.is_empty():
		return

	var current_id: String = production_queue[0]
	var total_time: float = float(CATALOGO_UNIDADES.get(current_id, {}).get("train_time", 6.0))
	var elapsed: float = total_time - production_timer.time_left
	var progress: float = clampf(elapsed / total_time, 0.0, 1.0)
	queue_progress_updated.emit(progress, current_id)

# ─── 2. Métodos de Producción y Reembolso ──────────────────────────────────────

var resource_manager: Node = null

func _get_resource_manager() -> Node:
	if is_instance_valid(resource_manager):
		return resource_manager
	if is_inside_tree():
		var rm_root := get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm_root):
			return rm_root
	if get_parent():
		for child in get_parent().get_children():
			if child is GlobalResourceManager or child.name.begins_with("ResourceManager") or child.is_in_group("resource_manager"):
				return child
	var tree := get_tree() if get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		for node in tree.get_nodes_in_group("resource_manager"):
			if is_instance_valid(node):
				return node
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if child is GlobalResourceManager or child.name.begins_with("ResourceManager") or child.is_in_group("resource_manager"):
					return child
	return null

## Entrena una unidad militar validando recursos, era y espacio en cola (máximo 5).
func entrenar_unidad(unit_id: String) -> bool:
	if is_under_construction or is_dead or production_queue.size() >= MAX_QUEUE_SIZE:
		return false

	if unit_id == "garrotero" and not CATALOGO_UNIDADES.has("garrotero") and CATALOGO_UNIDADES.has("clubman_era0"):
		unit_id = "clubman_era0"

	if not CATALOGO_UNIDADES.has(unit_id):
		push_error("Barracks3D: Unidad '%s' no existe en el catálogo." % unit_id)
		return false

	var unit_info: Dictionary = CATALOGO_UNIDADES[unit_id]
	var rm: Node = _get_resource_manager()
	if not is_instance_valid(rm):
		return false

	# Validar restricción de Era histórica (Tech Tree Locking)
	var cur_era: int = int(rm.era_actual) if "era_actual" in rm else 0
	if cur_era == 0:
		var allowed_era0: Array[String] = ["brawler_primitivo", "garrotero", "clubman_era0", "spearman_era0"]
		if not allowed_era0.has(unit_id):
			print("Barracks3D: dbtechtree.dat Era 0: Bloqueo de unidad '%s'. Solo permitidas unidades prehistóricas." % unit_id)
			return false
	var e_min: int = int(unit_info.get("era_min", 0))
	var e_max: int = int(unit_info.get("era_max", 99))
	if cur_era < e_min or cur_era > e_max:
		print("Barracks3D: La unidad '%s' no está disponible en la Era %d (Requiere Era %d-%d)." % [unit_info.get("name", unit_id), cur_era, e_min, e_max])
		return false

	# Validar límite de población antes de descontar recursos
	var cur_pop: int = int(rm.current_population) if "current_population" in rm else 0
	var max_pop: int = int(rm.max_population) if "max_population" in rm else 0
	var pop_locked: bool = false
	if rm.has_method("has_population_room"):
		pop_locked = not rm.has_population_room(1)
	elif max_pop > 0 and cur_pop + 1 > max_pop:
		pop_locked = true

	if pop_locked:
		var msg := "⚠️ Límite de población alcanzado (" + str(cur_pop) + "/" + str(max_pop) + ")"
		_mostrar_alerta_poblacion(msg)
		print("Barracks3D: " + msg)
		return false


	# Validar y descontar recursos de la reserva global
	var cost: Dictionary = unit_info.get("cost", {})
	if rm.has_method("gastar_recursos") and not rm.gastar_recursos(cost):
		print("Barracks3D: Recursos insuficientes para '%s'." % unit_info["name"])
		return false

	# Descontar espacio de población
	if rm.has_method("change_current_population"):
		rm.change_current_population(1)

	# Insertar ID en la cola
	production_queue.append(unit_id)
	unit_queued.emit(unit_id, production_queue.size())

	# Iniciar el procesado de la cola si es la única unidad
	if production_queue.size() == 1:
		_procesar_siguiente_en_cola()

	print("Barracks3D: Unidad '%s' añadida a la cola (%d/%d)." % [unit_info["name"], production_queue.size(), MAX_QUEUE_SIZE])
	return true

func train_soldier() -> void:
	entrenar_unidad("clubman_era0")

## Controla el temporizador dinámico de producción para la unidad al frente de la cola.
func _procesar_siguiente_en_cola() -> void:
	if not is_instance_valid(production_timer):
		return

	if production_queue.is_empty():
		production_timer.stop()
		return

	var current_id: String = production_queue[0]
	var train_time: float = float(CATALOGO_UNIDADES.get(current_id, {}).get("train_time", 6.0))
	production_timer.start(train_time)

## Callback invocado al expirar el ProductionTimer: instanciar unidad y procesar siguiente.
func _on_production_timer_timeout() -> void:
	if production_queue.is_empty():
		return

	var completed_id: String = str(production_queue.pop_front())
	var unit_info: Dictionary = CATALOGO_UNIDADES.get(completed_id, {})

	# Instanciar físicamente la escena del soldado
	_spawn_military_unit(unit_info)

	# Procesar la siguiente unidad en la cola
	_procesar_siguiente_en_cola()

## Cancela la unidad en la posición `index` y reembolsa el 100% de los recursos y población.
func cancelar_produccion(index: int) -> void:
	if index < 0 or index >= production_queue.size():
		return

	var canceled_id := production_queue[index]
	production_queue.remove_at(index)

	var unit_info: Dictionary = CATALOGO_UNIDADES.get(canceled_id, {})
	var cost: Dictionary = unit_info.get("cost", {})

	# Reembolso exacto al GlobalResourceManager
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_method("add_resources"):
			for rk in cost:
				rm.add_resources(rk, int(cost[rk]))
		if rm.has_method("change_current_population"):
			rm.change_current_population(-1)

	# Si se canceló el primer elemento en progreso, reiniciar el timer para la siguiente unidad
	if index == 0:
		_procesar_siguiente_en_cola()

	print("Barracks3D: Producción de '%s' cancelada. Reembolso del 100%% otorgado." % unit_info.get("name", canceled_id))

# ─── Instanciación y Despacho en Rally Point ───────────────────────────────────

func _spawn_military_unit(unit_info: Dictionary) -> void:
	var path: String = unit_info.get("scene_path", "res://scenes/units/soldier_3d.tscn")
	var scene: PackedScene = null
	if ResourceLoader.exists(path):
		scene = load(path) as PackedScene

	var inst: Node3D = null
	if is_instance_valid(scene):
		inst = scene.instantiate() as Node3D
	else:
		var soldier_class = load("res://scripts/units/soldier_3d.gd")
		if is_instance_valid(soldier_class):
			inst = soldier_class.new() as Node3D

	if not is_instance_valid(inst):
		inst = UnitBase3D.new()
	var spawn_pos: Vector3

	if is_instance_valid(spawn_point_marker):
		spawn_pos = spawn_point_marker.global_position
	elif rally_point_set and rally_point != Vector3.ZERO:
		spawn_pos = global_position + Vector3(3.0, 0.0, 0.0)
	else:
		var spawn_radius := 4.8
		var angle := float(_spawn_counter % 8) * (TAU / 8.0)
		var ring := floorf(float(_spawn_counter) / 8.0) * 1.6
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (spawn_radius + ring)
		spawn_pos = global_position + offset
		_spawn_counter += 1

	var parent: Node = null
	if get_tree() and get_tree().current_scene:
		parent = get_tree().current_scene.get_node_or_null("World/Units")
		if not parent:
			parent = get_tree().current_scene.get_node_or_null("Units")
		if not parent:
			parent = get_tree().current_scene
	if not parent:
		parent = get_parent()
	if not parent:
		parent = self

	inst.set_meta("pop_counted", true)
	parent.add_child(inst)

	inst.global_position = spawn_pos
	inst.add_to_group("units")
	inst.add_to_group("units_3d")
	inst.add_to_group("military_units")

	if bando == Bando.PLAYER:
		inst.add_to_group("player_units")
	else:
		inst.add_to_group("enemy_units")

	if "bando" in inst:
		inst.set("bando", bando)

	# Sello de Era Entrenada y Categoría Militar para inmunidad a mutaciones históricas (Estilo Empire Earth)
	var rm: Node = get_node_or_null("/root/ResourceManager")
	var current_era_idx: int = int(rm.era_actual) if is_instance_valid(rm) and "era_actual" in rm else 0
	if "era_entrenada" in inst:
		inst.set("era_entrenada", current_era_idx)
	if "es_militar" in inst:
		inst.set("es_militar", true)

	# Escalar estadísticas según la Era actual y tipo táctico
	_aplicar_mejoras_era_a_unidad(inst, unit_info)

	# Ordenar movimiento o ataque dinámico al Rally Point / Target
	if rally_point_set and rally_point != Vector3.ZERO:
		if is_instance_valid(rally_target_node) and inst.has_method("command_attack"):
			inst.command_attack(rally_target_node)
		elif inst.has_method("command_move"):
			inst.command_move(rally_point)

	unit_spawned.emit(inst)

func _aplicar_mejoras_era_a_unidad(inst: Node3D, unit_info: Dictionary) -> void:
	var unit_display_name: String = str(unit_info.get("name", "Guerrero"))
	var utype: String = str(unit_info.get("type", "melee"))
	var uid: String = str(unit_info.get("id", ""))

	if "unit_id" in inst:
		inst.set("unit_id", uid)
	if "unit_name" in inst:
		inst.unit_name = unit_display_name

	if "attack_type" in inst:
		inst.set("attack_type", "ranged" if utype in ["ranged", "siege"] else "melee")

	# Ajustar rol y stats según clase táctica
	match utype:
		"cavalry":
			if "speed" in inst:
				inst.set("speed", 7.2)
			if "rango_ataque" in inst:
				inst.set("rango_ataque", 3.2)
		"siege":
			if "speed" in inst:
				inst.set("speed", 3.2)
			if "rango_ataque" in inst:
				inst.set("rango_ataque", 24.0)
			if "projectile_type" in inst:
				inst.set("projectile_type", "stone")
		"ranged":
			if "rango_ataque" in inst:
				inst.set("rango_ataque", 20.0)
			if "projectile_type" in inst:
				inst.set("projectile_type", "arrow")
		"melee":
			if "rango_ataque" in inst:
				inst.set("rango_ataque", 3.0)

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		var era_val: int = int(rm.era_actual)
		if "daño" in inst:
			inst.daño = float(inst.daño) * (1.0 + era_val * 0.35)
		if "salud_maxima" in inst:
			var new_hp := float(inst.salud_maxima) * (1.0 + era_val * 0.3)
			inst.salud_maxima = new_hp
			inst.salud_actual = new_hp

func get_training_progress() -> float:
	if production_queue.is_empty() or not is_instance_valid(production_timer) or production_timer.is_stopped():
		return 0.0
	var current_id := production_queue[0]
	var total_time := float(CATALOGO_UNIDADES.get(current_id, {}).get("train_time", 6.0))
	if total_time <= 0.0:
		return 0.0
	var elapsed := total_time - production_timer.time_left
	return clampf(elapsed / total_time, 0.0, 1.0)

func get_queue_count() -> int:
	return production_queue.size()

# ─── 3. Escucha de Señales de Era (Swap de Mallas) ───────────────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return
	# Invocar el manejador base con los 3 Variant explícitos (evita bug de parseo GDScript 4.3)
	super._on_era_evolucionada(player_id, nueva_era)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	var cuartel_prehist := get_node_or_null("CuartelPrehistorico")
	if not is_instance_valid(cuartel_prehist):
		var glb_res := "res://IMAGENES/EDAD PREHISTORICA/CASAS DE CONSTRUIR/cuartel prehistorico.glb"
		if ResourceLoader.exists(glb_res):
			var pscene := load(glb_res) as PackedScene
			if is_instance_valid(pscene):
				cuartel_prehist = pscene.instantiate()
				cuartel_prehist.name = "CuartelPrehistorico"
				cuartel_prehist.scale = Vector3(3.8, 3.8, 3.8)
				add_child(cuartel_prehist)

	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1: # Prehistórica y Piedra
			if is_instance_valid(cuartel_prehist):
				cuartel_prehist.visible = true
			_activar_mesh_por_nombre("EraMesh_PrimitiveCamp")
			building_name = "Cuartel Prehistórico"
		2, 3: # Bronce y Hierro
			if is_instance_valid(cuartel_prehist):
				cuartel_prehist.visible = false
			_activar_mesh_por_nombre("EraMesh_BronzeArmory")
			building_name = "Cuartel y Armería de Bronce/Hierro"
		4, 5: # Medieval y Renacimiento
			if is_instance_valid(cuartel_prehist):
				cuartel_prehist.visible = false
			_activar_mesh_por_nombre("EraMesh_StoneFortress")
			building_name = "Fuerte de Piedra y Torrecilla"
		6, 7: # Industrial y Atómica
			if is_instance_valid(cuartel_prehist):
				cuartel_prehist.visible = false
			_activar_mesh_por_nombre("EraMesh_ConcreteBunker")
			building_name = "Búnker Militar de Hormigón Armado"
		8, 9: # Digital y Nano-Futurista
			if is_instance_valid(cuartel_prehist):
				cuartel_prehist.visible = false
			_activar_mesh_por_nombre("EraMesh_EnergyShieldBarracks")
			building_name = "Complejo Táctico de Escudos de Energía"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
