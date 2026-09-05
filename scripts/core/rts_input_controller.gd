## RTSInputController — Controlador Central de Órdenes y Raycast 3D (GDScript 2.0 / Godot 4).
##
## Soporta entradas de Ratón (PC) y Tácticas Multitoque (Android/iOS) de forma transparente.
## Cross-play nativo: un jugador móvil puede jugar en la misma sala que jugadores de PC.
##
## - Clic derecho (PC) / Hold 0.4s o Botón Flotante (Móvil) -> Despacha órdenes RTS.
## - Toque izquierdo (Móvil) -> Selecciona unidades vía raycast.
## - Enemigo -> Estado ATACANDO | Recurso -> RECOLECTANDO | Suelo -> MOVIENDOSE.

class_name RTSInputController
extends Node3D

const SaveManagerClass = preload("res://scripts/core/save_manager.gd")

# ─── Exports ───────────────────────────────────────────────────────────────────
@export var ray_length: float = 2000.0
@export_flags_3d_physics var collision_mask: int = 4294967295 # Todas las capas por defecto

# ─── Referencias ───────────────────────────────────────────────────────────────
@onready var camera: Camera3D = get_viewport().get_camera_3d() if is_instance_valid(get_viewport()) else null

# ─── Detección de Plataforma ───────────────────────────────────────────────────
var _is_mobile: bool = false

# ─── Estado de Entradas PC ─────────────────────────────────────────────────────
var _is_right_dragging: bool = false
var _right_press_screen: Vector2 = Vector2.ZERO
var _right_press_world: Vector3 = Vector3.ZERO
var _right_press_target: Node = null
var _arrow_indicator: Node3D = null
var _arrow_shaft: MeshInstance3D = null
var _arrow_head: MeshInstance3D = null

# ─── Estado de Entradas Táctiles (Móvil) ───────────────────────────────────────
const HOLD_ORDER_TIME: float = 0.4  # Segundos para activar la orden por presión larga
var _touch_hold_timer: float = 0.0
var _touch_holding: bool = false
var _touch_screen_pos: Vector2 = Vector2.ZERO
var _touch_finger_id: int = -1
var _modo_orden_activo: bool = false  # True cuando el botón flotante "Modo Orden" está activado

# Referencia al botón flotante de orden (inyectado opcionalmente desde la escena del HUD)
var _btn_modo_orden: Button = null
var target_tree: SceneTree = null

func _init() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_arrow_indicator()
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	if _is_mobile:
		_setup_mobile_overlay()
		print("RTSInputController: Plataforma MÓVIL detectada. Touch inputs habilitados.")
	else:
		print("RTSInputController: Plataforma PC detectada. Mouse inputs habilitados.")

func _get_active_tree() -> SceneTree:
	if is_instance_valid(target_tree):
		return target_tree
	var t: SceneTree = get_tree()
	if is_instance_valid(t):
		return t
	var ml = Engine.get_main_loop()
	if ml is SceneTree:
		return ml
	return null

func _find_pause_menu() -> Node:
	var tree := _get_active_tree()
	if not is_instance_valid(tree):
		return null
	var pm: Node = tree.get_first_node_in_group("pause_menu")
	if is_instance_valid(pm):
		return pm
	var root_node: Node = null
	if "root" in tree and is_instance_valid(tree.root):
		root_node = tree.root
	elif tree.has_method("get_root"):
		root_node = tree.get_root()
	if is_instance_valid(root_node):
		pm = root_node.find_child("PauseMenu", true, false)
		if is_instance_valid(pm):
			return pm
		var queue: Array[Node] = [root_node]
		while queue.size() > 0:
			var curr: Node = queue.pop_front()
			if curr != root_node and (curr.is_in_group("pause_menu") or curr.name == "PauseMenu" or curr.get_script() == preload("res://scripts/ui/pause_menu.gd")):
				return curr
			for child in curr.get_children():
				queue.push_back(child)
	return null

func _desplegar_menu_pausa_visual() -> void:
	var pm: Node = _find_pause_menu()
	if is_instance_valid(pm):
		pm.process_mode = Node.PROCESS_MODE_ALWAYS
		if pm.has_method("abrir_pausa"):
			pm.abrir_pausa()
		else:
			pm.visible = true

