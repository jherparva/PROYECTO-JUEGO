## Dock3D — Astillero / Puerto Marítimo 3D (GDScript 2.0 / Godot 4).
##
## Edificio de producción naval y punto de entrega costero para madera, comida, piedra, oro e hierro.
## Administra la cola de construcción de barcos pesqueros, transportes y navíos de guerra en 9 Eras.

class_name Dock3D
extends "res://scripts/buildings/building_base_3d.gd"

signal ship_queued(ship_id: String, queue_size: int)
signal naval_queue_updated(progress: float, current_ship_id: String)
signal ship_spawned(ship_instance: Node3D)
signal resources_deposited(resource_type: String, amount: int)

# ─── Catálogo de Embarcaciones por Eras ───────────────────────────────────────
const NAVAL_CATALOG: Dictionary = {
	"barco_pesquero": {
		"name": "Barco Pesquero Autónomo",
		"type": "economic",
		"cost": {"wood": 100},
		"train_time": 6.0,
		"era_min": 0,
		"scene_path": "res://scenes/units/villager_3d.tscn" # Escena base adaptable
	},
	"transporte_naval": {
		"name": "Galería de Transporte Naval",
		"type": "transport",
		"cost": {"wood": 150, "gold": 100},
		"train_time": 10.0,
		"era_min": 2,
		"scene_path": "res://scenes/units/soldier_3d.tscn"
	},
	"galeon_guerra": {
		"name": "Acorazado / Navío de Guerra",
		"type": "military",
		"cost": {"wood": 200, "iron": 150, "gold": 150},
		"train_time": 14.0,
		"era_min": 4,
		"scene_path": "res://scenes/units/archer_3d.tscn"
	}
}

# ─── Configuración de Producción Naval ─────────────────────────────────────────
@export var MAX_QUEUE_SIZE: int = 5
@export var water_spawn_offset: Vector3 = Vector3(0.0, -0.5, 6.0)

var naval_queue: Array[String] = []
var naval_timer: Timer = null
var water_rally_point: Vector3 = Vector3.ZERO
var _spawn_counter: int = 0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Astillero Marítimo"
	salud_maxima = 900.0
	salud_actual = 900.0
	_setup_drop_off_point()

func _ready() -> void:
	super._ready()
	add_to_group("docks")
	add_to_group("docks_3d")
	add_to_group("town_centers")
	add_to_group("settlements")
	add_to_group("drop_off_buildings")
	add_to_group("drop_off_depots")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	water_rally_point = global_position + water_spawn_offset

	_setup_drop_off_point()

	# Crear Timer de producción naval
	naval_timer = get_node_or_null("NavalTimer") as Timer
	if not is_instance_valid(naval_timer):
		naval_timer = Timer.new()
		naval_timer.name = "NavalTimer"
		naval_timer.one_shot = true
		naval_timer.autostart = false
		add_child(naval_timer)

	if not naval_timer.timeout.is_connected(_on_naval_timer_timeout):
		naval_timer.timeout.connect(_on_naval_timer_timeout)

	# Escuchar cambio de era para swap visual
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _setup_drop_off_point() -> void:
	var drop_off_point := get_node_or_null("DropOffPoint") as Area3D
	if not is_instance_valid(drop_off_point):
		drop_off_point = Area3D.new()
		drop_off_point.name = "DropOffPoint"
		var col := CollisionShape3D.new()
		col.name = "DropOffShape"
		var box := BoxShape3D.new()
		box.size = Vector3(8.0, 4.0, 8.0)
		col.shape = box
		drop_off_point.add_child(col)
		add_child(drop_off_point)
		drop_off_point.position = water_spawn_offset

	if not drop_off_point.body_entered.is_connected(_on_drop_off_body_entered):
		drop_off_point.body_entered.connect(_on_drop_off_body_entered)
	if not drop_off_point.area_entered.is_connected(_on_drop_off_area_entered):
		drop_off_point.area_entered.connect(_on_drop_off_area_entered)

func _on_drop_off_body_entered(body: Node) -> void:
	_handle_boat_dropoff(body)

func _on_drop_off_area_entered(area: Area3D) -> void:
	_handle_boat_dropoff(area.get_parent())

func _handle_boat_dropoff(node: Node) -> void:
	if not is_instance_valid(node) or is_dead or is_under_construction:
		return
	if node is FishingBoat3D or node.is_in_group("fishing_boats") or "current_cargo" in node:
		var cargo: int = int(node.get("current_cargo"))
		if cargo > 0:
			deposit_resources("food", cargo, node)
			node.set("current_cargo", 0)
			if node.has_signal("cargo_changed"):
				var max_c: int = int(node.get("MAX_CARGA")) if "MAX_CARGA" in node else 20
				node.cargo_changed.emit(0, max_c)
			if node.has_method("set_status_text"):
				node.call("set_status_text", "+%d Food" % cargo, 2.5)
			print("Dock3D '%s': Entrega síncrona recibida de %s: +%d Food" % [name, node.name, cargo])

func _process(_delta: float) -> void:
	if not is_instance_valid(naval_timer) or naval_timer.is_stopped() or naval_queue.is_empty():
		return

	var current_id := naval_queue[0]
	var total_time := float(NAVAL_CATALOG.get(current_id, {}).get("train_time", 8.0))
	var elapsed := total_time - naval_timer.time_left
	var progress := clampf(elapsed / total_time, 0.0, 1.0)
	naval_queue_updated.emit(progress, current_id)

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

# ─── API de Depósito de Recursos (Costero) ────────────────────────────────────

