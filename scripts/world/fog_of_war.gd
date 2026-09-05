## FogOfWar — Sistema completo de Niebla de Guerra generado por código.
##
## Crea automáticamente la jerarquía de Viewports para lograr:
## 1. Zonas Ocultas (Negro)
## 2. Zonas Exploradas (Gris oscurecido)
## 3. Zonas Visibles AHORA (Transparente)
##
## Simplemente añade este nodo (FogOfWar) como hijo de `Main`.
## Se encarga de buscar todos los nodos en el grupo "vision_casters"
## (que deben tener un radio_vision: float) y dibujarlos.

class_name FogOfWar
extends CanvasLayer

# ─── Configuración ─────────────────────────────────────────────────────────────
## Pon en false para desactivar la niebla completamente (modo debug).
@export var enabled: bool = true

# ─── Variables ─────────────────────────────────────────────────────────────────
var _current_vp: SubViewport
var _accum_vp: SubViewport

var _current_rect: ColorRect
var _accum_rect: ColorRect

var _display_rect: ColorRect
var _vision_casters: Array[Node] = []

var _screen_size: Vector2 = Vector2(1920, 1080)

# ─── Shaders ───────────────────────────────────────────────────────────────────

# Shader para el acumulador (mantiene lo anterior y suma lo nuevo)
const ACCUM_SHADER = """
shader_type canvas_item;
uniform sampler2D current_vision;
void fragment() {
	vec4 current = texture(current_vision, UV);
	vec4 old = texture(TEXTURE, UV);
	COLOR = max(current, old);
}
"""

# Shader final para mostrar en pantalla
const DISPLAY_SHADER = """
shader_type canvas_item;
uniform sampler2D current_vision;
uniform sampler2D accum_vision;

uniform vec4 fog_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 explored_color = vec4(0.0, 0.0, 0.0, 0.6);

void fragment() {
	float curr = texture(current_vision, UV).r;
	float acc = texture(accum_vision, UV).r;
	
	if (curr > 0.1) {
		// Visible ahora
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (acc > 0.1) {
		// Explorado antes
		COLOR = explored_color;
	} else {
		// Nunca visto
		COLOR = fog_color;
	}
}
"""

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 8
	
	if not enabled:
		return # FoW desactivado - no construir nada
	
	# Actualizar tamaño al inicio
	_screen_size = get_viewport().get_visible_rect().size
	get_tree().get_root().size_changed.connect(_on_screen_resized)
	
	_build_hierarchy()

func _process(_delta: float) -> void:
	if not enabled:
		return
	_update_vision()

# ─── Configuración Interna ─────────────────────────────────────────────────────

func _build_hierarchy() -> void:
	# 1. Current Vision Viewport (se limpia cada frame)
	_current_vp = SubViewport.new()
	_current_vp.size = _screen_size
	_current_vp.transparent_bg = true
	_current_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_current_vp.disable_3d = true
	add_child(_current_vp)
	
	_current_rect = ColorRect.new()
	_current_rect.color = Color.TRANSPARENT
	_current_rect.size = _screen_size
	# Sobrescribimos el dibujado en _draw
	_current_rect.draw.connect(_on_current_draw)
	_current_vp.add_child(_current_rect)
	
	# 2. Accumulator Viewport (NUNCA se limpia, guarda memoria)
	_accum_vp = SubViewport.new()
	_accum_vp.size = _screen_size
	_accum_vp.transparent_bg = true
	_accum_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_accum_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER # MEMORIA!
	_accum_vp.disable_3d = true
	add_child(_accum_vp)
	
	_accum_rect = ColorRect.new()
	_accum_rect.size = _screen_size
	var accum_mat = ShaderMaterial.new()
	var accum_shader = Shader.new()
	accum_shader.code = ACCUM_SHADER
	accum_mat.shader = accum_shader
	
	# Esperar 1 frame para que las texturas estén listas
	call_deferred("_setup_textures", accum_mat)
	
	_accum_rect.material = accum_mat
	_accum_vp.add_child(_accum_rect)
	
	# 3. Display Rect (lo que ve el jugador en el Main Screen)
	_display_rect = ColorRect.new()
	_display_rect.size = _screen_size
	_display_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var display_mat = ShaderMaterial.new()
	var display_shader = Shader.new()
	display_shader.code = DISPLAY_SHADER
	display_mat.shader = display_shader
	_display_rect.material = display_mat
	
	add_child(_display_rect)

func _setup_textures(accum_mat: ShaderMaterial) -> void:
	# Conectar las texturas de los viewports a los shaders
	var curr_tex = _current_vp.get_texture()
	var acc_tex = _accum_vp.get_texture()
	
	accum_mat.set_shader_parameter("current_vision", curr_tex)
	
	var disp_mat = _display_rect.material as ShaderMaterial
	disp_mat.set_shader_parameter("current_vision", curr_tex)
	disp_mat.set_shader_parameter("accum_vision", acc_tex)

func _on_screen_resized() -> void:
	_screen_size = get_viewport().get_visible_rect().size
	_current_vp.size = _screen_size
	_current_rect.size = _screen_size
	_accum_vp.size = _screen_size
	_accum_rect.size = _screen_size
	_display_rect.size = _screen_size

# ─── Dibujado de Visión ────────────────────────────────────────────────────────

func _update_vision() -> void:
	# Buscar todas las unidades que otorgan visión (nuestras)
	_vision_casters.clear()
	var units = get_tree().get_nodes_in_group("units")
	var buildings = get_tree().get_nodes_in_group("buildings")
	
	_vision_casters.append_array(units)
	_vision_casters.append_array(buildings)
	
	# Forzar redibujado de la máscara actual
	_current_rect.queue_redraw()

func _on_current_draw() -> void:
	# Obtener la cámara activa para transformar coordenadas de mundo a pantalla
	var cam := get_viewport().get_camera_2d()
	var canvas_transform := get_viewport().get_canvas_transform()
	
	# Dibujar un círculo blanco opaco por cada caster
	for caster in _vision_casters:
		if not is_instance_valid(caster) or not caster is Node2D:
			continue
			
		# Solo aliados (podrías añadir lógica de facciones aquí)
		if "is_dead" in caster and caster.is_dead:
			continue
			
		# Si no tiene radio definido, usar 300 por defecto
		var radius: float = caster.vision_radius if "vision_radius" in caster else 300.0
		
		# Proyectar al espacio de pantalla
		var screen_pos = canvas_transform * caster.global_position
		
		# Ajustar el radio por el zoom de la cámara
		var zoom_factor = cam.zoom.x if cam else 1.0
		var screen_radius = radius * zoom_factor
		
		# Dibujar el círculo en el Current Rect (color blanco = visible)
		_current_rect.draw_circle(screen_pos, screen_radius, Color.WHITE)
