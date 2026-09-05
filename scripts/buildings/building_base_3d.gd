## BuildingBase3D — Clase base para todos los edificios 3D (GDScript 2.0 / Godot 4).

class_name BuildingBase3D
extends StaticBody3D

# ─── Bando / Facción ───────────────────────────────────────────────────────────
enum Bando { PLAYER, ENEMY }

# ─── Señales ───────────────────────────────────────────────────────────────────
signal hp_changed(current: float, maximum: float)
signal construction_completed()
signal destroyed()
signal selected_changed(is_selected: bool)
signal rally_point_changed(new_pos: Vector3, target_node: Node3D)

# ─── Stats Exportables ─────────────────────────────────────────────────────────
@export_group("Identidad")
@export var building_name: String = "Building3D"
@export var era: int = 0
@export var bando: Bando = Bando.PLAYER
@export var owner_peer_id: int = 1

@export_group("Visión y Niebla de Guerra")
## Radio del campo de visión en unidades 3D para el Fog of War.
@export var radio_vision: float = 38.0

@export_group("HP y Resistencia")
@export var salud_maxima: float = 600.0
@export var starts_under_construction: bool = false

# Property Aliases
var max_hp: int:
	get: return int(salud_maxima)
	set(v): salud_maxima = float(v)

var hp: int:
	get: return int(salud_actual)
	set(v): salud_actual = float(v)

# ─── Estado de Construcción y Selección ────────────────────────────────────────
var salud_actual: float = 0.0
var is_under_construction: bool = false
var esta_construido: bool = true
var progreso_construccion: float = 100.0
var is_dead: bool = false
var is_selected: bool = false

# ─── Punto de Reunión (Rally Point) ────────────────────────────────────────────
var rally_point: Vector3 = Vector3.ZERO
var rally_point_set: bool = false
var rally_target_node: Node3D = null
var _salud_maxima_base: float = 600.0
var rally_flag_indicator: Node3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	is_under_construction = starts_under_construction
	if is_under_construction:
		esta_construido = false
		progreso_construccion = 0.0
		salud_actual = 1.0
		call_deferred("_update_construction_scaffold_visual")
	else:
		esta_construido = true
		progreso_construccion = 100.0
		salud_actual = salud_maxima

	rally_point = global_position + Vector3(4.0, 0.0, 4.0)

	add_to_group("buildings")
	add_to_group("buildings_3d")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	if owner_peer_id == 1 and multiplayer.has_multiplayer_peer() and get_multiplayer_authority() != 1:
		owner_peer_id = get_multiplayer_authority()

	input_ray_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	call_deferred("_setup_rally_flag_visual")
	call_deferred("_ensure_building_primitive_mesh")
	call_deferred("_ensure_building_label3d")

	# Guardar el HP máximo base para escalar con multiplicadores de era
	_salud_maxima_base = salud_maxima

	# Añadir obstáculo de navegación para que las unidades no choquen con las paredes
	var nav_obs := NavigationObstacle3D.new()
	nav_obs.name = "NavObstacle"
	nav_obs.radius = 5.2 if (self is TownCenter3D or is_in_group("town_centers")) else 3.8
	nav_obs.avoidance_enabled = true
	add_child(nav_obs)

	# Conectar la señal global de cambio de era
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

