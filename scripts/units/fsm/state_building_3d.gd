## StateBuilding3D — Estado de Construcción y Reparación 3D (GDScript 2.0 / Godot 4).
##
## Controla el comportamiento del aldeano al construir y reparar:
## 1. Navega hacia los límites físicos del edificio usando NavigationAgent3D.
## 2. Al llegar al rango cercano, activa el prop "Maza_Piedra" en su 'RightHandAttachment'.
## 3. Si el edificio no está terminado, incrementa `progreso_construccion` en ticks.
##    Si el edificio está dañado pero terminado, repara su salud (`salud_actual`).
## 4. Al finalizar la obra (100% o reparación total), busca automáticamente otras
##    obras o reparaciones aliadas en un radio de 18 metros sin requerir microgestión.

class_name StateBuilding3D
extends StateBase3D

# ─── Exports y Configuración ───────────────────────────────────────────────────
@export var build_range: float = 3.5
@export var progress_per_second: float = 5.0 # +5% de avance por segundo

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target_building: BuildingBase3D = null
var _build_timer: float = 0.0
var _has_equipped_hammer: bool = false

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	state_name = &"Building"

func _get_pos(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	return node.position

func enter(context: Dictionary = {}) -> void:
	_build_timer = 0.0
	_has_equipped_hammer = false
	var raw_bld = context.get("target_node", null)
	_target_building = raw_bld as BuildingBase3D if is_instance_valid(raw_bld) else null

	if not is_instance_valid(_target_building):
		state_machine.change_state(&"Idle")
		return

	# Si ya está completamente construido Y tiene la salud al 100%, nada que reparar
	if _target_building.esta_construido and _target_building.salud_actual >= _target_building.salud_maxima:
		state_machine.change_state(&"Idle")
		return

	# Si está fuera del rango cercano, cambiar a Move con parada adaptable
	var max_range := _get_effective_build_range()
	var dist := _get_pos(unit).distance_to(_get_pos(_target_building))
	if dist > max_range:
		state_machine.change_state(&"Move", {
			"target_node": _target_building,
			"stopping_distance": _get_building_extent() + 1.2,
			"on_arrival_state": &"Building",
			"on_arrival_context": {"target_node": _target_building}
		})
		return

	_start_building_visuals()

func physics_update(delta: float) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(_target_building):
		state_machine.change_state(&"Idle")
		return

	# Si el edificio ya completó el 100% de construcción o reparación
	if _target_building.esta_construido and _target_building.salud_actual >= _target_building.salud_maxima:
		_finish_building()
		return

	# Verificar si se alejó del edificio (con margen de tolerancia)
	var max_range := _get_effective_build_range()
	var dist := _get_pos(unit).distance_to(_get_pos(_target_building))
	if dist > max_range + 0.8:
		state_machine.change_state(&"Move", {
			"target_node": _target_building,
			"stopping_distance": _get_building_extent() + 1.2,
			"on_arrival_state": &"Building",
			"on_arrival_context": {"target_node": _target_building}
		})
		return

	# Detener movimiento y orientar al aldeano hacia el edificio
	unit.velocity = Vector3.ZERO
	var dir_to_bld := (_get_pos(_target_building) - _get_pos(unit))
	unit.rotate_towards_direction(dir_to_bld, delta)

	# Ticks de avance en la construcción o reparación
	_build_timer += delta
	if _build_timer >= 1.0:
		_build_timer = 0.0
		_perform_build_tick()

func _get_building_extent() -> float:
	if not is_instance_valid(_target_building):
		return 2.5
	var base_extent: float = 2.5
	var col: CollisionShape3D = _target_building.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col and col.shape:
		if col.shape is BoxShape3D:
			var box: BoxShape3D = col.shape as BoxShape3D
			base_extent = maxf(box.size.x, box.size.z) * 0.5
		elif col.shape is CylinderShape3D:
			base_extent = (col.shape as CylinderShape3D).radius
		elif col.shape is SphereShape3D:
			base_extent = (col.shape as SphereShape3D).radius
	elif _target_building is TownCenter3D or _target_building.is_in_group("town_centers"):
		base_extent = 4.0
	elif _target_building.is_in_group("farms") or _target_building.is_in_group("temples"):
		base_extent = 3.5
	return base_extent

func _get_effective_build_range() -> float:
	var extent := _get_building_extent()
	return maxf(extent + 3.5, 6.5)

func exit() -> void:
	_build_timer = 0.0
	_target_building = null
	if unit:
		unit.set_hand_prop("")
		if unit is Villager3D:
			(unit as Villager3D).set_gathering_animation(false)

# ─── Comportamiento Interno ────────────────────────────────────────────────────

func _start_building_visuals() -> void:
	if not is_instance_valid(unit):
		return

	# Activar prop y animación de martilleo/construcción
	unit.set_hand_prop("Maza_Piedra")
	if unit is Villager3D:
		(unit as Villager3D).set_gathering_animation(true)

	if unit.has_method("set_status_text") and is_instance_valid(_target_building):
		if not _target_building.esta_construido:
			unit.set_status_text("🔨 Construyendo (%d%%)..." % int(_target_building.progreso_construccion))
		else:
			unit.set_status_text("🔧 Reparando (%d/%d HP)..." % [int(_target_building.salud_actual), int(_target_building.salud_maxima)])

const GameSettingsClass = preload("res://scripts/core/game_settings.gd")

func _get_game_speed_modifier() -> float:
	return GameSettingsClass.get_game_speed_mod()

func get_build_rate() -> float:
	return 10.0 * _get_game_speed_modifier()

func get_repair_rate() -> float:
	return 15.0 * _get_game_speed_modifier()

func _perform_build_tick() -> void:
	if not is_instance_valid(_target_building):
		state_machine.change_state(&"Idle")
		return

	if not _target_building.esta_construido:
		# Construcción de nueva estructura (+10% por tick escalado por speed_modifier)
		var prog_rate := get_build_rate()
		if _target_building.has_method("aplicar_progreso_construccion"):
			_target_building.aplicar_progreso_construccion(prog_rate)
		elif _target_building.has_method("repair"):
			_target_building.repair(prog_rate)

		if unit.has_method("set_status_text") and is_instance_valid(_target_building):
			unit.set_status_text("🔨 Construyendo (%d%%)..." % int(_target_building.progreso_construccion))
	else:
		# Reparación de estructura completada dañada (+15 HP por tick escalado por speed_modifier)
		var rep_rate := get_repair_rate()
		if _target_building.has_method("repair"):
			_target_building.repair(rep_rate)
		else:
			_target_building.salud_actual = minf(_target_building.salud_maxima, _target_building.salud_actual + rep_rate)
			_target_building.hp_changed.emit(_target_building.salud_actual, _target_building.salud_maxima)

		if unit.has_method("set_status_text") and is_instance_valid(_target_building):
			unit.set_status_text("🔧 Reparando (%d/%d HP)..." % [int(_target_building.salud_actual), int(_target_building.salud_maxima)])

	# Verificar si ya finalizó tras aplicar el tick
	if _target_building.esta_construido and _target_building.salud_actual >= _target_building.salud_maxima:
		_finish_building()

func _finish_building() -> void:
	if is_instance_valid(unit):
		unit.set_hand_prop("")
		if unit is Villager3D:
			(unit as Villager3D).set_gathering_animation(false)
		if unit.has_method("set_status_text"):
			unit.set_status_text("✅ ¡Completado!", 2.5)

	# Asistencia automática a obras/reparaciones cercanas en un radio de 18 metros
	var next_work := _find_nearby_construction_or_repair(18.0)
	if is_instance_valid(next_work) and unit.has_method("command_build"):
		unit.command_build(next_work)
		return

	state_machine.change_state(&"Idle")

func _find_nearby_construction_or_repair(max_distance: float = 18.0) -> BuildingBase3D:
	if not is_instance_valid(unit):
		return null

	var my_bando: int = int(unit.get("bando")) if "bando" in unit else 0
	var tree := get_tree_safe()

	var candidates: Array[Node] = []
	if is_instance_valid(tree):
		candidates.append_array(tree.get_nodes_in_group("player_buildings") if my_bando == 0 else tree.get_nodes_in_group("enemy_buildings"))
		candidates.append_array(tree.get_nodes_in_group("buildings_3d"))

	# Respaldo si los grupos no están indexados (por ejemplo en tests de scene tree no activo)
	if candidates.is_empty():
		var parent_node: Node = null
		if is_instance_valid(unit) and is_instance_valid(unit.get_parent()):
			parent_node = unit.get_parent()
		elif is_instance_valid(tree) and is_instance_valid(tree.root):
			parent_node = tree.root
		if is_instance_valid(parent_node):
			for child in parent_node.get_children():
				if child is BuildingBase3D or child.is_in_group("player_buildings") or child.is_in_group("buildings_3d"):
					candidates.append(child)

	var best_bld: BuildingBase3D = null
	var min_dist := max_distance
	var unit_pos := _get_pos(unit)

	for bld in candidates:
		if not is_instance_valid(bld) or not (bld is BuildingBase3D) or bld == _target_building:
			continue

		var b := bld as BuildingBase3D
		if b.is_dead:
			continue

		var b_bando: int = int(b.bando) if "bando" in b else 0
		if b_bando != my_bando:
			continue

		# Debe necesitar construcción o reparación
		var needs_work: bool = (not b.esta_construido) or (b.salud_actual < b.salud_maxima)
		if not needs_work:
			continue

		var d := unit_pos.distance_to(_get_pos(b))
		if d <= min_dist:
			min_dist = d
			best_bld = b

	return best_bld
