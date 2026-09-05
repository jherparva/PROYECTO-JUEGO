## Temple3D — Templo místico / Centro Espiritual y Tecnológico 3D (GDScript 2.0 / Godot 4).
##
## Entrena a los Profetas (Sacerdotes), regenera el recurso de Fe (Mana/Faith) de forma pasiva
## e investiga tecnologías espirituales y de resistencia a la conversión.

class_name Temple3D
extends "res://scripts/buildings/building_base_3d.gd"

const CivPointsManager = preload("res://scripts/core/civ_points_manager.gd")

signal prophet_trained(prophet: Node3D)
signal faith_changed(current_faith: float, max_faith: float)

# ─── Sistema de Fe y Producción ────────────────────────────────────────────────
@export_group("Parámetros de Fe Espiritual")
@export var max_faith_points: float = 200.0
@export var faith_regen_rate: float = 5.0 # +5 de Fe por segundo por cada templo
@export var prophet_cost: Dictionary = {"food": 100, "gold": 80}
@export var prophet_train_time: float = 8.0

var current_faith_points: float = 200.0
var production_queue: Array[Dictionary] = []
var current_train_timer: float = 0.0
var _spawn_counter: int = 0

# ─── Guarecido de Aldeanos y Teocracia de Fe ──────────────────────────────────
const MAX_GARRISON: int = 5
var garrison_array: Array[Node3D] = []

## Guarece a un aldeano en el templo para rezar y acumular puntos de fe (+1/s)
func guarecer_aldeano(villager: Node3D) -> bool:
	if is_dead or not is_instance_valid(villager):
		return false
	if garrison_array.size() >= MAX_GARRISON:
		print("Temple3D '%s': Capacidad de rezo completa (%d/%d)." % [name, garrison_array.size(), MAX_GARRISON])
		return false
	if garrison_array.has(villager):
		return false

	garrison_array.append(villager)
	villager.visible = false
	if villager is CollisionObject3D:
		(villager as CollisionObject3D).set_collision_layer_value(1, false)
		(villager as CollisionObject3D).set_collision_mask_value(1, false)
	villager.process_mode = Node.PROCESS_MODE_DISABLED
	print("Temple3D '%s': Aldeano '%s' entró a rezar (%d/%d guarecidos)." % [name, villager.name, garrison_array.size(), MAX_GARRISON])
	return true

## Expulsa a todos los aldeanos guarecidos al exterior
func expulsar_aldeanos() -> Array[Node3D]:
	var ejected: Array[Node3D] = []
	for v in garrison_array:
		if is_instance_valid(v):
			v.visible = true
			if v is CollisionObject3D:
				(v as CollisionObject3D).set_collision_layer_value(1, true)
				(v as CollisionObject3D).set_collision_mask_value(1, true)
			v.process_mode = Node.PROCESS_MODE_INHERIT
			v.global_position = global_position + Vector3(randf_range(3.0, 5.0), 0.0, randf_range(3.0, 5.0))
			ejected.append(v)
	garrison_array.clear()
	return ejected

func get_garrison_count() -> int:
	return garrison_array.size()

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Templo Sagrado"
	salud_maxima = 750.0
	salud_actual = 750.0

func _ready() -> void:
	super._ready()
	add_to_group("temples")
	add_to_group("temples_3d")
	add_to_group("faith_generators")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	rally_point = global_position + Vector3(3.5, 0.0, 3.5)

	# Escuchar la señal global de eras
	if is_inside_tree() and get_tree():
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
			if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
				rm.era_evolucionada.connect(_on_era_evolucionada)

