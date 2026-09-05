## Minimap — Sistema de Minimapa Interactivo 2D (GDScript 2.0 / Godot 4).
##
## Renderiza una vista cenital simplificada del mapa 3D en la esquina inferior
## derecha de la pantalla. Dibuja "blips" de colores para:
##   - Unidades del jugador     → puntos verdes
##   - Edificios del jugador    → cuadrados verdes
##   - Enemigos visibles (FOW)  → puntos rojos
##   - Recursos en el mapa      → puntos amarillos
##
## Al hacer clic izquierdo sobre el minimapa, la cámara RTS principal se
## desplaza instantáneamente a las coordenadas 3D correspondientes.

class_name Minimap
extends Control

# ─── Exports y Configuración ───────────────────────────────────────────────────
@export_group("Dimensiones del Mapa 3D")
## Debe coincidir con el map_bounds del FogOfWarManager.
@export var map_bounds: Vector2 = Vector2(400.0, 400.0)

@export_group("Visual de Blips")
@export var blip_unit_color:     Color = Color(0.2, 1.0, 0.3, 1.0)      # Verde jugador
@export var blip_building_color: Color = Color(0.1, 0.85, 0.4, 1.0)     # Verde edificio
@export var blip_enemy_color:    Color = Color(1.0, 0.2, 0.2, 1.0)      # Rojo enemigo
@export var blip_resource_color: Color = Color(1.0, 0.88, 0.1, 1.0)     # Amarillo recurso
@export var blip_unit_radius:    float = 3.5
@export var blip_building_size:  float = 5.0
@export var blip_resource_radius:float = 2.5

@export_group("Rendimiento")
## Intervalo en segundos entre actualizaciones de los blips (0.1 = 10 FPS).
@export var update_interval: float = 0.1

@export_group("Cámara Cenital (SubViewport)")
## Altura Y desde la cual la cámara cenital mira hacia abajo.
@export var overview_camera_height: float = 350.0

# ─── Nodos internos ────────────────────────────────────────────────────────────
@onready var viewport_texture_rect: TextureRect = $ViewportTextureRect
@onready var sub_viewport: SubViewport           = $MinimapSubViewport
@onready var overview_camera: Camera3D           = $MinimapSubViewport/OverviewCamera

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _update_timer: float = 0.0
var _blip_data: Array[Dictionary] = []   # [{pos, color, size, is_rect}]
var _fow_manager: Node3D = null
var _rts_camera: Node3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_process(true)
	set_process_input(true)

	# Buscar el FogOfWarManager global
	var fow_nodes: Array[Node] = get_tree().get_nodes_in_group("fog_of_war_manager")
	if not fow_nodes.is_empty():
		_fow_manager = fow_nodes[0] as Node3D

	# Buscar la cámara RTS principal (marcada con grupo rts_camera)
	_find_rts_camera()

	# Configurar cámara cenital del SubViewport
	_setup_overview_camera()

	# Primera actualización de blips
	_refresh_blips()

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_refresh_blips()
		queue_redraw()

# ─── Cámara Cenital ────────────────────────────────────────────────────────────

func _setup_overview_camera() -> void:
	if not is_instance_valid(overview_camera):
		return

	# Cámara ortográfica mirando directamente hacia abajo
	overview_camera.projection       = Camera3D.PROJECTION_ORTHOGONAL
	overview_camera.size             = maxf(map_bounds.x, map_bounds.y)
	overview_camera.position         = Vector3(0.0, overview_camera_height, 0.0)
	overview_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	overview_camera.near             = 0.1
	overview_camera.far              = overview_camera_height * 2.5

# ─── Lógica de Blips ───────────────────────────────────────────────────────────