## Genera malla 3D procedural si el edificio no tiene ningún MeshInstance3D hijo.
func _ensure_building_primitive_mesh() -> void:
	if not find_children("*", "MeshInstance3D", true, false).is_empty():
		return
	if true:
		var visual_node: Node3D = null
		
		if is_in_group("town_centers"):
			var gltf_path := "res://IMAGENES/EDAD PREHISTORICA/CASAS DE CONSTRUIR/capitolio edad prehistorica.glb"
			if not ResourceLoader.exists(gltf_path):
				gltf_path = "res://assets/models/era0/capitolio.glb"
			if ResourceLoader.exists(gltf_path):
				var pscene := load(gltf_path) as PackedScene
				if pscene:
					visual_node = pscene.instantiate() as Node3D
					visual_node.scale = Vector3(3.8, 3.8, 3.8)
					
		if not is_instance_valid(visual_node):
			var mesh_inst := MeshInstance3D.new()
			var box := BoxMesh.new()
			# TownCenter más grande que edificios auxiliares
			if is_in_group("town_centers"):
				box.size = Vector3(6.0, 4.0, 6.0)
				mesh_inst.position = Vector3(0.0, 2.0, 0.0)
			elif is_in_group("barracks") or "arracks" in building_name:
				box.size = Vector3(5.0, 3.5, 5.0)
				mesh_inst.position = Vector3(0.0, 1.75, 0.0)
			else:
				box.size = Vector3(4.0, 3.0, 4.0)
				mesh_inst.position = Vector3(0.0, 1.5, 0.0)
			mesh_inst.mesh = box
			var mat := StandardMaterial3D.new()
			if bando == Bando.PLAYER:
				mat.albedo_color = Color(0.50, 0.65, 0.85) # Azul aliado
			else:
				mat.albedo_color = Color(0.75, 0.30, 0.30) # Rojo enemigo
			mesh_inst.material_override = mat
			visual_node = mesh_inst

		visual_node.name = "BuildingPrimitive"
		add_child(visual_node)

	# Colisionador de caja si falta
	var has_col: bool = false
	for child in get_children():
		if child is CollisionShape3D:
			has_col = true
			break
	if not has_col:
		var col := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(5.0, 4.0, 5.0) if is_in_group("town_centers") else Vector3(4.0, 3.0, 4.0)
		col.shape = box_shape
		col.position = Vector3(0.0, box_shape.size.y / 2.0, 0.0)
		add_child(col)

## Etiqueta 3D flotante con el nombre del edificio.
func _ensure_building_label3d() -> void:
	if get_node_or_null("BuildingNameLabel3D"):
		return
	var lbl := Label3D.new()
	lbl.name = "BuildingNameLabel3D"
	lbl.text = building_name
	lbl.font_size = 20
	lbl.modulate = Color(1.0, 0.95, 0.7, 0.90)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var height: float = 5.5 if is_in_group("town_centers") else 4.5
	lbl.position = Vector3(0.0, height, 0.0)
	lbl.pixel_size = 0.008
	lbl.no_depth_test = true
	add_child(lbl)


# ─── Selección RTS ─────────────────────────────────────────────────────────────

func select() -> void:
	is_selected = true
	selected_changed.emit(true)
	_update_rally_flag_visual()
	_set_selection_glow(true)

func deselect() -> void:
	is_selected = false
	selected_changed.emit(false)
	_update_rally_flag_visual()
	_set_selection_glow(false)

func _set_selection_glow(active: bool) -> void:
	var prim: MeshInstance3D = get_node_or_null("BuildingPrimitive") as MeshInstance3D
	if not is_instance_valid(prim):
		return
	var mat := prim.material_override as StandardMaterial3D
	if not is_instance_valid(mat):
		return
	if active:
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.2)
		mat.emission_energy_multiplier = 0.6
	else:
		mat.emission_enabled = false

# ─── Visualización de Banderín Rally Point ─────────────────────────────────────

func _setup_rally_flag_visual() -> void:
	if is_instance_valid(rally_flag_indicator):
		return

	var flag := Node3D.new()
	flag.name = "RallyFlagIndicator"

	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.04
	pole_mesh.bottom_radius = 0.04
	pole_mesh.height = 2.0

	var pole_inst := MeshInstance3D.new()
	pole_inst.mesh = pole_mesh
	pole_inst.position = Vector3(0.0, 1.0, 0.0)

	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.9, 0.8, 0.2)
	pole_inst.material_override = pole_mat
	flag.add_child(pole_inst)

	var flag_mesh := PrismMesh.new()
	flag_mesh.size = Vector3(0.1, 0.6, 0.8)

	var flag_inst := MeshInstance3D.new()
	flag_inst.mesh = flag_mesh
	flag_inst.position = Vector3(0.3, 1.7, 0.0)
	flag_inst.rotation_degrees.z = -90.0

	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = Color(0.2, 0.6, 1.0)
	flag_inst.material_override = flag_mat
	flag.add_child(flag_inst)

	rally_flag_indicator = flag
	rally_flag_indicator.visible = false

	var parent := get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if is_instance_valid(parent):
		parent.add_child(rally_flag_indicator)

