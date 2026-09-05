## SaveManager — Sistema de Guardar y Cargar Partida RTS 3D (GDScript 2.0 / Godot 4).
##
## Gestiona la serialización y deserialización completa del estado de la partida en JSON:
## - Economía y Recursos del Jugador.
## - Era tecnológica activa y multiplicadores.
## - Estado de la IA Enemiga y sus reservas económicas.
## - Unidades 3D activas (Aldeanos, Guerreros, Posición, HP, Bando, Carga).
## - Edificios 3D activos (Capitolios, Cuarteles, Chozas, HP, Bando, Progreso de Obra).
## - Nodos de recursos restantes en el mapa.

extends Node

static var instance: Node = null

const SAVE_DIR: String = "user://saves/"
const DEFAULT_SAVE_SLOT: String = "quick_save.json"

signal partida_guardada(slot_name: String)
signal partida_cargada(slot_name: String)

func _ready() -> void:
	instance = self
	process_mode = PROCESS_MODE_ALWAYS
	_ensure_save_directory_exists()

func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# ─── API Pública ───────────────────────────────────────────────────────────────

## Atajo para F5 (Guardado Rápido)
func quicksave() -> bool:
	return guardar_partida("quicksave.json")

## Atajo para F9 (Carga Rápida)
func quickload() -> bool:
	return cargar_partida("quicksave.json")

## Guarda la partida actual en el slot especificado.
func guardar_partida(slot_name: String = DEFAULT_SAVE_SLOT) -> bool:
	var save_data := _gather_save_data()
	var file_path := SAVE_DIR + slot_name
	var json_string := JSON.stringify(save_data, "  ")

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not is_instance_valid(file):
		push_error("SaveManager: No se pudo abrir el archivo para escribir en '%s'." % file_path)
		return false

	file.store_string(json_string)
	file.close()

	print("SaveManager: Partida guardada con éxito en '%s'." % file_path)
	partida_guardada.emit(slot_name)
	_notify_player("💾 Partida Guardada con Éxito (" + slot_name + ")")
	return true

## Carga la partida guardada desde el slot especificado.
func cargar_partida(slot_name: String = DEFAULT_SAVE_SLOT) -> bool:
	var file_path := SAVE_DIR + slot_name
	if not FileAccess.file_exists(file_path):
		push_warning("SaveManager: No existe el archivo de guardado en '%s'." % file_path)
		_notify_player("⚠️ No se encontró la partida guardada")
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not is_instance_valid(file):
		push_error("SaveManager: Error al abrir '%s'." % file_path)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("SaveManager: Error de parseo JSON en '%s' — %s" % [file_path, json.get_error_message()])
		return false

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		return false

	var success := _apply_save_data(data)
	if success:
		print("SaveManager: Partida '%s' cargada y restaurada con éxito." % slot_name)
		partida_cargada.emit(slot_name)
		_notify_player("📂 Partida Cargada con Éxito")
	return success

# ─── Recopilación de Datos (Serialización) ────────────────────────────────────

func _gather_save_data() -> Dictionary:
	var data := {}

	# 1. Metadata
	data["metadata"] = {
		"timestamp": Time.get_datetime_string_from_system(),
		"engine_version": "Godot 4.3 RTS 3D"
	}

	# 1.5. Estado del Lobby Multijugador Híbrido
	var mm: Node = get_node_or_null("/root/MultiplayerManager")
	if is_instance_valid(mm) and "lobby_slots" in mm:
		data["multiplayer_lobby_state"] = (mm.lobby_slots as Array).duplicate(true)

	# 1.6. Puntos de Civilización y Mejoras Tecnológicas
	var cpm: Node = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm):
		data["civ_upgrades"] = {
			"puntos_civ": int(cpm.get("puntos_civ")),
			"upgrade_levels": (cpm.get("upgrade_levels") as Dictionary).duplicate()
		}

	# 2. Economía y Era del Jugador
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		data["resources"] = rm.resources.duplicate() if "resources" in rm else {}
		data["era_actual"] = int(rm.era_actual) if "era_actual" in rm else 0
		data["current_population"] = int(rm.current_population) if "current_population" in rm else 0
		data["max_population"] = int(rm.max_population) if "max_population" in rm else 10

	# 3. Estado de la IA Enemiga
	var ai_node: Node = get_tree().get_first_node_in_group("enemy_ai") if get_tree() else null
	if is_instance_valid(ai_node) and "_recursos_ia" in ai_node:
		data["ai_resources"] = ai_node._recursos_ia.duplicate()

	# 4. Unidades 3D
	var units_array: Array[Dictionary] = []
	if get_tree():
		for unit in get_tree().get_nodes_in_group("units_3d"):
			if not is_instance_valid(unit) or not (unit is Node3D):
				continue
			var u_data := _serialize_unit(unit as Node3D)
			if not u_data.is_empty():
				units_array.append(u_data)
	data["units"] = units_array

	# 5. Edificios 3D
	var buildings_array: Array[Dictionary] = []
	if get_tree():
		for bld in get_tree().get_nodes_in_group("buildings_3d"):
			if not is_instance_valid(bld) or not (bld is Node3D):
				continue
			var b_data := _serialize_building(bld as Node3D)
			if not b_data.is_empty():
				buildings_array.append(b_data)
	data["buildings"] = buildings_array

	# 6. Nodos de Recursos
	var resources_array: Array[Dictionary] = []
	if get_tree():
		for res in get_tree().get_nodes_in_group("resources_3d"):
			if not is_instance_valid(res) or not (res is Node3D):
				continue
			var r_data := _serialize_resource_node(res as Node3D)
			if not r_data.is_empty():
				resources_array.append(r_data)
	data["resource_nodes"] = resources_array

	return data

