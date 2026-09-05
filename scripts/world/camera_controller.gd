## CameraController — Cámara RTS con pan, edge-scroll y zoom.
##
## Controles:
##   • Pan: Teclas de flecha (↑↓←→) o arrastrar con el botón central del mouse
##   • Edge scroll: mover el cursor al borde de la ventana
##   • Zoom: rueda del mouse
##
## Configura map_limits para restringir el movimiento al tamaño del mapa.
## Adjunta este script a un nodo Camera2D hijo de la escena Main.

class_name CameraController
extends Camera2D

# ─── Exports ───────────────────────────────────────────────────────────────────
@export_group("Pan")
@export var pan_speed: float = 500.0
@export var edge_scroll_enabled: bool = true
## Margen en píxeles desde el borde de ventana que activa el edge-scroll.
@export var edge_margin: float = 24.0

@export_group("Zoom")
@export var zoom_step: float = 0.1
@export var zoom_min: float = 0.4
@export var zoom_max: float = 3.0
## Velocidad de suavizado del zoom (lerp). 0 = instantáneo.
@export var zoom_smooth: float = 10.0

@export_group("Límites del Mapa")
@export var map_rect: Rect2 = Rect2(-500, -500, 4000, 4000)

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _target_zoom: float = 1.0
var _middle_drag_active: bool = false
var _middle_drag_origin: Vector2 = Vector2.ZERO
var _camera_origin: Vector2 = Vector2.ZERO

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	enabled = true
	_target_zoom = zoom.x
	_apply_limits()
	# Empezar la cámara centrada donde está el aldeano al inicio
	global_position = Vector2(500.0, 500.0)

func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_handle_edge_scroll(delta)
	_smooth_zoom(delta)
	_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	# ── Zoom con rueda del mouse ───────────────────────────────────────────────
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clampf(_target_zoom + zoom_step, zoom_min, zoom_max)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clampf(_target_zoom - zoom_step, zoom_min, zoom_max)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_middle_drag_active = true
				_middle_drag_origin = mb.position
				_camera_origin     = global_position
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_MIDDLE:
			_middle_drag_active = false

	# ── Pan con botón central del mouse ───────────────────────────────────────
	if event is InputEventMouseMotion and _middle_drag_active:
		var motion := event as InputEventMouseMotion
		var delta_screen: Vector2 = motion.position - _middle_drag_origin
		global_position = _camera_origin - delta_screen / zoom.x
		get_viewport().set_input_as_handled()

# ─── Pan por Teclado (teclas de flecha) ───────────────────────────────────────

func _handle_keyboard_pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_UP)    or Input.is_key_pressed(KEY_KP_8): dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN)  or Input.is_key_pressed(KEY_KP_2): dir.y += 1.0
	if Input.is_key_pressed(KEY_LEFT)  or Input.is_key_pressed(KEY_KP_4): dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_KP_6): dir.x += 1.0
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta * (1.0 / zoom.x)

# ─── Edge Scroll ──────────────────────────────────────────────────────────────

func _handle_edge_scroll(delta: float) -> void:
	if not edge_scroll_enabled:
		return
	# Solo actuar si la ventana tiene el foco
	if not get_window().has_focus():
		return
	var mouse  := get_viewport().get_mouse_position()
	var vp_size := get_viewport().get_visible_rect().size
	var dir    := Vector2.ZERO
	if mouse.x < edge_margin:                  dir.x -= 1.0
	if mouse.x > vp_size.x - edge_margin:     dir.x += 1.0
	if mouse.y < edge_margin:                  dir.y -= 1.0
	if mouse.y > vp_size.y - edge_margin:     dir.y += 1.0
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta * (1.0 / zoom.x)

# ─── Zoom Suavizado ───────────────────────────────────────────────────────────

func _smooth_zoom(delta: float) -> void:
	var current_z := zoom.x
	if abs(current_z - _target_zoom) > 0.001:
		var new_z := lerpf(current_z, _target_zoom, zoom_smooth * delta)
		zoom = Vector2(new_z, new_z)

# ─── Restricciones ────────────────────────────────────────────────────────────

func _apply_limits() -> void:
	limit_left   = int(map_rect.position.x)
	limit_top    = int(map_rect.position.y)
	limit_right  = int(map_rect.end.x)
	limit_bottom = int(map_rect.end.y)

func _clamp_position() -> void:
	global_position.x = clampf(global_position.x, map_rect.position.x, map_rect.end.x)
	global_position.y = clampf(global_position.y, map_rect.position.y, map_rect.end.y)