func _refresh_blips() -> void:
	_blip_data.clear()

	if not get_tree():
		return

	# Unidades del jugador
	for node in get_tree().get_nodes_in_group("player_units"):
		_add_blip_from_node(node, blip_unit_color, blip_unit_radius, false)

	# También recorrer units_3d por compatibilidad si no están en player_units
	for node in get_tree().get_nodes_in_group("units_3d"):
		if not node.is_in_group("enemy_units") and not node.is_in_group("player_units"):
			_add_blip_from_node(node, blip_unit_color, blip_unit_radius, false)

	# Edificios del jugador
	for node in get_tree().get_nodes_in_group("player_buildings"):
		_add_blip_from_node(node, blip_building_color, blip_building_size, true)

	# Town centers (siempre visibles)
	for node in get_tree().get_nodes_in_group("town_centers"):
		if not node.is_in_group("enemy_buildings"):
			_add_blip_from_node(node, blip_building_color, blip_building_size + 2.0, true)

	# Enemigos — sólo los que estén en visión activa de la FOW
	for node in get_tree().get_nodes_in_group("enemy_units"):
		if _is_node_visible_in_fow(node):
			_add_blip_from_node(node, blip_enemy_color, blip_unit_radius, false)

	for node in get_tree().get_nodes_in_group("enemy_buildings"):
		if _is_node_visible_in_fow(node):
			_add_blip_from_node(node, blip_enemy_color, blip_building_size, true)

	# Recursos (nodos explorados o siempre visibles)
	for node in get_tree().get_nodes_in_group("resources_3d"):
		if _is_node_explored_in_fow(node):
			_add_blip_from_node(node, blip_resource_color, blip_resource_radius, false)

func _add_blip_from_node(node: Node, color: Color, size: float, is_rect: bool) -> void:
	if not is_instance_valid(node) or not (node is Node3D):
		return
	var world_pos3d: Vector3 = (node as Node3D).global_position
	var map2d_pos: Vector2 = _world3d_to_minimap2d(world_pos3d)
	_blip_data.append({
		"pos":     map2d_pos,
		"color":   color,
		"size":    size,
		"is_rect": is_rect
	})

# ─── Dibujo 2D de Blips ────────────────────────────────────────────────────────

func _draw() -> void:
	var rect: Rect2 = get_rect()

	# Fondo semiopaco del minimapa
	draw_rect(rect, Color(0.05, 0.08, 0.05, 0.88), true)

	# Capa táctica de Niebla de Guerra (cubre terreno inexplorado de negro en el minimapa)
	if is_instance_valid(_fow_manager) and is_instance_valid(_fow_manager.minimap_fog_texture):
		draw_texture_rect(_fow_manager.minimap_fog_texture, rect, false)

	# Blips tácticos
	for blip: Dictionary in _blip_data:
		var pos2d: Vector2 = blip["pos"] as Vector2
		var col: Color = blip["color"] as Color
		var sz: float = float(blip["size"])
		var is_rc: bool = bool(blip["is_rect"])

		# Verificar que el punto esté dentro del área del minimapa
		if pos2d.x < 0.0 or pos2d.x > rect.size.x or pos2d.y < 0.0 or pos2d.y > rect.size.y:
			continue

		if is_rc:
			var half: float = sz * 0.5
			draw_rect(Rect2(pos2d.x - half, pos2d.y - half, sz, sz), col, true)
		else:
			draw_circle(pos2d, sz, col)

	# Indicador de la cámara principal (rectángulo blanco semitransparente)
	_draw_camera_frustum_indicator(rect)

	# Pings tácticos de alerta de ataque
	_draw_pings_alerta()

	# Borde exterior del minimapa
	draw_rect(rect, Color(0.4, 0.8, 0.4, 0.9), false, 2.0)

func _draw_camera_frustum_indicator(minimap_rect: Rect2) -> void:
	if not is_instance_valid(_rts_camera):
		_find_rts_camera()
		if not is_instance_valid(_rts_camera):
			return

	# Centro de visión de la cámara en coordenadas del minimapa
	var cam_world_pos: Vector3 = _rts_camera.global_position
	var cam_center_2d: Vector2 = _world3d_to_minimap2d(cam_world_pos)

	# Tamaño aproximado del frustum visible según el zoom
	var frustum_half: float = 15.0
	if "_current_zoom" in _rts_camera:
		frustum_half = float(_rts_camera.get("_current_zoom")) * 0.55

	var indicator_rect: Rect2 = Rect2(
		cam_center_2d.x - frustum_half * (minimap_rect.size.x / map_bounds.x),
		cam_center_2d.y - frustum_half * (minimap_rect.size.y / map_bounds.y),
		frustum_half * 2.0 * (minimap_rect.size.x / map_bounds.x),
		frustum_half * 2.0 * (minimap_rect.size.y / map_bounds.y)
	)
	draw_rect(indicator_rect, Color(1.0, 1.0, 1.0, 0.35), true)
	draw_rect(indicator_rect, Color(1.0, 1.0, 1.0, 0.85), false, 1.5)