func _ocultar_menu_pausa_visual() -> void:
	var pm: Node = _find_pause_menu()
	if is_instance_valid(pm):
		pm.process_mode = Node.PROCESS_MODE_ALWAYS
		if pm.has_method("reanudar_juego"):
			pm.reanudar_juego()
		else:
			pm.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# ── Teclas de teclado (PC y Móvil con teclado físico) ─────────────────────────
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_F3:
			var tree := _get_active_tree()
			if is_instance_valid(tree):
				tree.paused = !tree.paused
				if tree.paused:
					_desplegar_menu_pausa_visual()
				else:
					_ocultar_menu_pausa_visual()
			var vp := get_viewport()
			if is_instance_valid(vp):
				vp.set_input_as_handled()
			return
		elif k.keycode == KEY_F5:
			if is_instance_valid(SaveManagerClass.instance):
				SaveManagerClass.instance.guardar_partida("quicksave.json")
			var vp := get_viewport()
			if is_instance_valid(vp):
				vp.set_input_as_handled()
			return
		elif k.keycode == KEY_F9:
			if is_instance_valid(SaveManagerClass.instance):
				SaveManagerClass.instance.cargar_partida("quicksave.json")
			var vp := get_viewport()
			if is_instance_valid(vp):
				vp.set_input_as_handled()
			return

	# ── Entradas de Ratón (solo PC) ───────────────────────────────────────────────
	if not _is_mobile:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					_start_right_drag(mb.position)
				else:
					_finish_right_drag(mb.position)
			elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_process_left_click_selection(mb.position)
		elif event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			if _is_right_dragging:
				_update_right_drag(mm.position)
		return

	# ── Entradas Táctiles (Android / iOS) ─────────────────────────────────────────
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_touch_pressed(touch.index, touch.position)
		else:
			_on_touch_released(touch.index, touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_finger_id and _touch_holding:
			# Si el dedo se mueve significativamente, cancelar el hold-timer
			var delta := drag.position - _touch_screen_pos
			if delta.length() > 18.0:
				_touch_holding = false
				_touch_hold_timer = 0.0

# ─── Lógica de Hold-to-Order Táctil ───────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_mobile or not _touch_holding:
		return
	_touch_hold_timer += delta
	if _touch_hold_timer >= HOLD_ORDER_TIME:
		_touch_holding = false
		_touch_hold_timer = 0.0
		# Disparar orden de movimiento/ataque como si fuera un clic derecho de PC
		_finish_right_drag(_touch_screen_pos)

func _on_touch_pressed(finger_id: int, screen_pos: Vector2) -> void:
	# Solo rastreamos el primer dedo
	if _touch_finger_id != -1:
		return
	_touch_finger_id = finger_id
	_touch_screen_pos = screen_pos

	if _modo_orden_activo:
		# Modo orden: el siguiente toque se ejecuta como orden RTS directa (equivale a clic derecho)
		_start_right_drag(screen_pos)
		_finish_right_drag(screen_pos)
		_modo_orden_activo = false
		if is_instance_valid(_btn_modo_orden):
			_btn_modo_orden.button_pressed = false
	else:
		# Toque simple: iniciar selección táctil y temporizador de hold
		_touch_holding = true
		_touch_hold_timer = 0.0
		_start_right_drag(screen_pos)  # Pre-cargar el punto de inicio del drag

func _on_touch_released(finger_id: int, screen_pos: Vector2) -> void:
	if finger_id != _touch_finger_id:
		return
	_touch_finger_id = -1

	if _touch_holding and _touch_hold_timer < HOLD_ORDER_TIME:
		# El dedo se levantó rápido: fue un tap de selección (equivale a clic izquierdo de PC)
		_touch_holding = false
		_touch_hold_timer = 0.0
		_is_right_dragging = false
		_hide_arrow_indicator()
		_process_left_click_selection(screen_pos)
	else:
		_touch_holding = false
		_touch_hold_timer = 0.0

# ─── Overlay Móvil: Botón Flotante "Modo Orden" ────────────────────────────────

func _setup_mobile_overlay() -> void:
	# Crear el botón flotante como CanvasLayer para que quede siempre encima del 3D
	var cl := CanvasLayer.new()
	cl.name = "MobileOverlay"
	cl.layer = 10
	add_child(cl)

	_btn_modo_orden = Button.new()
	_btn_modo_orden.name = "BtnModoOrden"
	_btn_modo_orden.text = "⚔ ORDEN"
	_btn_modo_orden.toggle_mode = true
	_btn_modo_orden.custom_minimum_size = Vector2(110.0, 64.0)

	# Anclar esquina inferior derecha
	_btn_modo_orden.anchor_right  = 1.0
	_btn_modo_orden.anchor_bottom = 1.0
	_btn_modo_orden.anchor_left   = 1.0
	_btn_modo_orden.anchor_top    = 1.0
	_btn_modo_orden.offset_left   = -130.0
	_btn_modo_orden.offset_top    = -90.0
	_btn_modo_orden.offset_right  = -20.0
	_btn_modo_orden.offset_bottom = -26.0

	# Estilo visual Modo Orden
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color("#B3330099")   # Rojo translúcido inactivo
	style_normal.corner_radius_top_left    = 10
	style_normal.corner_radius_top_right   = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color("#FF3300EE")  # Rojo brillante activo
	style_pressed.corner_radius_top_left    = 10
	style_pressed.corner_radius_top_right   = 10
	style_pressed.corner_radius_bottom_left = 10
	style_pressed.corner_radius_bottom_right = 10

	_btn_modo_orden.add_theme_stylebox_override("normal",  style_normal)
	_btn_modo_orden.add_theme_stylebox_override("pressed", style_pressed)
	_btn_modo_orden.add_theme_color_override("font_color", Color.WHITE)
	_btn_modo_orden.add_theme_font_size_override("font_size", 16)

	cl.add_child(_btn_modo_orden)
	_btn_modo_orden.toggled.connect(_on_modo_orden_toggled)

func _on_modo_orden_toggled(pressed: bool) -> void:
	_modo_orden_activo = pressed
	if pressed:
		print("RTSInputController [Móvil]: Modo Orden ACTIVADO. Toca el mapa para dar órdenes.")
	else:
		print("RTSInputController [Móvil]: Modo Orden DESACTIVADO.")

func _setup_arrow_indicator() -> void:
	if is_instance_valid(_arrow_indicator):
		return
	_arrow_indicator = Node3D.new()
	_arrow_indicator.name = "RTSFacingArrow"

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.1, 0.95, 0.65, 0.9)

	_arrow_shaft = MeshInstance3D.new()
	_arrow_shaft.name = "Shaft"
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.08, 1.0)
	_arrow_shaft.mesh = box
	_arrow_shaft.material_override = mat
	_arrow_indicator.add_child(_arrow_shaft)

	_arrow_head = MeshInstance3D.new()
	_arrow_head.name = "Head"
	var prism := PrismMesh.new()
	prism.size = Vector3(1.4, 1.4, 0.1)
	_arrow_head.mesh = prism
	_arrow_head.rotation_degrees.x = 90.0
	_arrow_head.rotation_degrees.z = 180.0
	_arrow_head.material_override = mat
	_arrow_indicator.add_child(_arrow_head)

	_arrow_indicator.visible = false
	add_child(_arrow_indicator)

