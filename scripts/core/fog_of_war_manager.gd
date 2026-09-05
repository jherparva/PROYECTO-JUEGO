## FogOfWarManager — Gestor de Niebla de Guerra 3D Optimizado (GDScript 2.0 / Godot 4).
##
## Administra la revelación táctica dinámica en 3D:
## 1. Negro Absoluto (Terra Incognita): Terreno nunca explorado.
## 2. Gris/Penumbra (Vista previa): Terreno explorado previamente sin visión activa actual.
## 3. Visión Activa (Transparente): Revelación en tiempo real por unidades y edificios del jugador.
## Actualización regulada en ticks (10 FPS) para máximo rendimiento sin pérdidas de cuadros por segundo.

extends Node3D

# ─── Exports y Configuración ───────────────────────────────────────────────────
@export_group("Dimensiones del Mapa")
@export var map_bounds: Vector2 = Vector2(400.0, 400.0)
@export var texture_size: Vector2i = Vector2i(256, 256)
@export var fog_height: float = 7.5

@export_group("Rendimiento y Ticks")
## Intervalo en segundos entre cada actualización de la textura (0.1s = 10 Hz / FPS).
@export var update_interval: float = 0.1

# ─── Estado Interno ────────────────────────────────────────────────────────────
var fog_image: Image = null
var fog_texture: ImageTexture = null
var minimap_fog_image: Image = null
var minimap_fog_texture: ImageTexture = null
var fog_material: ShaderMaterial = null
var fog_mesh_instance: MeshInstance3D = null

var _update_timer: float = 0.0
var _explored_grid: PackedByteArray = PackedByteArray()
var _current_vision_grid: PackedByteArray = PackedByteArray()

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("fog_of_war_manager")
	_initialize_fog_system()

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_fog_grid()

# ─── Inicialización del Sistema ────────────────────────────────────────────────

func _initialize_fog_system() -> void:
	var total_pixels := texture_size.x * texture_size.y
	_explored_grid.resize(total_pixels)
	_explored_grid.fill(0)
	_current_vision_grid.resize(total_pixels)
	_current_vision_grid.fill(0)

	# Crear imagen RGBA8 para 3D (Canal R = Visión Activa, Canal G = Explorado)
	fog_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, 1))
	fog_texture = ImageTexture.create_from_image(fog_image)

	# Crear imagen RGBA8 lista para el minimapa 2D (Negro opaco inicial)
	minimap_fog_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	minimap_fog_image.fill(Color(0.02, 0.04, 0.02, 0.95))
	minimap_fog_texture = ImageTexture.create_from_image(minimap_fog_image)

	# Cargar shader de Niebla de Guerra
	var shader := load("res://resources/shaders/fog_of_war_3d.gdshader") as Shader
	if is_instance_valid(shader):
		fog_material = ShaderMaterial.new()
		fog_material.shader = shader
		fog_material.set_shader_parameter("fog_texture", fog_texture)

	# Crear PlaneMesh para cubrir el mapa en 3D
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = map_bounds

	fog_mesh_instance = MeshInstance3D.new()
	fog_mesh_instance.name = "FogOfWarPlane"
	fog_mesh_instance.mesh = plane_mesh
	fog_mesh_instance.material_override = fog_material
	fog_mesh_instance.position = Vector3(0.0, fog_height, 0.0)

	add_child(fog_mesh_instance)

# ─── Actualización Táctica Regulada por Ticks ──────────────────────────────────