func _serialize_unit(unit: Node3D) -> Dictionary:
	var scene_path := ""
	if unit is Villager3D:
		scene_path = "res://scenes/units/villager_3d.tscn"
	elif unit is Soldier3D:
		scene_path = "res://scenes/units/soldier_3d.tscn"
	else:
		scene_path = "res://scenes/units/villager_3d.tscn"

	var pos := unit.global_position
	var dict := {
		"scene_path": scene_path,
		"name": unit.name,
		"unit_name": unit.get("unit_name") if "unit_name" in unit else "Unidad",
		"bando": int(unit.get("bando")) if "bando" in unit else 0,
		"pos": [pos.x, pos.y, pos.z],
		"rot_y": unit.rotation.y,
		"salud_actual": float(unit.get("salud_actual")) if "salud_actual" in unit else 100.0,
		"salud_maxima": float(unit.get("salud_maxima")) if "salud_maxima" in unit else 100.0,
	}

	if unit is Villager3D:
		dict["carried_amount"] = (unit as Villager3D).carried_amount
		dict["carried_resource_type"] = (unit as Villager3D).carried_resource_type

	return dict

func _serialize_building(bld: Node3D) -> Dictionary:
	var scene_path := ""
	if bld is TownCenter3D:
		scene_path = "res://scenes/buildings/town_center_3d.tscn"
	elif bld is Barracks3D:
		scene_path = "res://scenes/buildings/barracks_3d.tscn"
	elif bld is Hut3D:
		scene_path = "res://scenes/buildings/hut_3d.tscn"
	elif bld is Settlement3D:
		scene_path = "res://scenes/buildings/settlement_3d.tscn"
	else:
		return {}

	var pos := bld.global_position
	var rally := Vector3.ZERO
	if "rally_point" in bld and bld.rally_point is Vector3:
		rally = bld.rally_point

	return {
		"scene_path": scene_path,
		"name": bld.name,
		"building_name": bld.get("building_name") if "building_name" in bld else "Edificio",
		"bando": int(bld.get("bando")) if "bando" in bld else 0,
		"pos": [pos.x, pos.y, pos.z],
		"salud_actual": float(bld.get("salud_actual")) if "salud_actual" in bld else 500.0,
		"salud_maxima": float(bld.get("salud_maxima")) if "salud_maxima" in bld else 500.0,
		"is_under_construction": bool(bld.get("is_under_construction")) if "is_under_construction" in bld else false,
		"progreso_construccion": float(bld.get("progreso_construccion")) if "progreso_construccion" in bld else 100.0,
		"rally": [rally.x, rally.y, rally.z]
	}

func _serialize_resource_node(res: Node3D) -> Dictionary:
	var pos := res.global_position
	var res_type := "wood"
	if res.has_method("get_resource_type"):
		res_type = res.get_resource_type()
	elif "resource_type" in res:
		res_type = str(res.resource_type)

	var cur_amt := int(res.get("current_amount")) if "current_amount" in res else 200

	return {
		"pos": [pos.x, pos.y, pos.z],
		"type": res_type,
		"current_amount": cur_amt
	}

# ─── Restauración de Datos (Deserialización) ───────────────────────────────────

