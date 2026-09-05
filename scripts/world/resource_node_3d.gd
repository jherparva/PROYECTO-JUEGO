## ResourceNode3D — Nodo de Recurso Interactivo 3D (GDScript 2.0 / Godot 4).
##
## Representa canteras, vetas rocosas, árboles y presas de caza.
## Soporta los 5 recursos del proyecto: "wood", "food", "stone", "iron", "gold".

class_name ResourceNode3D
extends StaticBody3D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal depleted(node: Node3D)
signal amount_changed(current: int, maximum: int)

# ─── Exports ───────────────────────────────────────────────────────────────────
@export_enum("wood", "food", "stone", "iron", "gold") var resource_type: String = "wood":
	set(v):
		resource_type = v
		_balance_resource_capacity()

@export var max_amount: int = 300
@export var is_aquatic: bool = false:
	set(v):
		is_aquatic = v
		_balance_resource_capacity()

@export var respawn_enabled: bool = false
@export var respawn_time: float = 60.0

# ─── Estado Interno ────────────────────────────────────────────────────────────
var current_amount: int = 0
var _respawn_timer: float = 0.0
var is_selected: bool = false
var _selection_ring: MeshInstance3D = null

func _balance_resource_capacity() -> void:
	if resource_type.to_lower() in ["iron", "stone", "gold"]:
		if max_amount == 300 or max_amount < 999999:
			max_amount = 999999
			current_amount = 999999
	elif resource_type.to_lower() == "food" and not is_aquatic:
		if max_amount == 300 or max_amount == 150 or max_amount < 850:
			max_amount = 850
			current_amount = 850

## Propiedad 'resource_capacity' requerida por la suite de balanceo histórico (EE).
## Sincroniza max_amount y current_amount.
var resource_capacity: int:
	get:
		return max_amount
	set(val):
		max_amount = val
		current_amount = val

# ─── Gestión de Cupos (Máximo 6 Aldeanos por Recurso) ─────────────────────────
const MAX_GATHERERS: int = 6
var assigned_gatherers: Array[Node] = []

func request_gather_slot(villager: Node) -> Dictionary:
	_clean_assigned_gatherers()

	# Si ya tiene cupo asignado previamente
	var existing_idx := assigned_gatherers.find(villager)
	if existing_idx != -1:
		return {
			"has_slot": true,
			"slot_index": existing_idx,
			"slot_pos": get_slot_position(existing_idx)
		}

	# Si hay cupo libre (< 6)
	if assigned_gatherers.size() < MAX_GATHERERS:
		assigned_gatherers.append(villager)
		var slot_idx := assigned_gatherers.size() - 1
		return {
			"has_slot": true,
			"slot_index": slot_idx,
			"slot_pos": get_slot_position(slot_idx)
		}

	# Si está lleno (6/6), calcular posición de espera a distancia (6.5m)
	var wait_ang: float = randf() * TAU
	var wait_pos: Vector3 = global_position + Vector3(cos(wait_ang), 0.0, sin(wait_ang)) * 6.5
	return {
		"has_slot": false,
		"wait_pos": wait_pos
	}

func release_gather_slot(villager: Node) -> void:
	if assigned_gatherers.has(villager):
		assigned_gatherers.erase(villager)

func get_slot_position(slot_idx: int) -> Vector3:
	var angle := float(slot_idx) * (TAU / float(MAX_GATHERERS))
	var slot_radius := 1.45 # Distancia justa y cercana (máximo 1.8m del nodo real para erradicar tala flotante)
	return global_position + Vector3(cos(angle), 0.0, sin(angle)) * slot_radius