func _show_arrow_indicator(origin: Vector3, dir_vec: Vector3) -> void:
	if not is_instance_valid(_arrow_indicator):
		_setup_arrow_indicator()

	var dist := clampf(dir_vec.length(), 1.5, 25.0)
	_arrow_indicator.global_position = origin + Vector3(0.0, 0.15, 0.0)

	var target_look := origin + dir_vec + Vector3(0.0, 0.15, 0.0)
	_arrow_indicator.look_at(target_look, Vector3.UP)

	var shaft_len := maxf(0.1, dist - 1.2)
	_arrow_shaft.scale = Vector3(1.0, 1.0, shaft_len)
	_arrow_shaft.position = Vector3(0.0, 0.0, -shaft_len * 0.5)
	_arrow_head.position = Vector3(0.0, 0.0, -dist)
	_arrow_indicator.visible = true

func _hide_arrow_indicator() -> void:
	if is_instance_valid(_arrow_indicator):
		_arrow_indicator.visible = false

func _raycast_from_screen(screen_pos: Vector2, exclude_rids: Array[RID] = []) -> Dictionary:
	var cam := camera if is_instance_valid(camera) else (get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null)
	if not is_instance_valid(cam):
		return {}

	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_end := ray_origin + cam.project_ray_normal(screen_pos) * ray_length

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if not exclude_rids.is_empty():
		query.exclude = exclude_rids
	return space_state.intersect_ray(query)

func _start_right_drag(screen_pos: Vector2) -> void:
	var selected_units := _get_selected_units()
	if selected_units.is_empty():
		return

	var ray_res := _raycast_from_screen(screen_pos)
	if ray_res.is_empty():
		return

	_is_right_dragging = true
	_right_press_screen = screen_pos
	_right_press_world = ray_res.get("position", Vector3.ZERO) as Vector3
	_right_press_target = ray_res.get("collider", null) as Node

func _update_right_drag(screen_pos: Vector2) -> void:
	var ray_res := _raycast_from_screen(screen_pos)
	if ray_res.is_empty():
		return
	var current_world := ray_res.get("position", Vector3.ZERO) as Vector3
	var drag_vec := current_world - _right_press_world
	drag_vec.y = 0.0

	if drag_vec.length() > 1.2:
		_show_arrow_indicator(_right_press_world, drag_vec)
	else:
		_hide_arrow_indicator()