func _update_rally_flag_visual() -> void:
	if not is_instance_valid(rally_flag_indicator):
		return

	rally_flag_indicator.global_position = rally_point
	rally_flag_indicator.visible = is_selected and not is_dead and not is_under_construction

func _unhandled_input(event: InputEvent) -> void:
	if not is_selected or is_dead or is_under_construction or bando != Bando.PLAYER:
		return

	# Si el edificio está seleccionado y el jugador hace clic derecho en el terreno
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var camera := get_viewport().get_camera_3d()
		if not is_instance_valid(camera):
			return

		var mb_event := event as InputEventMouseButton
		var mouse_pos: Vector2 = mb_event.position
		var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
		var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * 2000.0

		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			var collider := result.get("collider", null) as Node
			var hit_pos := result.get("position", Vector3.ZERO) as Vector3

			# Si hace clic sobre el mismo edificio, ignorar
			if collider == self:
				return

			get_viewport().set_input_as_handled()
			_set_rally_point(hit_pos, collider)

func _set_rally_point(hit_position: Vector3, hit_node: Node = null) -> void:
	rally_point = hit_position
	rally_point_set = true

	if is_instance_valid(hit_node) and (hit_node is ResourceNode3D or hit_node.is_in_group("resources") or hit_node.is_in_group("resources_3d")):
		rally_target_node = hit_node as Node3D
	else:
		rally_target_node = null

	_update_rally_flag_visual()
	rally_point_changed.emit(rally_point, rally_target_node)

var _construction_label_3d: Label3D = null

func _update_construction_billboard() -> void:
	if not is_inside_tree():
		return
	if is_under_construction and not esta_construido:
		if not is_instance_valid(_construction_label_3d):
			_construction_label_3d = Label3D.new()
			_construction_label_3d.name = "ConstructionLabel3D"
			_construction_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_construction_label_3d.no_depth_test = true
			_construction_label_3d.font_size = 28
			_construction_label_3d.outline_size = 6
			_construction_label_3d.outline_modulate = Color(0, 0, 0, 0.9)
			_construction_label_3d.modulate = Color(1.0, 0.85, 0.2)
			_construction_label_3d.position = Vector3(0.0, 4.0, 0.0)
			add_child(_construction_label_3d)
		_construction_label_3d.text = "🔨 Construcción: %d%%" % int(progreso_construccion)
		_construction_label_3d.visible = true
	else:
		if is_instance_valid(_construction_label_3d):
			_construction_label_3d.visible = false

# ─── Lógica de Construcción ────────────────────────────────────────────────────

func aplicar_progreso_construccion(incremento: float) -> void:
	if is_dead or esta_construido:
		return

	progreso_construccion = clampf(progreso_construccion + incremento, 0.0, 100.0)
	salud_actual = (progreso_construccion / 100.0) * salud_maxima
	hp_changed.emit(salud_actual, salud_maxima)
	_update_construction_billboard()
	_update_construction_scaffold_visual()

	if progreso_construccion >= 100.0:
		esta_construido = true
		is_under_construction = false
		salud_actual = salud_maxima
		_update_construction_billboard()
		_update_construction_scaffold_visual()
		construction_completed.emit()

var _base_visual_scales: Dictionary = {}

func _update_construction_scaffold_visual() -> void:
	# Eliminar andamio obsoleto si existe
	var scaffold_node := get_node_or_null("ConstructionScaffold")
	if is_instance_valid(scaffold_node):
		scaffold_node.queue_free()

	# Recopilar todos los nodos visuales 3D del edificio (ej: CuartelPrehistorico, BuildingPrimitive, etc.)
	var visual_nodes: Array[Node3D] = []
	for child in get_children():
		if not (child is Node3D):
			continue
		if child is CollisionShape3D or child is NavigationObstacle3D or child is Marker3D or child is Label3D:
			continue
		if child.name == "ConstructionLabel3D" or child.name == "BuildingNameLabel3D" or child.name == "HealthBar3D" or child.name == "RallyFlagIndicator":
			continue
		visual_nodes.append(child as Node3D)

	for v_node in visual_nodes:
		if not _base_visual_scales.has(v_node):
			var cur_s: Vector3 = v_node.scale
			if cur_s.y <= 0.001:
				cur_s.y = 1.0
			_base_visual_scales[v_node] = cur_s

	if is_under_construction and not esta_construido:
		# Factor de elevación progresiva del modelo 3D real desde cimientos (8% de altura) hasta 100%
		var factor := clampf(progreso_construccion / 100.0, 0.08, 1.0)
		for v_node in visual_nodes:
			if is_instance_valid(v_node):
				v_node.visible = true
				var orig_scale: Vector3 = _base_visual_scales.get(v_node, Vector3.ONE)
				v_node.scale = Vector3(orig_scale.x, orig_scale.y * factor, orig_scale.z)
	else:
		for v_node in visual_nodes:
			if is_instance_valid(v_node):
				v_node.visible = true
				if _base_visual_scales.has(v_node):
					v_node.scale = _base_visual_scales[v_node]

