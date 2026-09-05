## WallGate3D — Puerta Inteligente de Muralla 3D (GDScript 2.0 / Godot 4).
##
## Edificio de paso fortificado que detecta la proximidad de unidades aliadas
## para abrir paso automáticamente, y se bloquea de forma sólida ante unidades enemigas.

class_name WallGate3D
extends "res://scripts/buildings/building_base_3d.gd"

signal gate_opened
signal gate_closed

# ─── Configuración de Puerta ───────────────────────────────────────────────────
var is_gate_open: bool = false
var allies_in_range: Array[Node3D] = []

@onready var detection_area: Area3D = get_node_or_null("DetectionArea") as Area3D
@onready var gate_collision: CollisionShape3D = get_node_or_null("GateCollision") as CollisionShape3D
@onready var left_door_mesh: Node3D = get_node_or_null("LeftDoor") as Node3D
@onready var right_door_mesh: Node3D = get_node_or_null("RightDoor") as Node3D

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Puerta Fortificada"
	salud_maxima = 1200.0
	salud_actual = 1200.0

func _ready() -> void:
	super._ready()
	add_to_group("gates")
	add_to_group("gates_3d")
	add_to_group("walls_3d")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	# Si no existe Area3D de detección, crearla dinámicamente
	if not is_instance_valid(detection_area):
		detection_area = Area3D.new()
		detection_area.name = "DetectionArea"
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(8.0, 4.0, 8.0)
		col.shape = box
		detection_area.add_child(col)
		add_child(detection_area)

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	_ensure_procedural_gate_meshes()

	# Conectar a la señal global de eras
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
			if "era_actual" in rm:
				_actualizar_modelo_visual_era(int(rm.era_actual))

# ─── Mallas Procedurales y Swap por Eras ───────────────────────────────────────

func _ensure_procedural_gate_meshes() -> void:
	if not is_instance_valid(left_door_mesh):
		var left_node := MeshInstance3D.new()
		left_node.name = "LeftDoor"
		var box := BoxMesh.new()
		box.size = Vector3(2.8, 3.5, 0.4)
		left_node.mesh = box
		left_node.position = Vector3(-1.4, 1.75, 0.0)
		add_child(left_node)
		left_door_mesh = left_node

	if not is_instance_valid(right_door_mesh):
		var right_node := MeshInstance3D.new()
		right_node.name = "RightDoor"
		var box := BoxMesh.new()
		box.size = Vector3(2.8, 3.5, 0.4)
		right_node.mesh = box
		right_node.position = Vector3(1.4, 1.75, 0.0)
		add_child(right_node)
		right_door_mesh = right_node

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return
	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	var target_key: String = "Primitive_Gate_Mesh"
	var mat := StandardMaterial3D.new()

	match era_val:
		0, 1, 2: # Primitivo: Empalizadas de troncos amarrados y portones de madera tosca
			target_key = "Primitive_Gate_Mesh"
			mat.albedo_color = Color(0.42, 0.28, 0.15) # Madera tosca
			mat.roughness = 0.95
			building_name = "Portón de Troncos y Empalizada"
		3, 4, 5: # Histórico: Murallas de sillar y rastrillos de hierro forjado
			target_key = "Historical_Gate_Mesh"
			mat.albedo_color = Color(0.28, 0.28, 0.30) # Hierro forjado
			mat.metallic = 0.65
			building_name = "Puerta Fortificada de Piedra y Hierro"
		6, 7: # Industrial: Hormigón armado, alambre de espino y compuertas de acero remachado
			target_key = "Industrial_Gate_Mesh"
			mat.albedo_color = Color(0.32, 0.35, 0.40) # Acero industrial
			mat.metallic = 0.85
			mat.roughness = 0.35
			building_name = "Compuerta de Hormigón y Acero Blindado"
		8, 9: # Futurista: Postes de nanocompuesto que proyectan barreras láser cian
			target_key = "Futuristic_Gate_Mesh"
			mat.albedo_color = Color(0.0, 0.85, 1.0, 0.85) # Barrera láser cian
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.9, 1.0)
			mat.emission_energy_multiplier = 2.0
			building_name = "Barrera Láser y Campo de Fuerza"

	# Aplicar material actualizado a los portones
	if is_instance_valid(left_door_mesh) and left_door_mesh is MeshInstance3D:
		(left_door_mesh as MeshInstance3D).material_override = mat
	if is_instance_valid(right_door_mesh) and right_door_mesh is MeshInstance3D:
		(right_door_mesh as MeshInstance3D).material_override = mat

	# Swap de mallas importadas si existen
	for child in get_children():
		if child is MeshInstance3D:
			if child.name.contains(target_key) or child.name.begins_with("EraMesh_"):
				child.visible = true
			elif child.name.ends_with("_Gate_Mesh") or child.name.ends_with("_Wall_Mesh"):
				child.visible = false

# ─── Detección de Proximidad y Control de Acceso ──────────────────────────────

func _on_body_entered(body: Node) -> void:
	if is_dead or is_under_construction or not (body is Node3D):
		return

	# Verificar si es una unidad aliada del jugador
	var is_ally := false
	if bando == Bando.PLAYER and (body.is_in_group("player_units") or body.is_in_group("unidades")):
		is_ally = true
	elif bando == Bando.ENEMY and body.is_in_group("enemy_units"):
		is_ally = true

	if is_ally:
		var ally_node := body as Node3D
		if not allies_in_range.has(ally_node):
			allies_in_range.append(ally_node)
		if not is_gate_open:
			abrir_puerta()

func _on_body_exited(body: Node) -> void:
	if body is Node3D:
		allies_in_range.erase(body as Node3D)

	# Limpiar referencias nulas o muertas
	allies_in_range = allies_in_range.filter(func(n): return is_instance_valid(n) and not (n.has_method("is_dead") and n.call("is_dead")))

	if allies_in_range.is_empty() and is_gate_open:
		cerrar_puerta()

# ─── Animación y Colisión de Puerta ────────────────────────────────────────────

func abrir_puerta() -> void:
	if is_gate_open:
		return
	is_gate_open = true

	# Desactivar colisión física para permitir el paso
	if is_instance_valid(gate_collision):
		gate_collision.disabled = true

	# Animación visual de apertura vía Tween
	var tween := create_tween().set_parallel(true)
	if is_instance_valid(left_door_mesh):
		tween.tween_property(left_door_mesh, "rotation_degrees:y", 90.0, 0.5)
	if is_instance_valid(right_door_mesh):
		tween.tween_property(right_door_mesh, "rotation_degrees:y", -90.0, 0.5)

	gate_opened.emit()
	print("WallGate3D '%s': Puerta abierta para aliados." % name)

func cerrar_puerta() -> void:
	if not is_gate_open:
		return
	is_gate_open = false

	# Reactivar colisión física para bloquear enemigos
	if is_instance_valid(gate_collision):
		gate_collision.disabled = false

	var tween := create_tween().set_parallel(true)
	if is_instance_valid(left_door_mesh):
		tween.tween_property(left_door_mesh, "rotation_degrees:y", 0.0, 0.5)
	if is_instance_valid(right_door_mesh):
		tween.tween_property(right_door_mesh, "rotation_degrees:y", 0.0, 0.5)

	gate_closed.emit()
	print("WallGate3D '%s': Puerta cerrada y bloqueada." % name)