func _finish_right_drag(screen_pos: Vector2) -> void:
	if not _is_right_dragging:
		return
	_is_right_dragging = false
	_hide_arrow_indicator()

	var selected_units := _get_selected_units()
	if selected_units.is_empty():
		return

	var ray_res := _raycast_from_screen(screen_pos)
	var current_world := ray_res.get("position", _right_press_world) as Vector3 if not ray_res.is_empty() else _right_press_world
	var drag_vec := current_world - _right_press_world
	drag_vec.y = 0.0

	# Instanciar respuesta visual de movimiento en el suelo
	var indicator_class = load("res://scripts/world/move_order_indicator_3d.gd")
	if is_instance_valid(indicator_class) and indicator_class.has_method("create_at"):
		indicator_class.call("create_at", _right_press_world, get_tree().current_scene)

	if drag_vec.length() > 1.2:
		var facing_dir := drag_vec.normalized()
		_dispatch_order_with_facing(selected_units, _right_press_world, facing_dir)
	else:
		var collider := _right_press_target
		if not is_instance_valid(collider) or (not _is_resource_target(collider) and not _is_enemy_target(collider)):
			var nearby_res := _find_nearby_resource(_right_press_world, 3.0)
			if is_instance_valid(nearby_res):
				collider = nearby_res
		_dispatch_order_to_units(selected_units, collider, _right_press_world)

# ─── Sistema de Formaciones Tácticas ──────────────────────────────────────────

enum FormationType { LINE, WEDGE, BOX, SCATTERED }
var current_formation: FormationType = FormationType.LINE

func set_formation(form_name: String) -> void:
	match form_name.to_lower():
		"line", "línea":
			current_formation = FormationType.LINE
		"wedge", "cuña":
			current_formation = FormationType.WEDGE
		"box", "bloque", "cuadrado":
			current_formation = FormationType.BOX
		"scattered", "dispersa":
			current_formation = FormationType.SCATTERED

	var selected := _get_selected_units()
	if selected.size() > 1:
		_rearrange_units_in_formation(selected)

func _calculate_formation_offset(index: int, total: int, facing_dir: Vector3) -> Vector3:
	var perp := Vector3(-facing_dir.z, 0.0, facing_dir.x)
	var forward := facing_dir
	var spacing := 2.5

	match current_formation:
		FormationType.LINE:
			var start_offset: float = -float(total - 1) * 0.5 * spacing
			return perp * (start_offset + float(index) * spacing)

		FormationType.WEDGE:
			if index == 0:
				return Vector3.ZERO
			var side: float = 1.0 if index % 2 == 1 else -1.0
			var rank: float = ceil(float(index) / 2.0)
			return perp * (side * rank * (spacing * 1.1)) - forward * (rank * (spacing * 0.9))

		FormationType.BOX:
			var cols: int = int(ceil(sqrt(float(total))))
			var row: int = index / cols
			var col: int = index % cols
			var off_x: float = (float(col) - float(cols - 1) * 0.5) * spacing
			var off_z: float = -float(row) * spacing
			return perp * off_x + forward * off_z

		FormationType.SCATTERED:
			var cols: int = 3
			var row: int = index / cols
			var col: int = index % cols
			var stagger: float = 0.6 if row % 2 == 1 else 0.0
			var off_x: float = (float(col) - 1.0 + stagger) * (spacing * 1.8)
			var off_z: float = -float(row) * (spacing * 1.5)
			return perp * off_x + forward * off_z

	return perp * float(index) * spacing

func _rearrange_units_in_formation(selected_units: Array) -> void:
	if selected_units.is_empty():
		return

	var center := Vector3.ZERO
	var valid_count := 0
	for u in selected_units:
		if is_instance_valid(u) and u is Node3D:
			center += (u as Node3D).global_position
			valid_count += 1
	if valid_count == 0:
		return
	center /= float(valid_count)

	var facing := Vector3.FORWARD
	var first_u: Node3D = selected_units[0] as Node3D
	if is_instance_valid(first_u):
		facing = -first_u.global_transform.basis.z
		facing.y = 0.0
		if facing.length_squared() < 0.01:
			facing = Vector3.FORWARD
		facing = facing.normalized()

	for i in range(selected_units.size()):
		var u: Node = selected_units[i] as Node
		if not is_instance_valid(u):
			continue
		var target_pos := center + _calculate_formation_offset(i, selected_units.size(), facing)
		_move_unit(u, target_pos, facing)

