## SelectionBox — Overlay UI para selección por arrastre (drag-select).
##
## Dibuja un rectángulo translúcido durante el arrastre del mouse.
## Al soltar, detecta todas las unidades dentro del rectángulo en pantalla.
##
## Configuración en escena:
##   • Coloca este nodo como hijo de un CanvasLayer (encima del mundo).
##   • Ajusta anchor_right=1, anchor_bottom=1 para cubrir toda la pantalla.
##   • El CanvasLayer debe tener layer=10 o superior (por encima de la UI del juego).
##
## Integración:
##   • Llama SelectionManager.select_units() o add_to_selection() según Shift.
##   • Las unidades deben estar en el grupo "units" y tener global_position.
##
## Patrón: Observer → delega resultado de selección a SelectionManager.

class_name SelectionBox
extends Control

# ─── Exports ───────────────────────────────────────────────────────────────────
## Color de relleno del rectángulo de selección.
@export var box_fill_color: Color   = Color(0.2, 0.85, 0.3, 0.18)
## Color del borde del rectángulo.
@export var box_border_color: Color = Color(0.25, 0.95, 0.35, 0.9)
## Grosor del borde en píxeles.
@export var border_width: float = 1.5
## Distancia mínima de arrastre (en px) para activar el cuadro.
@export var drag_threshold: float = 6.0
## Nombre del grupo de Godot al que pertenecen las unidades seleccionables.
@export var unit_group: String = "units"

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _dragging: bool    = false
var _start: Vector2    = Vector2.ZERO
var _current: Vector2  = Vector2.ZERO

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# No bloquear clics al mundo — solo escuchar eventos sin consumirlos aquí
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(_delta: float) -> void:
	if _dragging:
		_current = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	if not _dragging:
		return
	var rect := _get_selection_rect()
	if rect.size.length() < drag_threshold:
		return
	draw_rect(rect, box_fill_color)
	draw_rect(rect, box_border_color, false, border_width)

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_start_drag(mb.position)
	else:
		_end_drag()

# ─── Lógica de Arrastre ────────────────────────────────────────────────────────

func _start_drag(pos: Vector2) -> void:
	_start    = pos
	_current  = pos
	_dragging = true

func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	queue_redraw()  # Borrar el rectángulo

	var rect := _get_selection_rect()
	# Si el arrastre fue demasiado pequeño, lo tratamos como click simple
	if rect.size.length() < drag_threshold:
		return

	var found := _query_units_in_screen_rect(rect)

	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm):
		if Input.is_key_pressed(KEY_SHIFT):
			sm.add_units_to_selection(found)
		else:
			sm.select_units(found)

# ─── Detección de Unidades ─────────────────────────────────────────────────────

## Recorre todas las unidades del grupo y filtra las que caen dentro del rect de pantalla.
func _query_units_in_screen_rect(screen_rect: Rect2) -> Array:
	var found: Array = []
	var viewport := get_viewport()
	if not viewport:
		return found

	var camera_3d := viewport.get_camera_3d()
	var canvas_transform := viewport.get_canvas_transform()

	# Recopilar unidades tanto del grupo genérico como de units_3d y player_units
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group(unit_group))
	candidates.append_array(get_tree().get_nodes_in_group("player_units"))
	candidates.append_array(get_tree().get_nodes_in_group("units_3d"))

	# Eliminar duplicados
	var processed: Dictionary = {}

	for unit in candidates:
		if not is_instance_valid(unit) or processed.has(unit):
			continue
		processed[unit] = true

		var screen_pos: Vector2 = Vector2(-99999.0, -99999.0)

		# Soporte 3D
		if unit is Node3D:
			if is_instance_valid(camera_3d):
				# Ignorar si está detrás de la cámara
				if camera_3d.is_position_behind((unit as Node3D).global_position):
					continue
				screen_pos = camera_3d.unproject_position((unit as Node3D).global_position)
		# Soporte 2D
		elif unit is Node2D:
			screen_pos = canvas_transform * (unit as Node2D).global_position

		if screen_rect.has_point(screen_pos):
			# Filtrar solo unidades del jugador (no enemigos)
			if "bando" in unit and int(unit.bando) != 0:
				continue
			found.append(unit)

	return found

func _get_selection_rect() -> Rect2:
	return Rect2(_start, _current - _start).abs()