func deposit_resources(resource_type: String, amount: int, depositor: Node = null) -> void:
	if is_dead or is_under_construction or amount <= 0:
		return

	if bando == Bando.PLAYER:
		var rm: Node = _get_resource_manager()
		if is_instance_valid(rm) and rm.has_method("add_resources"):
			rm.add_resources(resource_type, amount)
		elif is_instance_valid(rm) and "resources" in rm:
			var cur: int = int(rm.resources.get(resource_type, 0))
			rm.resources[resource_type] = cur + amount
			if rm.has_signal("recursos_actualizados"):
				rm.recursos_actualizados.emit(rm.resources)
	else:
		var enemy_ais := get_tree().get_nodes_in_group("enemy_ai")
		for ai in enemy_ais:
			if is_instance_valid(ai) and ai.has_method("agregar_recursos_ia"):
				ai.agregar_recursos_ia(resource_type, amount)

	resources_deposited.emit(resource_type, amount)

	var target_label_node := depositor if is_instance_valid(depositor) else self
	if target_label_node.has_method("set_status_text"):
		target_label_node.call("set_status_text", "+%d %s" % [amount, resource_type.capitalize()], 2.5)

# ─── Producción Naval y Reembolso ─────────────────────────────────────────────

func construir_barco(ship_id: String) -> bool:
	if is_under_construction or is_dead or naval_queue.size() >= MAX_QUEUE_SIZE:
		return false

	if not NAVAL_CATALOG.has(ship_id):
		return false

	var ship_info: Dictionary = NAVAL_CATALOG[ship_id]
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
		print("Dock3D: " + msg)
		return false


	var cost: Dictionary = ship_info.get("cost", {})
	if rm.has_method("gastar_recursos") and not rm.gastar_recursos(cost):
		print("Dock3D: Recursos insuficientes para embarcación '%s'." % ship_info["name"])
		return false

	if rm.has_method("change_current_population"):
		rm.change_current_population(1)

	naval_queue.append(ship_id)
	ship_queued.emit(ship_id, naval_queue.size())

	if naval_queue.size() == 1:
		_procesar_siguiente_barco()

	print("Dock3D: Embarcación '%s' añadida a la cola naval (%d/5)." % [ship_info["name"], naval_queue.size()])
	return true

func _procesar_siguiente_barco() -> void:
	if not is_instance_valid(naval_timer):
		return

	if naval_queue.is_empty():
		naval_timer.stop()
		return

	var current_id := naval_queue[0]
	var train_time := float(NAVAL_CATALOG.get(current_id, {}).get("train_time", 8.0))
	naval_timer.start(train_time)

func _on_naval_timer_timeout() -> void:
	if naval_queue.is_empty():
		return

	var completed_id: String = str(naval_queue.pop_front())
	var ship_info: Dictionary = NAVAL_CATALOG.get(completed_id, {})
	_spawn_ship(ship_info)

	_procesar_siguiente_barco()

func cancelar_construccion_barco(index: int) -> bool:
	if index < 0 or index >= naval_queue.size():
		return false

	var canceled_id: String = str(naval_queue[index])
	naval_queue.remove_at(index)

	var ship_info: Dictionary = NAVAL_CATALOG.get(canceled_id, {})
	var cost: Dictionary = ship_info.get("cost", {})

	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm):
		if rm.has_method("add_resources"):
			for rk in cost:
				rm.add_resources(rk, int(cost[rk]))
		if rm.has_method("change_current_population"):
			rm.change_current_population(-1)

	if index == 0:
		_procesar_siguiente_barco()

	print("Dock3D: Embarcación '%s' cancelada. Recursos devueltos." % ship_info.get("name", canceled_id))
	return true

# ─── Spawn e Instanciación en Agua ─────────────────────────────────────────────

func _spawn_ship(ship_info: Dictionary) -> void:
	var path: String = ship_info.get("scene_path", "res://scenes/units/soldier_3d.tscn")
	var scene := load(path) as PackedScene
	if not is_instance_valid(scene):
		return

	var inst: Node3D = scene.instantiate() as Node3D
	var spawn_pos := global_position + water_spawn_offset

	var parent: Node = get_tree().current_scene.get_node_or_null("World/Ships")
	if not parent:
		parent = get_tree().current_scene.get_node_or_null("World/Units")
	if not parent:
		parent = get_tree().current_scene

	parent.add_child(inst)
	inst.global_position = spawn_pos
	inst.add_to_group("ships")
	inst.add_to_group("ships_3d")
	inst.add_to_group("units_3d")

	if bando == Bando.PLAYER:
		inst.add_to_group("player_units")
	else:
		inst.add_to_group("enemy_units")

	if "bando" in inst:
		inst.set("bando", bando)

	if water_rally_point != Vector3.ZERO and inst.has_method("command_move"):
		inst.command_move(water_rally_point)

	ship_spawned.emit(inst)

# ─── Evolución Estética por Era (Visual Mesh Swap Eras 0 a 9) ─────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return
	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1: # Prehistórica y Piedra
			_activar_mesh_por_nombre("EraMesh_PrimitiveDock")
			building_name = "Muelle de Troncos y Balsas"
		2, 3: # Bronce y Hierro
			_activar_mesh_por_nombre("EraMesh_WoodenHarbor")
			building_name = "Puerto de Madera y Galeras"
		4, 5: # Medieval y Renacimiento
			_activar_mesh_por_nombre("EraMesh_CaravelDock")
			building_name = "Astillero de Carabelas y Galeones"
		6, 7: # Industrial y Atómica
			_activar_mesh_por_nombre("EraMesh_SteelShipyard")
			building_name = "Astillero Siderúrgico de Acorazados"
		8, 9: # Digital y Nano-Futurista
			_activar_mesh_por_nombre("EraMesh_QuantumNavalBase")
			building_name = "Base Naval Fotónica / Nanotécnica"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