func _dispatch_order_with_facing(selected_units: Array, hit_pos: Vector3, facing_dir: Vector3) -> void:
	var count := selected_units.size()
	for i in range(count):
		var unit_node := selected_units[i] as Node
		if not is_instance_valid(unit_node):
			continue
		var offset := _calculate_formation_offset(i, count, facing_dir)
		var target_pos := hit_pos + offset
		_move_unit(unit_node, target_pos, facing_dir)

func get_entity_under_screen_point(screen_position: Vector2) -> Node:
	var result := _raycast_from_screen(screen_position)
	if result.is_empty():
		return null

	var collider := result.get("collider", null) as Node
	if not is_instance_valid(collider):
		return null

	# SELECCIÓN DE UNIDADES OCULTAS DETRÁS DE EDIFICIOS (BUILDING RAYCAST BYPASS)
	var is_building_hit: bool = (
		collider is BuildingBase3D or 
		collider.is_in_group("buildings") or 
		collider.is_in_group("player_buildings") or 
		collider.is_in_group("enemy_buildings") or 
		collider.is_in_group("buildings_3d")
	)

	if is_building_hit:
		var exclude_list: Array[RID] = []
		if collider is CollisionObject3D:
			exclude_list.append((collider as CollisionObject3D).get_rid())
		for child in collider.get_children():
			if child is CollisionObject3D:
				exclude_list.append((child as CollisionObject3D).get_rid())

		var second_result := _raycast_from_screen(screen_position, exclude_list)
		if not second_result.is_empty():
			var second_collider := second_result.get("collider", null) as Node
			if is_instance_valid(second_collider):
				var target_unit := _resolve_root_target(second_collider)
				if is_instance_valid(target_unit) and (
					target_unit is UnitBase3D or 
					target_unit.is_in_group("player_units") or 
					target_unit.is_in_group("enemy_units") or 
					target_unit.is_in_group("units_3d")
				):
					var is_alive: bool = true
					if "is_dead" in target_unit and target_unit.is_dead:
						is_alive = false
					elif "salud_actual" in target_unit and target_unit.salud_actual <= 0.0:
						is_alive = false

					if is_alive:
						return target_unit

	return collider

func _process_left_click_selection(screen_position: Vector2) -> void:
	var target_entity := get_entity_under_screen_point(screen_position)
	if not is_instance_valid(target_entity):
		return

	var sm: Node = get_node_or_null("/root/SelectionManager")
	if not is_instance_valid(sm):
		return

	# Si es un recurso interactivo
	if target_entity is ResourceNode3D or target_entity.is_in_group("resources") or target_entity.is_in_group("resources_3d"):
		sm.select_units([target_entity])
		return

	# Si es un edificio o unidad
	if target_entity is BuildingBase3D or target_entity.is_in_group("buildings_3d") or target_entity is UnitBase3D or target_entity.is_in_group("units_3d") or target_entity.is_in_group("player_units") or target_entity.is_in_group("enemy_units"):
		sm.select_units([target_entity])
		return

# ─── Raycast 3D y Despacho de Órdenes ──────────────────────────────────────────

func _process_right_click_order(screen_position: Vector2) -> void:
	var selected_units := _get_selected_units()
	if selected_units.is_empty():
		return

	var result := _raycast_from_screen(screen_position)
	if result.is_empty():
		return

	var collider := result.get("collider", null) as Node
	var hit_position := result.get("position", Vector3.ZERO) as Vector3

	if not is_instance_valid(collider):
		return

	# Detectar si el clic impactó el suelo/terreno para erradicar magnetismo hostil en órdenes de retirada
	var is_terrain_click: bool = (
		collider.is_in_group("terrain") or 
		collider.is_in_group("suelo") or 
		collider.name.to_lower().contains("terrain") or 
		collider.name.to_lower().contains("suelo") or
		(collider is StaticBody3D and (collider.is_in_group("terrain") or collider.name == "TerrainBody"))
	)

	# 1. Prioridad Enemigo: Solo buscar proximidad si NO se hizo clic en el terreno
	var enemy_target: Node3D = null
	if _is_enemy_target(collider):
		enemy_target = _resolve_root_target(collider) as Node3D
	elif not is_terrain_click:
		enemy_target = _find_nearby_enemy(hit_position, 3.5)

	if is_instance_valid(enemy_target):
		collider = enemy_target
	elif not _is_resource_target(collider):
		if not is_terrain_click:
			var nearby_res := _find_nearby_resource(hit_position, 3.0)
			if is_instance_valid(nearby_res):
				collider = nearby_res

	_dispatch_order_to_units(selected_units, collider, hit_position)