func _clean_assigned_gatherers() -> void:
	var valid: Array[Node] = []
	for g in assigned_gatherers:
		if is_instance_valid(g):
			valid.append(g)
	assigned_gatherers = valid

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_balance_resource_capacity()
	current_amount = max_amount
	add_to_group("resources")
	add_to_group("resources_3d")
	
	# Habilitar detección de eventos de entrada (mouse clicks en 3D)
	input_ray_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

	# Generar mallas 3D y colisionadores procedurales si no existen
	_ensure_visual_mesh_and_collision()

	# Conectar a la señal global de Eras
	var tree_inst := get_tree() if is_inside_tree() else null
	var rm: Node = tree_inst.root.get_node_or_null("ResourceManager") if tree_inst and tree_inst.root else null
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _ensure_visual_mesh_and_collision() -> void:
	# 1. Malla 3D procedural por tipo de recurso
	var has_mesh: bool = false
	for child in get_children():
		if child is MeshInstance3D:
			has_mesh = true
			break

	if not has_mesh:
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Primitive_Mesh"

		var mat := StandardMaterial3D.new()
		match resource_type.to_lower():
			"wood":
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.4
				cyl.bottom_radius = 0.8
				cyl.height = 3.5
				mesh_inst.mesh = cyl
				mat.albedo_color = Color(0.18, 0.49, 0.20) # Verde Bosque
			"gold":
				var gltf_path := "res://assets/models/era0/mina_de_oro.glb"
				var loaded_glb := false
				if ResourceLoader.exists(gltf_path):
					var pscene := load(gltf_path) as PackedScene
					if pscene:
						var inst := pscene.instantiate() as Node3D
						if is_instance_valid(inst):
							# Use the instanced GLB instead of MeshInstance3D primitive
							inst.name = "Primitive_Mesh"
							add_child(inst)
							mesh_inst.queue_free() # We don't need the generic one
							mesh_inst = null
							loaded_glb = true

				if not loaded_glb and is_instance_valid(mesh_inst):
					var prism := PrismMesh.new()
					prism.size = Vector3(1.6, 1.8, 1.6)
					mesh_inst.mesh = prism
					mat.albedo_color = Color(1.0, 0.82, 0.25) # Dorado brillante
					mat.emission_enabled = true
					mat.emission = Color(0.8, 0.6, 0.1)
					mat.emission_energy_multiplier = 0.4
			"iron":
				var box := BoxMesh.new()
				box.size = Vector3(1.6, 1.4, 1.6)
				mesh_inst.mesh = box
				mat.albedo_color = Color(0.47, 0.56, 0.61) # Gris Hierro Metalizado
			"stone":
				var sph := SphereMesh.new()
				sph.radius = 0.9
				sph.height = 1.6
				mesh_inst.mesh = sph
				mat.albedo_color = Color(0.38, 0.38, 0.38) # Gris Piedra
			"food":
				var sph := SphereMesh.new()
				sph.radius = 0.8
				sph.height = 1.4
				mesh_inst.mesh = sph
				mat.albedo_color = Color(0.85, 0.20, 0.18) # Rojo Bayas
			_:
				var box := BoxMesh.new()
				box.size = Vector3(1.2, 1.2, 1.2)
				mesh_inst.mesh = box
				mat.albedo_color = Color(0.7, 0.7, 0.7)

		if is_instance_valid(mesh_inst):
			mesh_inst.material_override = mat
			add_child(mesh_inst)

	# 2. Colisionador 3D para raycast y clics
	var has_col: bool = false
	for child in get_children():
		if child is CollisionShape3D:
			has_col = true
			break

	if not has_col:
		var col := CollisionShape3D.new()
		var cyl_shape := CylinderShape3D.new()
		match resource_type.to_lower():
			"wood":
				cyl_shape.radius = 0.45
				cyl_shape.height = 3.5
			"food":
				cyl_shape.radius = 0.45
				cyl_shape.height = 1.4
			"stone":
				cyl_shape.radius = 0.65
				cyl_shape.height = 1.6
			"iron":
				cyl_shape.radius = 0.65
				cyl_shape.height = 1.5
			"gold":
				cyl_shape.radius = 0.65
				cyl_shape.height = 1.8
			_:
				cyl_shape.radius = 0.55
				cyl_shape.height = 2.0
		col.shape = cyl_shape
		add_child(col)

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var era_val: int = 0
	if nueva_era != null and nueva_era is int:
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)
	else:
		var tree_inst := get_tree() if is_inside_tree() else null
		var rm: Node = tree_inst.root.get_node_or_null("ResourceManager") if tree_inst and tree_inst.root else null
		if is_instance_valid(rm) and "era_actual" in rm:
			era_val = int(rm.era_actual)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	var target_key: String = "Primitive_Mesh"
	var legacy_key := "EraMesh_PrimitiveNode"
	match era_val:
		0, 1, 2:
			target_key = "Primitive_Mesh"
			legacy_key = "EraMesh_PrimitiveNode"
		3, 4, 5:
			target_key = "Historical_Mesh"
			legacy_key = "EraMesh_IndustrialNode"
		6, 7:
			target_key = "Industrial_Mesh"
			legacy_key = "EraMesh_IndustrialNode"
		8, 9:
			target_key = "Futuristic_Mesh"
			legacy_key = "EraMesh_QuantumNode"

	for child in get_children():
		if child is MeshInstance3D:
			if child.name.contains(target_key) or child.name == legacy_key:
				child.visible = true
			elif child.name.begins_with("EraMesh_"):
				child.visible = false

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true