func _apply_save_data(data: Dictionary) -> bool:
	if not get_tree() or not get_tree().current_scene:
		return false

	var root := get_tree().current_scene

	# 1. Limpiar unidades y edificios dinámicos existentes
	for u in get_tree().get_nodes_in_group("units_3d"):
		if is_instance_valid(u):
			u.queue_free()

	for b in get_tree().get_nodes_in_group("buildings_3d"):
		if is_instance_valid(b) and not b.is_in_group("town_centers"):
			b.queue_free()

	# 2. Restaurar Economía y Era
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if "resources" in rm and "resources" in data:
			rm.resources = (data["resources"] as Dictionary).duplicate()
		if "era_actual" in rm and "era_actual" in data:
			rm._aplicar_nueva_era(int(data["era_actual"]))
		if "current_population" in rm and "current_population" in data:
			rm.current_population = int(data["current_population"])
		if "max_population" in rm and "max_population" in data:
			rm.max_population = int(data["max_population"])
		if rm.has_method("emit_all_signals"):
			rm.emit_all_signals()

	# 3. Restaurar IA Enemiga
	var ai_node: Node = get_tree().get_first_node_in_group("enemy_ai")
	if is_instance_valid(ai_node) and "ai_resources" in data and "_recursos_ia" in ai_node:
		ai_node._recursos_ia = (data["ai_resources"] as Dictionary).duplicate()

	# 3.5. Restaurar Puntos de Civilización y Mejoras Compradas
	var cpm: Node = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm) and "civ_upgrades" in data and data["civ_upgrades"] is Dictionary:
		var c_data: Dictionary = data["civ_upgrades"] as Dictionary
		if "puntos_civ" in c_data:
			cpm.set("puntos_civ", int(c_data["puntos_civ"]))
		if "upgrade_levels" in c_data and c_data["upgrade_levels"] is Dictionary:
			cpm.set("upgrade_levels", (c_data["upgrade_levels"] as Dictionary).duplicate())
			for up_id in (c_data["upgrade_levels"] as Dictionary):
				var lvl: int = int((c_data["upgrade_levels"] as Dictionary)[up_id])
				if cpm.has_method("_aplicar_multiplicadores_globales"):
					cpm.call("_aplicar_multiplicadores_globales", up_id, lvl)

	# Contenedores de escena
	var units_container := root.get_node_or_null("World/Units")
	if not is_instance_valid(units_container):
		units_container = root.get_node_or_null("Units")
	if not is_instance_valid(units_container):
		units_container = root

	var bld_container := root.get_node_or_null("World/Buildings")
	if not is_instance_valid(bld_container):
		bld_container = root.get_node_or_null("Buildings")
	if not is_instance_valid(bld_container):
		bld_container = root

	# 4. Re-instanciar Edificios
	if "buildings" in data and data["buildings"] is Array:
		for b_dict: Dictionary in data["buildings"]:
			_instantiate_building_from_data(b_dict, bld_container)

	# 5. Re-instanciar Unidades
	if "units" in data and data["units"] is Array:
		for u_dict: Dictionary in data["units"]:
			_instantiate_unit_from_data(u_dict, units_container)

	return true

func _instantiate_building_from_data(dict: Dictionary, container: Node) -> void:
	var path: String = dict.get("scene_path", "")
	if path.is_empty():
		return
	var scene := load(path) as PackedScene
	if not is_instance_valid(scene):
		return

	var bld: Node3D = scene.instantiate() as Node3D
	container.add_child(bld)

	var p_arr: Array = dict.get("pos", [0, 0, 0])
	bld.global_position = Vector3(float(p_arr[0]), float(p_arr[1]), float(p_arr[2]))

	if "bando" in bld:
		bld.set("bando", int(dict.get("bando", 0)))
	if "salud_actual" in bld:
		bld.set("salud_actual", float(dict.get("salud_actual", 500.0)))
	if "salud_maxima" in bld:
		bld.set("salud_maxima", float(dict.get("salud_maxima", 500.0)))
	if "is_under_construction" in bld:
		bld.set("is_under_construction", bool(dict.get("is_under_construction", false)))
	if "progreso_construccion" in bld:
		bld.set("progreso_construccion", float(dict.get("progreso_construccion", 100.0)))

	bld.add_to_group("buildings")
	bld.add_to_group("buildings_3d")
	if int(dict.get("bando", 0)) == 0:
		bld.add_to_group("player_buildings")
	else:
		bld.add_to_group("enemy_buildings")

func _instantiate_unit_from_data(dict: Dictionary, container: Node) -> void:
	var path: String = dict.get("scene_path", "")
	if path.is_empty():
		return
	var scene := load(path) as PackedScene
	if not is_instance_valid(scene):
		return

	var unit: Node3D = scene.instantiate() as Node3D
	container.add_child(unit)

	var p_arr: Array = dict.get("pos", [0, 0, 0])
	unit.global_position = Vector3(float(p_arr[0]), float(p_arr[1]), float(p_arr[2]))
	unit.rotation.y = float(dict.get("rot_y", 0.0))

	if "bando" in unit:
		unit.set("bando", int(dict.get("bando", 0)))
	if "salud_actual" in unit:
		unit.set("salud_actual", float(dict.get("salud_actual", 100.0)))
	if "salud_maxima" in unit:
		unit.set("salud_maxima", float(dict.get("salud_maxima", 100.0)))

	if unit is Villager3D:
		(unit as Villager3D).carried_amount = int(dict.get("carried_amount", 0))
		(unit as Villager3D).carried_resource_type = str(dict.get("carried_resource_type", "wood"))

	unit.add_to_group("units")
	unit.add_to_group("units_3d")
	if int(dict.get("bando", 0)) == 0:
		unit.add_to_group("player_units")
	else:
		unit.add_to_group("enemy_units")

# ─── Helper de Notificaciones ──────────────────────────────────────────────────

func _notify_player(msg: String) -> void:
	var notif := get_tree().get_first_node_in_group("rts_notification_manager") if get_tree() else null
	if is_instance_valid(notif) and notif.has_method("agregar_notificacion"):
		notif.call("agregar_notificacion", msg, 0, Vector3.ZERO)
