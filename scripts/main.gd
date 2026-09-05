## Main — Controlador principal de input del jugador.
##
## Gestiona todos los comandos RTS:
##   Click izquierdo    → selección individual de unidad / deseleccionar
##   Arrastre izquierdo → SelectionBox (gestionado en selection_box.gd)
##   Click derecho      → comando contextual (mover / atacar / recolectar / reparar)
##   Ctrl + 0-9         → assign_control_group(N)
##   0-9                → recall_control_group(N)
##   S                  → detener unidades seleccionadas
##   Delete             → eliminar unidades seleccionadas (debug)
##
## La lógica de detección usa el canvas_transform del viewport para convertir
## coordenadas de pantalla a mundo correctamente con cualquier zoom de cámara.

extends Node2D

# ─── Constantes ────────────────────────────────────────────────────────────────
## Radio de detección de click sobre una unidad/edificio/recurso (en px pantalla).
const CLICK_DETECT_RADIUS_PX: float = 22.0
## Distancia mínima de arrastre para NO considerar el soltar como click simple.
const SINGLE_CLICK_THRESHOLD: float = 6.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _left_press_pos: Vector2 = Vector2.ZERO

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	# ── Teclado ────────────────────────────────────────────────────────────────
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_keyboard(event as InputEventKey):
			get_viewport().set_input_as_handled()
		return

	# ── Mouse ──────────────────────────────────────────────────────────────────
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_left_press_pos = mb.position
			else:
				# Solo actuar como click si el movimiento fue menor al umbral
				if mb.position.distance_to(_left_press_pos) < SINGLE_CLICK_THRESHOLD:
					_handle_left_click(mb.position)
					get_viewport().set_input_as_handled()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_right_click(mb.position)
			get_viewport().set_input_as_handled()

# ─── Click Izquierdo — Selección Individual ────────────────────────────────────

func _get_sm() -> Node:
	return get_node_or_null("/root/SelectionManager")

func _handle_left_click(screen_pos: Vector2) -> void:
	var world_pos := _to_world(screen_pos)
	var unit := _find_nearest_in_group("units", world_pos)
	var sm := _get_sm()

	if not is_instance_valid(unit):
		# Click en vacío → deseleccionar todo
		if is_instance_valid(sm):
			sm.deselect_all()
		return

	if is_instance_valid(sm):
		if Input.is_key_pressed(KEY_SHIFT):
			sm.add_units_to_selection([unit])
		else:
			sm.select_units([unit])

# ─── Click Derecho — Comando Contextual ────────────────────────────────────────

func _handle_right_click(screen_pos: Vector2) -> void:
	var sm := _get_sm()
	if not is_instance_valid(sm) or sm.selected_units.is_empty():
		return

	var world_pos := _to_world(screen_pos)

	# ── Prioridad 1: Atacar enemigo ────────────────────────────────────────────
	var enemy := _find_nearest_in_group("enemies", world_pos)
	if is_instance_valid(enemy):
		for unit in sm.selected_units:
			if is_instance_valid(unit) and unit.has_method("command_attack"):
				unit.command_attack(enemy)
		return

	# ── Prioridad 2: Recolectar recurso (solo unidades con command_gather) ─────
	var resource := _find_nearest_in_group("resources", world_pos)
	if is_instance_valid(resource):
		var gatherers_found := false
		for unit in sm.selected_units:
			if is_instance_valid(unit) and unit.has_method("command_gather"):
				unit.command_gather(resource)
				gatherers_found = true
		# Si había al menos un recolector, no mover al resto
		if gatherers_found:
			return

	# ── Prioridad 3: Reparar edificio dañado (solo unidades con command_repair) ─
	var building := _find_nearest_in_group("buildings", world_pos)
	if is_instance_valid(building) and "hp" in building and "max_hp" in building:
		if (building as Node).get("hp") < (building as Node).get("max_hp"):
			var repairers_found := false
			for unit in sm.selected_units:
				if is_instance_valid(unit) and unit.has_method("command_repair"):
					unit.command_repair(building)
					repairers_found = true
			if repairers_found:
				return

	# ── Default: Mover a posición en formación de rejilla ─────────────────────
	_command_move_formation(world_pos)

