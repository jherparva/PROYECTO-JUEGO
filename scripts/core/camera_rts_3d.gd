## CameraRTS3D — Controlador de Cámara 3D estilo RTS (GDScript 2.0 / Godot 4).
##
## Incluye:
## 1. Movimiento por teclado (WASD / Flechas) y movimiento al borde de la pantalla (Edge Panning rápido).
## 2. Paneo con botón central del ratón (MMB Drag) para arrastre directo del mapa.
## 3. Inclinación isométrica de ángulo fijo (-55°).
## 4. Zoom suave con rueda del ratón (Scroll Wheel) escalando velocidad según distancia.
## 5. Interpolación suavizada con `lerp` para máxima fluidez táctica.

class_name CameraRTS3D
extends Node3D

# ─── Exports ───────────────────────────────────────────────────────────────────
@export_group("Inclinación de Cámara")
## Ángulo de inclinación vertical fijo (en grados).
@export var camera_pitch_angle: float = -55.0

@export_group("Velocidad y Suavizado")
@export var move_speed: float = 70.0
@export var pan_smoothing: float = 14.0

@export_group("Bordes de Pantalla (Edge Panning)")
@export var enable_edge_scroll: bool = true
## Distancia generosa en píxeles para que se active fácilmente al acercar el ratón a los bordes.
@export var edge_margin: float = 42.0

@export_group("Zoom")
@export var min_zoom: float = 8.0
@export var max_zoom: float = 45.0
@export var zoom_speed: float = 5.0
@export var zoom_smoothing: float = 12.0

@export_group("Límites del Mapa (Opcional)")
@export var enable_bounds: bool = true
@export var min_bounds: Vector2 = Vector2(-190.0, -190.0)
@export var max_bounds: Vector2 = Vector2(190.0, 190.0)

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target_position: Vector3 = Vector3.ZERO
var _target_zoom: float = 25.0
var _current_zoom: float = 25.0

var _is_mmb_dragging: bool = false
var _mmb_last_pos: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = get_node_or_null("Camera3D") as Camera3D

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_target_position = global_position
	_target_zoom = clampf(_target_zoom, min_zoom, max_zoom)
	_current_zoom = _target_zoom

	# Registrar en grupo para que el Minimapa pueda encontrar esta cámara
	add_to_group("rts_camera")

	# Asegurar que exista un nodo Camera3D como hijo
	if not is_instance_valid(camera):
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Configurar la inclinación de ángulo fijo
	rotation_degrees.x = camera_pitch_angle
	rotation_degrees.y = 0.0
	rotation_degrees.z = 0.0

	_update_camera_zoom_transform()

func _process(delta: float) -> void:
	_handle_input_movement(delta)
	_apply_smooth_movement(delta)
	_apply_smooth_zoom(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Zoom con rueda del ratón
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = maxf(min_zoom, _target_zoom - zoom_speed)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = minf(max_zoom, _target_zoom + zoom_speed)
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_is_mmb_dragging = true
				_mmb_last_pos = mb.position
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_mmb_dragging = false

	# Paneo arrastrando con botón central del ratón (MMB Drag)
	elif event is InputEventMouseMotion and _is_mmb_dragging:
		var mm := event as InputEventMouseMotion
		var pan_factor: float = (_current_zoom / 25.0) * 0.045
		var move_offset := Vector3(-mm.relative.x, 0.0, -mm.relative.y) * pan_factor
		_target_position += move_offset
		if enable_bounds:
			_target_position.x = clampf(_target_position.x, min_bounds.x, max_bounds.x)
			_target_position.z = clampf(_target_position.z, min_bounds.y, max_bounds.y)

# ─── Movimiento de la Cámara ───────────────────────────────────────────────────

func _handle_input_movement(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO

	# Movimiento por teclado (WASD + Flechas)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	# Movimiento por bordes de pantalla (Mouse Edge Panning)
	if enable_edge_scroll and not _is_mmb_dragging:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var vp_size: Vector2 = get_viewport().get_visible_rect().size

		if mouse_pos.x <= edge_margin:
			input_dir.x -= 1.0
		elif mouse_pos.x >= vp_size.x - edge_margin:
			input_dir.x += 1.0

		if mouse_pos.y <= edge_margin:
			input_dir.y -= 1.0
		elif mouse_pos.y >= vp_size.y - edge_margin:
			input_dir.y += 1.0

	if input_dir.length_squared() > 0.001:
		input_dir = input_dir.normalized()

		# Escalar velocidad con el zoom: alejado se mueve más rápido
		var zoom_factor: float = clampf(_current_zoom / 22.0, 0.8, 2.2)
		var move_vector: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y) * move_speed * zoom_factor * delta
		_target_position += move_vector

		# Aplicar límites del terreno
		if enable_bounds:
			_target_position.x = clampf(_target_position.x, min_bounds.x, max_bounds.x)
			_target_position.z = clampf(_target_position.z, min_bounds.y, max_bounds.y)

# ─── Suavizado con lerp ────────────────────────────────────────────────────────

func _apply_smooth_movement(delta: float) -> void:
	global_position = global_position.lerp(_target_position, pan_smoothing * delta)

func _apply_smooth_zoom(delta: float) -> void:
	_current_zoom = lerpf(_current_zoom, _target_zoom, zoom_smoothing * delta)
	_update_camera_zoom_transform()

func _update_camera_zoom_transform() -> void:
	if is_instance_valid(camera):
		camera.position = Vector3(0.0, 0.0, _current_zoom)
