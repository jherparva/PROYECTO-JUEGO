## ArcheryRange3D — Campo de Tiro de Proyectiles y Balística 3D (GDScript 2.0 / Godot 4).
##
## Edificación militar desbloqueada en la Edad de Piedra (Era 1+):
## - Permite el entrenamiento síncrono del Lanzador de Piedras y el Bowman de Era 1.
## - Bloquea la producción de tropas futuristas o no disponibles según 'dbtechtree.dat'.
## - Gestiona la cola de producción militar, el punto de reunión (rally point) y población.

class_name ArcheryRange3D
extends "res://scripts/buildings/barracks_3d.gd"

signal unit_trained(unit: Node3D)
signal queue_updated(queue_size: int)

# ─── Catálogo de Unidades por Era (dbtechtree.dat) ───────────────────────────
const UNIT_CATALOG: Dictionary = {
	"lanzador_piedras": {
		"name": "Lanzador de Piedras",
		"cost": {"food": 30, "wood": 20},
		"train_time": 4.0,
		"era_min": 1,
		"era_max": 2,
		"unit_id": "lanzador_piedras"
	},
	"bowman_era1": {
		"name": "Arquero de Piedra",
		"cost": {"food": 40, "wood": 30},
		"train_time": 5.0,
		"era_min": 1,
		"era_max": 3,
		"unit_id": "bowman_era1"
	},
	"arquero_compuesto": {
		"name": "Arquero Compuesto de Cobre",
		"cost": {"food": 45, "wood": 35, "gold": 10},
		"train_time": 6.0,
		"era_min": 2,
		"era_max": 3,
		"unit_id": "arquero_compuesto"
	},
	"fusilero_polvora": {
		"name": "Fusilero de Chispa",
		"cost": {"food": 60, "wood": 40, "iron": 25},
		"train_time": 8.0,
		"era_min": 5,
		"era_max": 6,
		"unit_id": "fusilero_polvora"
	},
	"sniper_nano": {
		"name": "Francotirador Cuántico",
		"cost": {"food": 100, "gold": 120, "iron": 80},
		"train_time": 12.0,
		"era_min": 8,
		"era_max": 9,
		"unit_id": "sniper_nano"
	}
}

const MAX_QUEUE: int = 5

var training_queue: Array[Dictionary] = []
var training_timer: float = 0.0
var era_desbloqueo: int = 1

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Campo de Tiro"
	salud_maxima = 500.0
	salud_actual = 500.0

func _ready() -> void:
	super._ready()
	add_to_group("archery_ranges")
	add_to_group("military_buildings")
	add_to_group("player_buildings" if bando == Bando.PLAYER else "enemy_buildings")

	rally_point = global_position + Vector3(4.0, 0.0, 4.0)

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _process(delta: float) -> void:
	if is_dead or is_under_construction:
		return

	if training_queue.is_empty():
		training_timer = 0.0
		return

	training_timer += delta
	var current_order: Dictionary = training_queue[0]
	var required_time := float(current_order.get("train_time", 4.0))

	if training_timer >= required_time:
		training_timer = 0.0
		var completed: Dictionary = training_queue.pop_front()
		_spawn_soldier(completed)
		queue_updated.emit(training_queue.size())

# ─── API de Entrenamiento Militar ──────────────────────────────────────────────

func entrenar_unidad(unit_key: String) -> bool:
	if is_dead or is_under_construction:
		return false

	if training_queue.size() >= MAX_QUEUE:
		print("ArcheryRange3D: Cola de entrenamiento llena (5/5).")
		return false

	if not UNIT_CATALOG.has(unit_key):
		print("ArcheryRange3D: Unidad '%s' no reconocida en catálogo balístico." % unit_key)
		return false

	var unit_info: Dictionary = UNIT_CATALOG[unit_key]
	var cur_era: int = _get_current_era()

	# Validación de Era 1+ y bloqueo de unidades de épocas futuras
	var min_era: int = int(unit_info.get("era_min", 1))
	var max_era: int = int(unit_info.get("era_max", 9))
	if cur_era < min_era or cur_era > max_era:
		print("ArcheryRange3D: dbtechtree.dat bloqueo: '%s' no disponible en Era %d (Requiere Era %d-%d)." % [
			unit_info["name"], cur_era, min_era, max_era
		])
		return false

	# Validación y consumo de población y recursos
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_method("has_population_room") and not rm.has_population_room(1):
			print("ArcheryRange3D: Límite de población alcanzado.")
			return false

		var cost: Dictionary = unit_info.get("cost", {})
		var success: bool = false
		if rm.has_method("gastar_recursos"):
			success = rm.gastar_recursos(cost)
		elif rm.has_method("spend_resources"):
			success = rm.spend_resources(cost)

		if not success:
			print("ArcheryRange3D: Recursos insuficientes para entrenar '%s'." % unit_info["name"])
			return false

		if rm.has_method("change_current_population"):
			rm.change_current_population(1)

	training_queue.append(unit_info)
	queue_updated.emit(training_queue.size())
	print("ArcheryRange3D: '%s' añadido a la cola (%d/%d)." % [unit_info["name"], training_queue.size(), MAX_QUEUE])
	return true

func entrenar_lanzador_piedras() -> bool:
	return entrenar_unidad("lanzador_piedras")

func entrenar_arquero_piedra() -> bool:
	return entrenar_unidad("bowman_era1")

func _spawn_soldier(order: Dictionary) -> void:
	var uid: String = str(order.get("unit_id", "lanzador_piedras"))
	var soldier := Soldier3D.new()
	soldier.name = order.get("name", "Soldier3D").replace(" ", "_")
	soldier.bando = UnitBase3D.Bando.PLAYER if bando == Bando.PLAYER else UnitBase3D.Bando.ENEMY

	var parent: Node = get_tree().current_scene.get_node_or_null("World/Units") if get_tree() and get_tree().current_scene else null
	if not parent and get_tree():
		parent = get_tree().current_scene
	if is_instance_valid(parent):
		parent.add_child(soldier)

	soldier.global_position = global_position + Vector3(3.5, 0.0, 3.5)
	soldier.configurar_unidad(uid)

	if rally_point_set and rally_point != Vector3.ZERO:
		soldier.command_move(rally_point)

	unit_trained.emit(soldier)
	print("ArcheryRange3D: '%s' entrenado y desplegado en el campo." % soldier.name)

func _get_current_era() -> int:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		return int(rm.era_actual)
	return 1 # Fallback por defecto a Era 1 (Piedra) si no hay singleton activo