# ─── Atajos de Teclado ─────────────────────────────────────────────────────────

func _handle_keyboard(event: InputEventKey) -> bool:
	var sm := _get_sm()
	# Grupos de control: Ctrl+0-9 asigna / 0-9 recupera
	const NUMBER_KEYS: Array[int] = [
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4,
		KEY_5, KEY_6, KEY_7, KEY_8, KEY_9
	]
	for i in NUMBER_KEYS.size():
		if event.keycode == NUMBER_KEYS[i]:
			if is_instance_valid(sm):
				if event.ctrl_pressed:
					sm.assign_control_group(i)
				else:
					sm.recall_control_group(i)
			return true

	# S → Detener unidades seleccionadas
	if event.keycode == KEY_S and not event.ctrl_pressed:
		if is_instance_valid(sm):
			for unit in sm.selected_units:
				if is_instance_valid(unit) and unit.has_method("command_stop"):
					unit.command_stop()
		return true

	# B → Entrar en modo construcción (Edificio Base)
	if event.keycode == KEY_B and not event.ctrl_pressed:
		_enter_build_mode("res://scenes/buildings/building_base.tscn", {"wood": 50})
		return true

	return false

# ─── Modo Construcción ─────────────────────────────────────────────────────────

func _enter_build_mode(scene_path: String, cost: Dictionary) -> void:
	# Si ya hay un fantasma, eliminarlo primero
	var existing = get_node_or_null("BuildingGhost")
	if existing:
		existing.queue_free()
		
	var ghost := BuildingGhost.new()
	ghost.name = "BuildingGhost"
	ghost.building_scene = load(scene_path)
	ghost.cost = cost
	ghost.placed.connect(_on_building_placed)
	add_child(ghost)

func _on_building_placed(pos: Vector2) -> void:
	# Podríamos ordenar automáticamente a los aldeanos seleccionados que vayan a reparar/construir
	pass

# ─── Formación en Rejilla ─────────────────────────────────────────────────────

## Distribuye las unidades en una rejilla centrada en target_pos para evitar que
## se apilen unas sobre otras al recibir la misma orden de movimiento.
func _command_move_formation(target_pos: Vector2) -> void:
	var sm := _get_sm()
	if not is_instance_valid(sm):
		return
	var units: Array = sm.selected_units
	var count  := units.size()
	if count == 0:
		return
	var cols    := ceili(sqrt(float(count)))
	var spacing := 42.0
	for i in count:
		var unit = units[i]
		if not is_instance_valid(unit) or not unit.has_method("command_move"):
			continue
		var row    := i / cols
		var col    := i % cols
		var rows   := ceili(float(count) / float(cols))
		var offset := Vector2(
			(col - (cols - 1) * 0.5) * spacing,
			(row - (rows - 1) * 0.5) * spacing
		)
		unit.command_move(target_pos + offset)

# ─── Utilidades de Detección en Escena ────────────────────────────────────────

## Retorna el Node2D del grupo más cercano a world_pos dentro del radio de detección.
func _find_nearest_in_group(group_name: String, world_pos: Vector2) -> Node:
	var best_node: Node  = null
	var best_dist: float = CLICK_DETECT_RADIUS_PX / zoom_at_camera()
	for node in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		var dist: float = (node as Node2D).global_position.distance_to(world_pos)
		if dist < best_dist:
			best_dist = dist
			best_node = node
	return best_node

## Convierte coordenadas de pantalla a coordenadas del mundo usando la
## transformación del canvas (tiene en cuenta cámara y zoom).
func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

## Retorna el zoom actual de la cámara activa (para escalar el radio de detección).
func zoom_at_camera() -> float:
	var cam := get_viewport().get_camera_2d()
	if cam:
		return cam.zoom.x
	return 1.0