func _process(delta: float) -> void:
	if is_dead or is_under_construction:
		return

	# 1. Regeneración pasiva de Fe y acumulación por Aldeanos Rezando (+1/s por aldeano)
	var pray_count := garrison_array.size()
	if pray_count > 0:
		var fe_gain := float(pray_count) * delta
		current_faith_points = minf(max_faith_points, current_faith_points + fe_gain)
		var cpm: Node = null
		if CivPointsManager != null and is_instance_valid(CivPointsManager.instance):
			cpm = CivPointsManager.instance
		elif is_inside_tree() and get_tree():
			cpm = get_node_or_null("/root/CivPointsManager")

		if is_instance_valid(cpm) and cpm.has_method("agregar_fe"):
			cpm.call("agregar_fe", fe_gain)

	if current_faith_points < max_faith_points:
		current_faith_points = minf(max_faith_points, current_faith_points + faith_regen_rate * delta)
		faith_changed.emit(current_faith_points, max_faith_points)

	# 2. Cola de producción de Profetas
	if production_queue.is_empty():
		current_train_timer = 0.0
		return

	current_train_timer += delta
	var current_order: Dictionary = production_queue[0]
	var total_time := float(current_order.get("train_time", prophet_train_time))

	if current_train_timer >= total_time:
		current_train_timer = 0.0
		var completed: Dictionary = production_queue.pop_front()
		_spawn_prophet(completed)

# ─── API de Entrenamiento de Profetas ──────────────────────────────────────────

func entrenar_profeta() -> bool:
	if is_under_construction or is_dead or production_queue.size() >= 5:
		return false

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		return false

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
		print("Temple3D: " + msg)
		return false


	if rm.has_method("gastar_recursos") and not rm.gastar_recursos(prophet_cost):
		print("Temple3D: Recursos insuficientes para entrenar al Profeta.")
		return false

	if rm.has_method("change_current_population"):
		rm.change_current_population(1)

	production_queue.append({
		"unit_type": "prophet",
		"train_time": prophet_train_time
	})
	print("Temple3D: Entrenando Profeta (%d/5 en cola)." % production_queue.size())
	return true

func _spawn_prophet(_order: Dictionary) -> void:
	var path := "res://scenes/units/prophet_3d.tscn"
	var scene := load(path) as PackedScene
	var inst: Node3D = null

	if is_instance_valid(scene):
		inst = scene.instantiate() as Node3D
	else:
		var p := Prophet3D.new()
		p.name = "Prophet3D"
		inst = p

	var spawn_pos := global_position + Vector3(3.5, 0.0, 3.5)
	var parent: Node = get_tree().current_scene.get_node_or_null("World/Units")
	if not parent:
		parent = get_tree().current_scene

	parent.add_child(inst)
	inst.global_position = spawn_pos
	inst.add_to_group("units")
	inst.add_to_group("units_3d")
	inst.add_to_group("prophets")

	if bando == Bando.PLAYER:
		inst.add_to_group("player_units")
	else:
		inst.add_to_group("enemy_units")

	if "bando" in inst:
		inst.set("bando", bando)

	if rally_point_set and rally_point != Vector3.ZERO:
		if inst.has_method("command_move"):
			inst.command_move(rally_point)

	prophet_trained.emit(inst)

# ─── Consumo de Fe Global / Local ──────────────────────────────────────────────

func gastar_fe(cantidad: float) -> bool:
	if current_faith_points >= cantidad:
		current_faith_points -= cantidad
		faith_changed.emit(current_faith_points, max_faith_points)
		return true
	return false

# ─── Evolución Estética por Era (Eras 0 a 9) ───────────────────────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return

	max_faith_points = 200.0 + era_val * 50.0
	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1: # Prehistórica y Piedra
			_activar_mesh_por_nombre("EraMesh_PrehistoricAltar")
			building_name = "Altar de Sacrificios Tribal"
		2, 3: # Bronce y Hierro
			_activar_mesh_por_nombre("EraMesh_BronzeZiggurat")
			building_name = "Zigurat de Bronce / Hierro"
		4, 5: # Medieval y Renacimiento
			_activar_mesh_por_nombre("EraMesh_GothicCathedral")
			building_name = "Catedral de Piedra y Vitrales"
		6, 7: # Industrial y Atómica
			_activar_mesh_por_nombre("EraMesh_SpiritualSanctuary")
			building_name = "Santuario Neoclásico"
		8, 9: # Digital y Nano-Futurista
			_activar_mesh_por_nombre("EraMesh_NanoSpireTemple")
			building_name = "Espira Cuántica y Templo Futurista"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