func _find_nearby_enemy(pos: Vector3, max_dist: float) -> Node3D:
	var closest: Node3D = null
	var min_dist: float = max_dist

	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("enemy_units"))
	candidates.append_array(get_tree().get_nodes_in_group("enemy_buildings"))
	candidates.append_array(get_tree().get_nodes_in_group("enemigos"))

	for u in get_tree().get_nodes_in_group("units_3d"):
		if is_instance_valid(u) and not candidates.has(u):
			if ("bando" in u and int(u.bando) == 1) or u.is_in_group("enemy_units"):
				candidates.append(u)

	for c in candidates:
		if is_instance_valid(c) and c is Node3D:
			if "is_dead" in c and c.is_dead:
				continue
			if "salud_actual" in c and c.salud_actual <= 0.0:
				continue
			var d := pos.distance_to((c as Node3D).global_position)
			if d < min_dist:
				min_dist = d
				closest = c as Node3D

	return closest

func _resolve_root_target(node: Node) -> Node:
	if not is_instance_valid(node):
		return null
	var cur: Node = node
	while is_instance_valid(cur.get_parent()) and not (cur is UnitBase3D or cur is BuildingBase3D):
		if cur.get_parent() is UnitBase3D or cur.get_parent() is BuildingBase3D:
			return cur.get_parent()
		cur = cur.get_parent()
	return cur

func _find_nearby_resource(pos: Vector3, max_dist: float) -> Node3D:
	var closest: Node3D = null
	var min_dist: float = max_dist
	for res in get_tree().get_nodes_in_group("resources_3d"):
		if is_instance_valid(res) and res is Node3D:
			if res.has_method("is_depleted") and res.is_depleted():
				continue
			var d := pos.distance_to((res as Node3D).global_position)
			if d < min_dist:
				min_dist = d
				closest = res as Node3D
	return closest

