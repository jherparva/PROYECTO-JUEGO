## HealthBar3D — Barra de Salud Flotante Billboard 3D (GDScript 2.0 / Godot 4).
##
## Muestra una barra de vida 3D flotante que mira a la cámara (Billboard) cuando la unidad sufre daños.

class_name HealthBar3D
extends Node3D

@export var offset_y: float = 2.2

var _sprite_3d: Sprite3D = null
var _sub_viewport: SubViewport = null
var _progress_bar: ProgressBar = null
var _target_node: Node3D = null

static func create_for(entity: Node3D, height_offset: float = 2.2) -> HealthBar3D:
	if not is_instance_valid(entity):
		return null
	var bar := HealthBar3D.new()
	bar.offset_y = height_offset
	bar._target_node = entity
	entity.add_child(bar)
	bar.position = Vector3(0.0, height_offset, 0.0)
	return bar

func _ready() -> void:
	visible = false
	_setup_billboard_ui()

func _setup_billboard_ui() -> void:
	# 1. SubViewport para renderizar la UI 2D en memoria
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(120, 16)
	_sub_viewport.transparent_bg = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub_viewport)

	# 2. ProgressBar de alto contraste (Verde / Rojo)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(120, 16)
	_progress_bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.set_corner_radius_all(3)

	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color(0.2, 0.9, 0.3, 0.95)
	fg_style.set_corner_radius_all(3)

	_progress_bar.add_theme_stylebox_override("background", bg_style)
	_progress_bar.add_theme_stylebox_override("fill", fg_style)
	_sub_viewport.add_child(_progress_bar)

	# 3. Sprite3D en modo Billboard
	_sprite_3d = Sprite3D.new()
	_sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite_3d.no_depth_test = true
	_sprite_3d.pixel_size = 0.01
	_sprite_3d.texture = _sub_viewport.get_texture()
	add_child(_sprite_3d)

func actualizar_salud(actual: float, maxima: float) -> void:
	if maxima <= 0.0:
		return

	if not is_instance_valid(_progress_bar):
		return

	_progress_bar.max_value = maxima
	_progress_bar.value = actual

	# La barra solo se vuelve visible si la entidad ha sufrido daños
	if actual < maxima and actual > 0.0:
		visible = true
		# Cambiar color a amarillo/rojo si la salud es crítica
		var ratio := actual / maxima
		var fg := _progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if is_instance_valid(fg):
			if ratio < 0.3:
				fg.bg_color = Color(0.9, 0.15, 0.15, 0.95) # Rojo crítico
			elif ratio < 0.6:
				fg.bg_color = Color(0.95, 0.8, 0.15, 0.95) # Amarillo medio
			else:
				fg.bg_color = Color(0.2, 0.9, 0.3, 0.95) # Verde óptimo
	else:
		visible = false
