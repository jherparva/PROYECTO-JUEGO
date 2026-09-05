## BuildingGhost — Preview visual de un edificio antes de construirlo.
##
## Sigue al cursor del mouse. Valida si puede ser construido en esa posición
## comprobando superposiciones con otras áreas o cuerpos estáticos.
## Al hacer click, si es válido, instancia el edificio real en estado de construcción.

class_name BuildingGhost
extends Node2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal placed(position: Vector2)
signal cancelled()

# ─── Variables ─────────────────────────────────────────────────────────────────
var building_scene: PackedScene
var cost: Dictionary = {}
var building_size: Vector2 = Vector2(96, 96)

var is_valid_placement: bool = true

@onready var color_rect := ColorRect.new()
@onready var area := Area2D.new()
@onready var collision := CollisionShape2D.new()

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Configuración visual
	color_rect.size = building_size
	color_rect.position = -building_size * 0.5
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	# Configuración física (para detectar colisiones)
	var shape := RectangleShape2D.new()
	shape.size = building_size
	collision.shape = shape
	area.add_child(collision)
	
	# Solo detectar colisiones con otros edificios, recursos o unidades
	area.collision_layer = 0
	area.collision_mask = 1 | 2 | 4 | 8 # Asumiendo capas estándar
	add_child(area)

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var mouse_screen := get_viewport().get_mouse_position()
	var mouse_world := get_viewport().get_canvas_transform().affine_inverse() * mouse_screen
	
	global_position = mouse_world
	
	_validate_placement()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var rm: Node = get_node_or_null("/root/ResourceManager")
			if is_valid_placement and is_instance_valid(rm) and rm.has_method("can_afford") and rm.can_afford(cost):
				_place_building()
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			cancelled.emit()
			queue_free()
			get_viewport().set_input_as_handled()
	
	# Cancelar con Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()

# ─── Lógica ────────────────────────────────────────────────────────────────────

func _validate_placement() -> void:
	var overlapping := area.get_overlapping_bodies()
	var overlapping_areas := area.get_overlapping_areas()
	
	# Si hay algo debajo, no es válido
	is_valid_placement = (overlapping.size() == 0 and overlapping_areas.size() == 0)
	
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("can_afford") and not rm.can_afford(cost):
		is_valid_placement = false
		
	if is_valid_placement:
		color_rect.color = Color(0.2, 1.0, 0.2, 0.5) # Verde translúcido
	else:
		color_rect.color = Color(1.0, 0.2, 0.2, 0.5) # Rojo translúcido

func _place_building() -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm) or not rm.has_method("spend_resources") or not rm.spend_resources(cost):
		return
		
	var building := building_scene.instantiate()
	if building is BuildingBase:
		building.starts_under_construction = true
	
	building.global_position = global_position
	
	# Añadir el edificio al mundo
	var buildings_node := get_tree().root.get_node_or_null("Main/World/Buildings")
	if is_instance_valid(buildings_node):
		buildings_node.add_child(building)
	else:
		get_tree().root.add_child(building)
		
	placed.emit(global_position)
	queue_free()