func _dispatch_order_to_units(selected_units: Array, target: Node, hit_pos: Vector3) -> void:
	var is_enemy := _is_enemy_target(target)
	var is_resource := _is_resource_target(target)
	var is_town_center := target is TownCenter3D or (is_instance_valid(target) and target.is_in_group("town_centers"))

	var is_live_fauna: bool = is_instance_valid(target) and (target is FaunaAnimal3D or target.is_in_group("fauna") or target.is_in_group("animals_3d")) and not (
		("is_animal_dead" in target and target.is_animal_dead) or ("is_dead" in target and target.is_dead)
	)

	var target_root := _resolve_root_target(target) if is_instance_valid(target) else null
	var is_building := is_instance_valid(target_root) and (target_root is BuildingBase3D or target_root.is_in_group("buildings_3d"))
	var is_friendly_building := is_building and (not ("bando" in target_root) or int(target_root.bando) == 0)
	var is_depot: bool = is_town_center or (is_instance_valid(target) and (target.is_in_group("drop_off") or (target.has_method("deposit_resources") and is_friendly_building)))
	var needs_construction_or_repair: bool = is_friendly_building and (
		(not target_root.esta_construido) or (target_root.salud_actual < target_root.salud_maxima)
	)

	# ─── INTERCEPCÍON TÁCTICA MILITAR ───────────────────────────────────────────
	# Si el objetivo es un enemigo, delegar a MilitaryWarTactics3D para:
	# 1. Maniobra de Flanqueo Automático (>8 unidades contra objetivo fortificado)
	# 2. Smart Targeting Prioritization (redistribuir blancos de arqueros)
	if is_enemy and is_instance_valid(target):
		var tactics := MilitaryWarTactics3D.instance if MilitaryWarTactics3D.instance != null else get_tree().get_first_node_in_group("military_war_tactics") as MilitaryWarTactics3D
		if is_instance_valid(tactics):
			# Recopilar paths de las unidades seleccionadas para RPC
			var unit_paths: Array = []
			for u in selected_units:
				if is_instance_valid(u) and u is Node3D:
					unit_paths.append(u.get_path())

			# Disparar flanqueo RPC si hay suficiente masa de tropas
			if unit_paths.size() >= tactics.umbral_flanqueo_peloton:
				tactics.rpc_coordinar_flanqueo(unit_paths, target.get_path())

				# Smart Targeting: redistribuir arqueros en el pelotón enemigo
				var enemy_peloton: Array[Node3D] = []
				for g in ["enemy_units", "player_units"]:
					for e in get_tree().get_nodes_in_group(g):
						if is_instance_valid(e) and e is Node3D:
							var et_bando: int = int(e.get("bando")) if "bando" in e else -1
							if et_bando != -1 and e.global_position.distance_to(hit_pos) <= 40.0:
								enemy_peloton.append(e as Node3D)

				var attackers_typed: Array[Node3D] = []
				for u in selected_units:
					if is_instance_valid(u) and u is Node3D:
						attackers_typed.append(u as Node3D)
				tactics.evaluar_prioridades_peloton(attackers_typed, enemy_peloton)
				return

	# Calcular centroide para vector de marcha en formación
	var centroid := Vector3.ZERO
	var valid_count := 0
	for u in selected_units:
		if is_instance_valid(u) and u is Node3D:
			centroid += (u as Node3D).global_position
			valid_count += 1
	if valid_count > 0:
		centroid /= float(valid_count)

	var move_dir := (hit_pos - centroid)
	move_dir.y = 0.0
	if move_dir.length_squared() < 0.01:
		move_dir = Vector3.FORWARD
	move_dir = move_dir.normalized()

	for i in range(selected_units.size()):
		var unit_node: Node = selected_units[i] as Node
		if not is_instance_valid(unit_node):
			continue

		# 0. CASO CAZA DE FAUNA ANIMAL VIVA: Cazar con lanza
		if is_live_fauna:
			if unit_node is Villager3D:
				(unit_node as Villager3D).command_hunt(target)
			elif unit_node.has_method("command_attack"):
				unit_node.command_attack(target)
			elif "state_machine" in unit_node and unit_node.state_machine:
				unit_node.state_machine.change_state(&"Attacking", {"target": target, "is_hunting": true})
			if unit_node.has_method("set_status_text"):
				unit_node.set_status_text("🏹 Cazando presa...", 2.0)
			continue

		# 1. CASO ENEMIGO: Atacar
		if is_enemy:
			var enemy_root: Node = _resolve_root_target(target)
			if unit_node.has_method("command_attack"):
				unit_node.command_attack(enemy_root)
			elif "state_machine" in unit_node and unit_node.state_machine:
				unit_node.state_machine.change_state(&"Attacking", {"target": enemy_root})
			if unit_node.has_method("set_status_text"):
				unit_node.set_status_text("⚔️ ¡Al ataque!", 2.0)
			continue

		# 2. CASO ALMACÉN / TOWN CENTER: Depositar si el aldeano lleva recursos
		if is_depot and unit_node is Villager3D:
			var vil := unit_node as Villager3D
			if vil.carried_amount > 0 and vil.has_method("command_deposit"):
				vil.command_deposit(target)
				continue

		# 3. CASO EDIFICIO ALIADO DAÑADO O EN CONSTRUCCIÓN: Reparar o Construir
		if needs_construction_or_repair:
			if unit_node is Villager3D or unit_node.has_method("command_build"):
				if unit_node.has_method("command_build"):
					unit_node.command_build(target_root)
					continue
				elif "state_machine" in unit_node and unit_node.state_machine:
					unit_node.state_machine.change_state(&"Building", {"target_node": target_root})
					continue

		# 4. CASO RECURSO: Recolectar (con validación de niebla y distancia máxima)
		if is_resource:
			if unit_node is Villager3D or unit_node.has_method("command_gather"):
				var check := _can_gather_resource(target as Node3D)
				if not check["allowed"]:
					_notify_player(check["reason"])
					if unit_node.has_method("set_status_text"):
						unit_node.set_status_text("❌ " + check["reason"], 3.0)
					continue
				if unit_node.has_method("command_gather"):
					unit_node.command_gather(target)
				elif "state_machine" in unit_node and unit_node.state_machine:
					unit_node.state_machine.change_state(&"Gathering", {"target_node": target})
			else:
				var offset := _calculate_formation_offset(i, selected_units.size(), move_dir) if selected_units.size() > 1 else Vector3.ZERO
				_move_unit(unit_node, hit_pos + offset, move_dir)
			continue

		# 5. CASO UNIDAD ALIADA: Escolta / Desplazamiento hacia el aliado (NUNCA ATACAR)
		if is_instance_valid(target_root) and (target_root is UnitBase3D or target_root.is_in_group("units_3d")):
			var tgt_u := target_root as UnitBase3D
			var tgt_bando: int = int(tgt_u.bando) if "bando" in tgt_u else 0
			var my_bando: int = int(unit_node.get("bando")) if "bando" in unit_node else 0
			if tgt_bando == my_bando:
				var escort_pos: Vector3 = tgt_u.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
				_move_unit(unit_node, escort_pos)
				continue

		# 6. CASO SUELO: Mover en la formación táctica elegida
		var offset := _calculate_formation_offset(i, selected_units.size(), move_dir) if selected_units.size() > 1 else Vector3.ZERO
		_move_unit(unit_node, hit_pos + offset, move_dir)

