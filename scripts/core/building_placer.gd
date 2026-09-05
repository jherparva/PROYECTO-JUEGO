## BuildingPlacer — Gestor del Sistema de Colocación de Edificios 3D (GDScript 2.0 / Godot 4).
##
## Administra el modo de construcción RTS:
## 1. Instancia una silueta fantasma semi-transparente que proyecta sobre el terreno por Raycast 3D.
## 2. Verifica fondos en `ResourceManager`, descuenta recursos y fija la estructura real.
## 3. Asigna automáticamente la construcción a los aldeanos seleccionados.

class_name BuildingPlacer
extends Node3D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal placement_started(building_scene: PackedScene)
signal placement_finished(building_instance: BuildingBase3D)
signal placement_canceled()

# ─── Exports y Configuración ───────────────────────────────────────────────────
@export var ray_length: float = 2000.0
@export_flags_3d_physics var terrain_mask: int = 1
@export var ghost_color: Color = Color(0.2, 0.9, 0.4, 0.55)

# ─── Estado Interno ────────────────────────────────────────────────────────────
var is_placing: bool = false
var current_building_scene: PackedScene = null
var current_cost: Dictionary = {}
var ghost_node: Node3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if not is_placing or not is_instance_valid(ghost_node):
		return

	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return

	# Proyección del ratón sobre el suelo 3D por Raycast
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * ray_length

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = terrain_mask

	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var hit_pos := result.get("position", Vector3.ZERO) as Vector3
		ghost_node.global_position = ghost_node.global_position.lerp(hit_pos, 0.6)
	else:
		# Fallback a plano horizontal XZ en Y=0.0
		var plane := Plane(Vector3.UP, 0.0)
		var hit_intersection = plane.intersects_ray(ray_origin, camera.project_ray_normal(mouse_pos))
		if hit_intersection != null:
			ghost_node.global_position = ghost_node.global_position.lerp(hit_intersection as Vector3, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if not is_placing:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_confirm_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			cancelar_colocacion()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancelar_colocacion()

# ─── API Pública ───────────────────────────────────────────────────────────────

const REQUIRED_ERAS: Dictionary = {
	"Hut3D": 0,
	"Choza": 0,
	"Choza3D": 0,
	"Barracks3D": 0,
	"Barracks": 0,
	"Cuartel": 0,
	"Cuartel3D": 0,
	"Settlement3D": 0,
	"Asentamiento": 0,
	"Asentamiento3D": 0,
	"DropOffDepot3D": 0,
	"Almacen": 0,
	"Farm3D": 1,
	"Granja": 1,
	"Granja3D": 1,
	"Tower3D": 1,
	"Torre": 1,
	"Torre3D": 1,
	"ArcheryRange3D": 1,
	"ArcheryRange": 1,
	"CampoDeTiro": 1,
	"CampoDeTiro3D": 1,
	"Temple3D": 1,
	"Templo": 1,
	"Templo3D": 1,
	"Stable3D": 2,
	"Establo": 2,
	"Establo3D": 2,
	"WallWoodEra1": 1,
	"WallWood3D": 1,
	"Empalizada": 1,
	"SiegeWorkshop3D": 2,
	"TallerAsedio": 2,
	"TallerAsedio3D": 2,
	"Market3D": 2,
	"Dock3D": 2,
	"Wonder3D": 5,
	"Satellite3D": 8,
	"WeatherController3D": 9   # Era 9 — Nano-Futurista. Costo: 300 Hierro, 300 Oro.
}

## Inicia el modo de colocación de un edificio 3D con su escena y costo.
func iniciar_colocacion(escena_edificio: PackedScene, costo: Dictionary) -> void:
	if not is_instance_valid(escena_edificio):
		push_error("BuildingPlacer: Escena de edificio no válida.")
		return

	# Validar restricción por árbol de eras
	var dummy: Node = escena_edificio.instantiate()
	var b_name: String = str(dummy.name) if is_instance_valid(dummy) else ""
	var req_era: int = int(REQUIRED_ERAS.get(b_name, 0))
	if is_instance_valid(dummy): dummy.queue_free()

	var cur_era: int = 0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		cur_era = int(rm.era_actual)

	# Excepción Era 1: Corral / Establo temprano habilitado en Era 1 para investigación pasiva
	if (b_name == "Stable3D" or b_name == "Establo" or b_name == "Establo3D") and cur_era >= 1:
		req_era = 1

	if cur_era < req_era:
		var era_names: Array[String] = ["Prehistórica", "Piedra", "Bronce", "Hierro", "Medieval", "Renacimiento", "Industrial", "Atómica", "Digital", "Nano-Futurista"]
		var req_era_str: String = era_names[req_era] if (req_era >= 0 and req_era < era_names.size()) else "superior"
		var ncm: Node = get_node_or_null("/root/NetworkChatManager")
		if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
			ncm.call("enviar_mensaje_local", "⚠️ Estructura bloqueada. Requiere Era de %s o superior." % req_era_str)
		print("BuildingPlacer: %s bloqueado. Requiere Era %d (Era actual: %d)" % [b_name, req_era, cur_era])
		return

	# Cancelar cualquier colocación previa activa
	if is_placing:
		cancelar_colocacion()

	current_building_scene = escena_edificio
	current_cost = costo
	is_placing = true

	# Instanciar silueta fantasma
	ghost_node = escena_edificio.instantiate() as Node3D
	_setup_ghost_visuals(ghost_node)

	var parent := get_tree().current_scene if get_tree() and get_tree().current_scene else self
	parent.add_child(ghost_node)

	placement_started.emit(escena_edificio)

## Cancela el modo de colocación actual y destruye la silueta fantasma.
func cancelar_colocacion() -> void:
	if is_instance_valid(ghost_node):
		ghost_node.queue_free()
		ghost_node = null

	is_placing = false
	current_building_scene = null
	current_cost.clear()
	placement_canceled.emit()

# ─── Confirmación e Instanciación ──────────────────────────────────────────────

func _confirm_placement() -> void:
	if not is_instance_valid(ghost_node) or not is_instance_valid(current_building_scene):
		return

	# 1. Verificar y gastar recursos en ResourceManager
	var success := false
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_method("gastar_recursos"):
			success = rm.gastar_recursos(current_cost)
		elif rm.has_method("spend_resources"):
			success = rm.spend_resources(current_cost)

	if not success:
		print("BuildingPlacer: Recursos insuficientes para construir este edificio.")
		return

	# Guardar posición final del fantasma
	var build_position := ghost_node.global_position

	# Destruir fantasma
	ghost_node.queue_free()
	ghost_node = null
	is_placing = false

	# 2. Instanciar edificio real en construcción
	var new_building := current_building_scene.instantiate() as BuildingBase3D
	if not is_instance_valid(new_building):
		new_building = BuildingBase3D.new()

	new_building.starts_under_construction = true
	new_building.esta_construido = false
	new_building.progreso_construccion = 0.0
	new_building.salud_actual = 1.0

	var parent := get_tree().current_scene if get_tree() and get_tree().current_scene else self
	var b_container := parent.get_node_or_null("World/Buildings")
	if is_instance_valid(b_container):
		b_container.add_child(new_building)
	else:
		parent.add_child(new_building)

	new_building.global_position = build_position

	# Auto-tiling dinámico de cuadrícula para murallas / empalizadas
	if new_building.has_method("actualizar_conexiones"):
		new_building.call("actualizar_conexiones")
	if new_building.is_in_group("walls") or new_building.is_in_group("walls_3d"):
		if get_tree():
			for w in get_tree().get_nodes_in_group("walls_3d"):
				if is_instance_valid(w) and w != new_building and w.has_method("actualizar_conexiones"):
					if (w as Node3D).global_position.distance_to(build_position) <= 5.0:
						w.call("actualizar_conexiones")

	# 3. Asignar orden de construcción a aldeanos seleccionados
	_order_selected_villagers_to_build(new_building)

	placement_finished.emit(new_building)

func _order_selected_villagers_to_build(building: BuildingBase3D) -> void:
	var selected: Array = []
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm) and "selected_units" in sm:
		selected = sm.selected_units
	else:
		selected = get_tree().get_nodes_in_group("unidades_seleccionadas")

	for unit_node in selected:
		if is_instance_valid(unit_node) and (unit_node is Villager3D or unit_node.has_method("command_build")):
			if unit_node.has_method("command_build"):
				unit_node.command_build(building)
			elif "state_machine" in unit_node and unit_node.state_machine:
				unit_node.state_machine.change_state(&"Building", {"target_node": building})

# ─── Configuración Visual del Fantasma ─────────────────────────────────────────

func _setup_ghost_visuals(node: Node) -> void:
	# Deshabilitar colisionadores para evitar intercepciones
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	elif node is CollisionObject3D:
		(node as CollisionObject3D).input_ray_pickable = false

	# Aplicar material semitransparente verde a todas las mallas
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		var ghost_mat := StandardMaterial3D.new()
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost_mat.albedo_color = ghost_color
		ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = ghost_mat

	for child in node.get_children():
		_setup_ghost_visuals(child)