func _update_fog_grid() -> void:
	if not is_instance_valid(fog_image) or not is_instance_valid(fog_texture):
		return

	_current_vision_grid.fill(0)

	# Recopilar todos los reveladores del bando del jugador
	var vision_sources: Array[Node] = []
	vision_sources.append_array(get_tree().get_nodes_in_group("player_units"))
	vision_sources.append_array(get_tree().get_nodes_in_group("player_buildings"))

	# Dibujar círculos de visión para cada unidad/edificio del jugador
	for source in vision_sources:
		if is_instance_valid(source) and source is Node3D:
			var node3d := source as Node3D
			var radius: float = source.radio_vision if "radio_vision" in source else 10.0
			_mark_vision_circle(node3d.global_position, radius)

	# Actualizar la textura RGBA8 basada en los canales R (visión) y G (explorado)
	var width := texture_size.x
	var height := texture_size.y

	for y in height:
		for x in width:
			var idx := y * width + x
			var active_val: int = _current_vision_grid[idx]
			var explored_val: int = _explored_grid[idx]

			var r_col := 1.0 if active_val > 0 else 0.0
			var g_col := 1.0 if explored_val > 0 else 0.0

			fog_image.set_pixel(x, y, Color(r_col, g_col, 0.0, 1.0))

			if is_instance_valid(minimap_fog_image):
				if active_val > 0:
					minimap_fog_image.set_pixel(x, y, Color(0, 0, 0, 0)) # Visión actual: transparente
				elif explored_val > 0:
					minimap_fog_image.set_pixel(x, y, Color(0.04, 0.07, 0.04, 0.62)) # Penumbra explorada
				else:
					minimap_fog_image.set_pixel(x, y, Color(0.02, 0.04, 0.02, 0.96)) # Inexplorado: negro

	# Subir imágenes actualizadas a la GPU
	fog_texture.update(fog_image)
	if is_instance_valid(minimap_fog_texture) and is_instance_valid(minimap_fog_image):
		minimap_fog_texture.update(minimap_fog_image)

	# Ocultar o mostrar unidades y estructuras enemigas según visibilidad actual
	_update_enemy_visibility()

func _mark_vision_circle(world_pos: Vector3, radius: float) -> void:
	var half_bounds := map_bounds * 0.5
	var center_pixel_x := int(((world_pos.x + half_bounds.x) / map_bounds.x) * texture_size.x)
	var center_pixel_y := int(((world_pos.z + half_bounds.y) / map_bounds.y) * texture_size.y)
	var pixel_radius := int((radius / map_bounds.x) * texture_size.x)

	var min_x := clampi(center_pixel_x - pixel_radius, 0, texture_size.x - 1)
	var max_x := clampi(center_pixel_x + pixel_radius, 0, texture_size.x - 1)
	var min_y := clampi(center_pixel_y - pixel_radius, 0, texture_size.y - 1)
	var max_y := clampi(center_pixel_y + pixel_radius, 0, texture_size.y - 1)

	var r_sq := pixel_radius * pixel_radius

	for y in range(min_y, max_y + 1):
		var dy := y - center_pixel_y
		for x in range(min_x, max_x + 1):
			var dx := x - center_pixel_x
			if (dx * dx + dy * dy) <= r_sq:
				var idx := y * texture_size.x + x
				_current_vision_grid[idx] = 255
				_explored_grid[idx] = 255

# ─── Consultas Tácticas de Visibilidad ─────────────────────────────────────────

## Retorna true si las coordenadas World Vector3 están en visión activa actual.
func is_position_visible(world_pos: Vector3) -> bool:
	var half_bounds := map_bounds * 0.5
	var px := int(((world_pos.x + half_bounds.x) / map_bounds.x) * texture_size.x)
	var py := int(((world_pos.z + half_bounds.y) / map_bounds.y) * texture_size.y)

	if px < 0 or px >= texture_size.x or py < 0 or py >= texture_size.y:
		return false

	var idx := py * texture_size.x + px
	return _current_vision_grid[idx] > 0

## Retorna true si las coordenadas World Vector3 pertenecen a terreno previamente explorado.
func is_position_explored(world_pos: Vector3) -> bool:
	var half_bounds := map_bounds * 0.5
	var px := int(((world_pos.x + half_bounds.x) / map_bounds.x) * texture_size.x)
	var py := int(((world_pos.z + half_bounds.y) / map_bounds.y) * texture_size.y)

	if px < 0 or px >= texture_size.x or py < 0 or py >= texture_size.y:
		return false

	var idx := py * texture_size.x + px
	return _explored_grid[idx] > 0

# ─── Ocultamiento de Enemigos Táctico ──────────────────────────────────────────

func _update_enemy_visibility() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy_units")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			var node3d := enemy as Node3D
			var is_vis := is_position_visible(node3d.global_position)
			node3d.visible = is_vis