func _can_gather_resource(res_node: Node3D) -> Dictionary:
	if not is_instance_valid(res_node):
		return {"allowed": false, "reason": "Recurso inválido"}

	# 1. Validar Niebla de Guerra (Zona explorada)
	var fow: Node = get_tree().get_first_node_in_group("fog_of_war_manager")
	if is_instance_valid(fow) and fow.has_method("is_position_explored"):
		if not fow.is_position_explored(res_node.global_position):
			return {
				"allowed": false,
				"reason": "¡Zona inexplorada! Debes explorar el mapa primero."
			}

	# 2. Validar Distancia al territorio / Centro Urbano o Asentamiento más cercano
	var drop_offs: Array[Node] = []
	for tc in get_tree().get_nodes_in_group("town_centers"):
		var b: int = int(tc.get("bando")) if "bando" in tc else 0
		if b == 0 and tc is Node3D:
			drop_offs.append(tc)
	for bld in get_tree().get_nodes_in_group("player_buildings"):
		if bld is Node3D and not drop_offs.has(bld):
			drop_offs.append(bld)

	if drop_offs.is_empty():
		return {"allowed": true, "reason": ""}

	var min_d := INF
	for d in drop_offs:
		var dist := (d as Node3D).global_position.distance_to(res_node.global_position)
		if dist < min_d:
			min_d = dist

	var max_gather_dist := 65.0
	if min_d > max_gather_dist:
		return {
			"allowed": false,
			"reason": "Recurso demasiado lejos de la base (%.0fm > %.0fm). ¡Construye un Asentamiento cerca!" % [min_d, max_gather_dist]
		}

	return {"allowed": true, "reason": ""}

func _notify_player(msg: String) -> void:
	var notif: Node = get_tree().get_first_node_in_group("rts_notification_manager")
	if is_instance_valid(notif) and notif.has_method("add_notification"):
		notif.add_notification(msg)
	else:
		print("RTS: " + msg)

func _move_unit(unit_node: Node, target_pos: Vector3, facing_dir: Vector3 = Vector3.ZERO) -> void:
	if "desired_facing_direction" in unit_node:
		unit_node.desired_facing_direction = facing_dir
	if unit_node.has_method("command_move_with_facing") and facing_dir != Vector3.ZERO:
		unit_node.command_move_with_facing(target_pos, facing_dir)
	elif unit_node.has_method("command_move"):
		unit_node.command_move(target_pos)
	elif "state_machine" in unit_node and unit_node.state_machine:
		var ctx: Dictionary = {"target_position": target_pos}
		if facing_dir != Vector3.ZERO:
			ctx["facing_direction"] = facing_dir
		unit_node.state_machine.change_state(&"Move", ctx)

# ─── Helpers de Identificación y Selección ─────────────────────────────────────

func _get_selected_units() -> Array:
	var list: Array = []

	# 1. Intentar desde SelectionManager Autoload
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm) and "selected_units" in sm:
		var sel: Array = sm.selected_units
		if not sel.is_empty():
			return sel.duplicate()

	# 2. Intentar desde el grupo oficial "unidades_seleccionadas"
	list = get_tree().get_nodes_in_group("unidades_seleccionadas")
	if not list.is_empty():
		return list

	# 3. Fallback a unidades individuales marcadas como is_selected
	var all_units := get_tree().get_nodes_in_group("units_3d")
	for u in all_units:
		if is_instance_valid(u) and "is_selected" in u and u.is_selected:
			list.append(u)

	return list

func _is_enemy_target(target: Node) -> bool:
	if not is_instance_valid(target):
		return false

	if target.is_in_group("terrain") or target.is_in_group("suelo") or target.name.to_lower().contains("terrain") or target.name.to_lower().contains("suelo"):
		return false

	var node_to_check: Node = _resolve_root_target(target)
	if not is_instance_valid(node_to_check):
		return false

	if node_to_check.is_in_group("terrain") or node_to_check.is_in_group("suelo"):
		return false

	if node_to_check.is_in_group("enemigos") or node_to_check.is_in_group("enemy_units") or node_to_check.is_in_group("enemy_buildings"):
		return true

	if "bando" in node_to_check:
		var bando_val: int = int(node_to_check.bando)
		# 1 = ENEMY en el enum Bando { PLAYER=0, ENEMY=1 }
		if bando_val == 1:
			return true

	return false

func _is_resource_target(target: Node) -> bool:
	if target is ResourceNode3D:
		return true
		
	if target.is_in_group("resources") or target.is_in_group("resources_3d"):
		return true
		
	if target.has_method("extract") and target.has_method("get_resource_type"):
		return true
		
	return false