# ─── Interactividad — Clic para Mover Cámara ───────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = mb.position
		var rect: Rect2 = get_rect()
		# Normalizar posición dentro del minimapa
		var norm_x: float = clampf(local_pos.x / rect.size.x, 0.0, 1.0)
		var norm_y: float = clampf(local_pos.y / rect.size.y, 0.0, 1.0)
		# Convertir a coordenadas 3D del mapa
		var world_x: float = (norm_x - 0.5) * map_bounds.x
		var world_z: float = (norm_y - 0.5) * map_bounds.y
		_move_rts_camera_to(Vector3(world_x, 0.0, world_z))
		get_viewport().set_input_as_handled()

func _move_rts_camera_to(world_pos: Vector3) -> void:
	if not is_instance_valid(_rts_camera):
		_find_rts_camera()
	if not is_instance_valid(_rts_camera):
		return

	# Mover el nodo raíz de la cámara RTS (CameraRTS3D) a la posición XZ
	if "_target_position" in _rts_camera:
		var current_y: float = float(_rts_camera.global_position.y)
		_rts_camera.set("_target_position", Vector3(world_pos.x, current_y, world_pos.z))
	else:
		_rts_camera.global_position = Vector3(
			world_pos.x,
			_rts_camera.global_position.y,
			world_pos.z
		)

# ─── Conversión de Coordenadas ─────────────────────────────────────────────────

## Convierte una posición 3D del mundo a coordenadas 2D dentro del minimapa.
func _world3d_to_minimap2d(world_pos: Vector3) -> Vector2:
	var rect: Rect2 = get_rect()
	var norm_x: float = (world_pos.x / map_bounds.x) + 0.5
	var norm_z: float = (world_pos.z / map_bounds.y) + 0.5
	return Vector2(norm_x * rect.size.x, norm_z * rect.size.y)

# ─── Consultas FOW ─────────────────────────────────────────────────────────────

func _is_node_visible_in_fow(node: Node) -> bool:
	if not is_instance_valid(_fow_manager) or not (node is Node3D):
		return true  # Sin FOW activa, mostrar todo
	return _fow_manager.is_position_visible((node as Node3D).global_position)

func _is_node_explored_in_fow(node: Node) -> bool:
	if not is_instance_valid(_fow_manager) or not (node is Node3D):
		return true
	return _fow_manager.is_position_explored((node as Node3D).global_position)

# ─── Búsqueda de la Cámara RTS Principal ──────────────────────────────────────

func _find_rts_camera() -> void:
	# 1. Buscar por grupo (el nodo raíz CameraRTS3D debe añadirse al grupo "rts_camera")
	var cam_nodes: Array[Node] = get_tree().get_nodes_in_group("rts_camera")
	if not cam_nodes.is_empty():
		_rts_camera = cam_nodes[0] as Node3D
		return

	# 2. Buscar por class_name CameraRTS3D en el árbol
	var root: Node = get_tree().current_scene
	if is_instance_valid(root):
		_rts_camera = _find_by_class_recursive(root, "CameraRTS3D") as Node3D

func _find_by_class_recursive(node: Node, class_str: String) -> Node:
	if node.get_class() == class_str or (node.get_script() and (node.get_script() as Script).get_global_name() == class_str):
		return node
	for child in node.get_children():
		var result: Node = _find_by_class_recursive(child, class_str)
		if is_instance_valid(result):
			return result
	return null

# ─── Pings de Alerta de Ataque ───────────────────────────────────────────────
var _pings_alerta: Array[Dictionary] = [] # [{pos_2d, timer, max_time}]

func ping_attack_location(pos_3d: Vector3) -> void:
	var pos_2d := _world3d_to_minimap2d(pos_3d)
	_pings_alerta.append({
		"pos": pos_2d,
		"timer": 0.0,
		"max_time": 2.5
	})

func _draw_pings_alerta() -> void:
	var to_remove: Array[int] = []
	for i in range(_pings_alerta.size()):
		var p: Dictionary = _pings_alerta[i]
		p["timer"] += get_process_delta_time()
		var progress: float = float(p["timer"]) / float(p["max_time"])
		if progress >= 1.0:
			to_remove.append(i)
			continue
		var radius: float = 6.0 + progress * 24.0
		var alpha: float = (1.0 - progress) * 0.9
		draw_circle(p["pos"] as Vector2, radius, Color(1.0, 0.1, 0.1, alpha))
		draw_arc(p["pos"] as Vector2, radius + 2.0, 0.0, TAU, 16, Color(1.0, 0.9, 0.2, alpha * 0.8), 2.0)

	to_remove.reverse()
	for idx in to_remove:
		_pings_alerta.remove_at(idx)
