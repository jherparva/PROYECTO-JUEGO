## ProductionOptimizationManager — Gestor de Carga Asíncrona y Caché de Shaders (GDScript 2.0 / Godot 4).
##
## Optimiza el rendimiento de producción en Godot 4.3:
## - Precarga asíncrona mediante ResourceLoader.load_threaded_request() para eliminar stuttering.
## - Precálculo y compilación en frío de Shaders GPU (fog_of_war.gdshader).
## - Cache de PackedScenes frecuentes (Unidades, Edificios y Proyectiles 3D).

class_name ProductionOptimizationManager
extends Node

signal preloading_completed()
signal progress_updated(progress: float, current_resource: String)

# ─── Lista de Escenas Críticas a Precargar ────────────────────────────────────
const CRITICAL_SCENES: Array[String] = [
	"res://scenes/units/villager_3d.tscn",
	"res://scenes/units/soldier_3d.tscn",
	"res://scenes/units/archer_3d.tscn",
	"res://scenes/units/prophet_3d.tscn",
	"res://scenes/buildings/town_center_3d.tscn",
	"res://scenes/buildings/barracks_3d.tscn",
	"res://scenes/buildings/dock_3d.tscn",
	"res://scenes/buildings/temple_3d.tscn",
	"res://scenes/buildings/drop_off_depot_3d.tscn",
	"res://scenes/buildings/farm_3d.tscn",
	"res://scenes/world/projectile_3d.tscn",
	"res://scenes/world/hit_vfx_3d.tscn"
]

# ─── Cache en Memoria RAM ──────────────────────────────────────────────────────
var loaded_scenes_cache: Dictionary = {}
var _pending_queue: Array[String] = []
var _current_resource: String = ""
var _is_preloading: bool = false
var _total_count: int = 0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("optimization_manager")
	process_mode = PROCESS_MODE_ALWAYS

	# 1. Compilar shaders en frío antes del renderizado del mapa
	_precompile_gpu_shaders()

	# 2. Iniciar la precarga asíncrona de recursos
	start_async_preload()

# ─── Precarga Asíncrona (ResourceLoader Threaded) ─────────────────────────────

func start_async_preload() -> void:
	if _is_preloading:
		return

	_pending_queue = CRITICAL_SCENES.duplicate()
	_total_count = _pending_queue.size()
	_is_preloading = true

	print("ProductionOptimizationManager: Iniciando precarga asíncrona de %d recursos..." % _total_count)
	_process_next_in_queue()

func _process(_delta: float) -> void:
	if not _is_preloading or _current_resource.is_empty():
		return

	var progress_array: Array = []
	var status := ResourceLoader.load_threaded_get_status(_current_resource, progress_array)

	var p_val: float = progress_array[0] if not progress_array.is_empty() else 0.0
	var overall_progress := (float(_total_count - _pending_queue.size() - 1) + p_val) / float(_total_count)
	progress_updated.emit(overall_progress, _current_resource)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(_current_resource)
			if is_instance_valid(res):
				loaded_scenes_cache[_current_resource] = res
			_current_resource = ""
			_process_next_in_queue()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("ProductionOptimizationManager: Error al cargar '%s' asíncronamente." % _current_resource)
			_current_resource = ""
			_process_next_in_queue()

func _process_next_in_queue() -> void:
	if _pending_queue.is_empty():
		_is_preloading = false
		print("ProductionOptimizationManager: ¡Precarga asíncrona completada con éxito!")
		preloading_completed.emit()
		return

	_current_resource = _pending_queue.pop_front()
	ResourceLoader.load_threaded_request(_current_resource, "", true)

## Obtiene una escena precargada directamente de la memoria RAM.
func get_cached_scene(path: String) -> PackedScene:
	if loaded_scenes_cache.has(path):
		return loaded_scenes_cache[path] as PackedScene
	elif ResourceLoader.has_cached(path):
		return load(path) as PackedScene
	else:
		return load(path) as PackedScene

# ─── Compilación de Caché de Shaders (GPU Shader Warmup) ──────────────────────

func _precompile_gpu_shaders() -> void:
	# Crear una malla invisible en coordenadas lejanas para compilar fog_of_war.gdshader
	var shader_res := load("res://shaders/fog_of_war.gdshader") as Shader
	if not is_instance_valid(shader_res):
		return

	var mat := ShaderMaterial.new()
	mat.shader = shader_res

	var dummy_mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	dummy_mesh.mesh = quad
	dummy_mesh.material_override = mat
	dummy_mesh.position = Vector3(9999.0, 9999.0, 9999.0) # Fuera de pantalla

	add_child(dummy_mesh)

	# Autodestruir el nodo dummy tras el primer frame renderizado por la GPU
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(dummy_mesh):
			dummy_mesh.queue_free()
	)

	print("ProductionOptimizationManager: Shader 'fog_of_war.gdshader' precompilado en la GPU.")