func _toggle_building_final_meshes(show_state: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name != "BuildingPrimitive":
			child.visible = show_state

# ─── Daño y Destrucción ────────────────────────────────────────────────────────

func recibir_daño(cantidad: float, _atacante: Node = null) -> void:
	if is_dead or cantidad <= 0.0:
		return
		
	salud_actual = maxf(0.0, salud_actual - cantidad)
	progreso_construccion = (salud_actual / salud_maxima) * 100.0
	hp_changed.emit(salud_actual, salud_maxima)

	# Actualizar o instanciar la barra de salud 3D flotante
	var hbar := get_node_or_null("HealthBar3D")
	if not is_instance_valid(hbar):
		var hbar_class = load("res://scripts/ui/health_bar_3d.gd")
		if is_instance_valid(hbar_class) and hbar_class.has_method("create_for"):
			hbar = hbar_class.call("create_for", self, 4.2)
	if is_instance_valid(hbar) and hbar.has_method("actualizar_salud"):
		hbar.call("actualizar_salud", salud_actual, salud_maxima)
	
	if salud_actual <= 0.0:
		_destroy()

func take_damage(amount: int, source: Node = null) -> void:
	recibir_daño(float(amount), source)

func repair(amount: float) -> void:
	if is_dead:
		return
	if not esta_construido:
		var pct := (amount / salud_maxima) * 100.0
		aplicar_progreso_construccion(pct)
	else:
		salud_actual = minf(salud_actual + amount, salud_maxima)
		progreso_construccion = (salud_actual / salud_maxima) * 100.0
		hp_changed.emit(salud_actual, salud_maxima)

func heal(amount: int) -> void:
	repair(float(amount))

func _destroy() -> void:
	if is_dead:
		return
	is_dead = true
	if is_instance_valid(rally_flag_indicator):
		rally_flag_indicator.queue_free()
	destroyed.emit()
	queue_free()

# ─── Interacción Clic RTS ───────────────────────────────────────────────────────

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if bando == Bando.PLAYER:
				var sm: Node = get_node_or_null("/root/SelectionManager")
				if is_instance_valid(sm) and sm.has_method("select_units"):
					sm.select_units([self])
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if bando == Bando.ENEMY:
				_order_selected_units_to_attack_building()
			elif not esta_construido:
				_order_selected_villagers_to_build()

func _order_selected_units_to_attack_building() -> void:
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if not is_instance_valid(sm) or not ("selected_units" in sm):
		return
	for unit_node in sm.selected_units:
		if is_instance_valid(unit_node):
			if unit_node.has_method("command_attack"):
				unit_node.command_attack(self)

func _order_selected_villagers_to_build() -> void:
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if not is_instance_valid(sm) or not ("selected_units" in sm):
		return
	for unit_node in sm.selected_units:
		if is_instance_valid(unit_node):
			if unit_node.has_method("command_build"):
				unit_node.command_build(self)

# ─── Respuesta al Sistema de Eras ──────────────────────────────────────────────

## Callback conectado a ResourceManager.era_evolucionada (Replicación Asíncrona Individual).
## Escala salud_maxima con el multiplicador de HP de edificios de la nueva era únicamente
## si el bando/propietario coincide con el peer que pagó la evolución.
func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return

	var p_id: int = player_id
	var era_val: int = nueva_era

	if self.owner_peer_id != p_id:
		return
	var mult_hp: float = 1.0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "MULTIPLICADORES_ERA" in rm:
		var mults: Dictionary = rm.get("MULTIPLICADORES_ERA").get(era_val, {})
		mult_hp = float(mults.get("building_hp", 1.0))

	# Calcular qué porcentaje de salud tenía el edificio antes del cambio
	var pct_salud_anterior: float = salud_actual / maxf(salud_maxima, 1.0)

	# Escalar sobre el valor BASE original del edificio
	salud_maxima = _salud_maxima_base * mult_hp

	# Restaurar salud actual de forma proporcional (misma fracción de HP)
	salud_actual = clampf(pct_salud_anterior * salud_maxima, 1.0, salud_maxima)
	progreso_construccion = (salud_actual / salud_maxima) * 100.0

	hp_changed.emit(salud_actual, salud_maxima)

	_actualizar_modelo_visual_era(era_val)

	print("BuildingBase3D '%s': Jugador %d avanzó a Era %d → salud_maxima=%.0f (×%.1f)" % [
		name, player_id, era_val, salud_maxima, mult_hp
	])


func _actualizar_modelo_visual_era(era_val: int) -> void:
	if is_dead:
		return

	# Granjas: parcelas toscas (0-2), huertos góticos con canales (3-5), campos con silos de chapa (6-7), domos hidropónicos UV (8-9)
	var is_farm: bool = is_in_group("farms") or building_name.contains("Granja") or name.contains("Farm")
	var target_key: String = "Primitive_Farm" if is_farm else "Primitive_Mesh"

	match era_val:
		0, 1, 2:
			target_key = "Primitive_Farm" if is_farm else "Primitive_Mesh"
		3, 4, 5:
			target_key = "Historical_Farm" if is_farm else "Historical_Mesh"
		6, 7:
			target_key = "Industrial_Farm" if is_farm else "Industrial_Mesh"
		8, 9:
			target_key = "Futuristic_Farm" if is_farm else "Futuristic_Mesh"

	var found_specific_era_mesh: bool = false

	if not is_under_construction:
		for child in get_children():
			if child is MeshInstance3D and child.name != "ConstructionScaffold" and child.name != "BuildingPrimitive":
				if child.name.contains(target_key) or child.name.begins_with("EraMesh_%d" % era_val):
					child.visible = true
					found_specific_era_mesh = true
				elif child.name.ends_with("_Farm") or child.name.ends_with("_Mesh") or child.name.begins_with("EraMesh_"):
					child.visible = false

	# Si el edificio utiliza BuildingPrimitive procedural, actualizar su textura/material al bloque de era
	var prim := get_node_or_null("BuildingPrimitive") as MeshInstance3D
	if is_instance_valid(prim) and is_instance_valid(prim.mesh) and not found_specific_era_mesh:
		var mat := StandardMaterial3D.new()
		var is_ally: bool = (bando == Bando.PLAYER)
		match era_val:
			0, 1, 2: # Primitivo: madera y barro rústico
				mat.albedo_color = Color(0.55, 0.42, 0.28) if is_ally else Color(0.68, 0.35, 0.25)
				mat.roughness = 0.95
				mat.metallic = 0.0
			3, 4, 5: # Histórico / Medieval: piedra gris labrada y bronce
				mat.albedo_color = Color(0.52, 0.55, 0.60) if is_ally else Color(0.62, 0.38, 0.38)
				mat.roughness = 0.70
				mat.metallic = 0.15
			6, 7: # Industrial: hormigón, ladrillo y acero forjado
				mat.albedo_color = Color(0.38, 0.42, 0.48) if is_ally else Color(0.55, 0.30, 0.30)
				mat.roughness = 0.45
				mat.metallic = 0.70
			8, 9: # Futurista: titanio compuesto blanco y emisores de plasma
				mat.albedo_color = Color(0.85, 0.90, 0.98) if is_ally else Color(0.92, 0.45, 0.45)
				mat.roughness = 0.20
				mat.metallic = 0.90
				mat.emission_enabled = true
				mat.emission = Color(0.0, 0.75, 1.0) if is_ally else Color(1.0, 0.25, 0.0)
				mat.emission_energy_multiplier = 0.8
		prim.material_override = mat

	# Actualizar la etiqueta 3D superior con el prefijo de la era
	var lbl: Label3D = get_node_or_null("BuildingNameLabel3D") as Label3D
	if is_instance_valid(lbl):
		lbl.text = "[Era %d] %s" % [era_val, building_name]