func select() -> void:
	is_selected = true
	_show_selection_indicator(true)

func deselect() -> void:
	is_selected = false
	_show_selection_indicator(false)

func _show_selection_indicator(visible_state: bool) -> void:
	if not is_instance_valid(_selection_ring):
		_selection_ring = MeshInstance3D.new()
		_selection_ring.name = "SelectionRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 1.3
		torus.outer_radius = 1.55
		_selection_ring.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.85, 0.25, 0.9) # Amarillo dorado brillante
		_selection_ring.material_override = mat
		_selection_ring.position = Vector3(0.0, 0.08, 0.0)
		add_child(_selection_ring)
	_selection_ring.visible = visible_state

func _process(delta: float) -> void:
	if is_depleted() and respawn_enabled:
		_respawn_timer += delta
		if _respawn_timer >= respawn_time:
			_respawn()

# ─── Interfaz de Extracción ────────────────────────────────────────────────────

func get_resource_type() -> String:
	return resource_type

func extract(amount: int) -> int:
	if is_depleted():
		return 0
	var extracted := mini(amount, current_amount)
	current_amount -= extracted
	amount_changed.emit(current_amount, max_amount)
	
	if is_depleted():
		_on_depleted()
		
	return extracted

func is_depleted() -> bool:
	return current_amount <= 0

# ─── Interacción RTS mediante Clic ─────────────────────────────────────────────

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var sm: Node = get_node_or_null("/root/SelectionManager")
			if is_instance_valid(sm) and sm.has_method("select_units"):
				sm.select_units([self])
		# Clic derecho: orden directa de recolección RTS
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_send_selected_villagers_to_gather()

func _send_selected_villagers_to_gather() -> void:
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if not is_instance_valid(sm) or not ("selected_units" in sm):
		return
		
	for unit_node in sm.selected_units:
		if is_instance_valid(unit_node):
			if unit_node.has_method("command_gather"):
				unit_node.command_gather(self)

# ─── Agotamiento y Respawn ─────────────────────────────────────────────────────

func _on_depleted() -> void:
	depleted.emit(self)
	
	# Feedback visual: ocultar visuales o cambiar transparencia
	var visual_mesh := find_child("*Mesh*", true, false) as VisualInstance3D
	if is_instance_valid(visual_mesh):
		visual_mesh.visible = false
		
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
		
	if not respawn_enabled:
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _respawn() -> void:
	_respawn_timer = 0.0
	current_amount = max_amount
	
	var visual_mesh := find_child("*Mesh*", true, false) as VisualInstance3D
	if is_instance_valid(visual_mesh):
		visual_mesh.visible = true
		
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
		
	amount_changed.emit(current_amount, max_amount)
