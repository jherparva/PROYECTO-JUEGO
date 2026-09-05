## Bridge3D — Puente Evolutivo Sobre Ríos y Canales 3D (GDScript 2.0 / Godot 4).
##
## Permite el cruce de unidades terrestres (infantería, tanques, aldeanos) sobre valles de agua profunda (-1.8m).
## Conmuta síncronamente su malla 3D según el bloque de Eras del Imperio Host.

class_name Bridge3D
extends StaticBody3D

signal era_changed(nueva_era: int)

# ─── Configuración de Puente ───────────────────────────────────────────────────
@export var width: float = 6.0
@export var length: float = 18.0
@export var current_era: int = 0

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("bridges")
	add_to_group("bridges_3d")

	_ensure_collision_platform()
	_ensure_procedural_era_meshes()

	# Conectar a la señal global de cambio de era
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
			if "era_actual" in rm:
				current_era = int(rm.era_actual)

	_actualizar_modelo_visual_era(current_era)

	# El rebake de NavMesh ahora se hace centralizado desde el spawner al terminar de crear todos los puentes
	# para evitar horneados simultáneos costosos.

# ─── NavMesh Runtime Rebake ───────────────────────────────────────────────────

## Busca el NavigationRegion3D del mapa y solicita un re-horneado asíncrono.
## Registra la plataforma del puente como terreno caminable para NavigationAgent3D.
func _rebake_nav_region() -> void:
	# Búsqueda del NavigationRegion3D raíz del mapa
	var nav_region: NavigationRegion3D = null

	# Intento 1: Buscarlo en el grupo "navigation_region"
	var region_in_group: Node = get_tree().get_first_node_in_group("navigation_region")
	if is_instance_valid(region_in_group) and region_in_group is NavigationRegion3D:
		nav_region = region_in_group as NavigationRegion3D

	# Intento 2: Buscarlo en la escena actual por tipo
	if not is_instance_valid(nav_region) and get_tree().current_scene:
		nav_region = _find_nav_region_recursive(get_tree().current_scene)

	if is_instance_valid(nav_region):
		# false = horneado ASÍNCRONO en hilo de fondo — no congela la simulación
		nav_region.bake_navigation_mesh(false)
		print("Bridge3D '%s': ✅ NavigationRegion3D re-horneado asincrónamente — plataforma registrada como terreno caminable." % name)
	else:
		print("Bridge3D '%s': ⚠️ NavigationRegion3D no encontrado. Los agentes navegarán sin el puente hasta el siguiente mapa." % name)

func _find_nav_region_recursive(node: Node) -> NavigationRegion3D:
	if node is NavigationRegion3D:
		return node as NavigationRegion3D
	for child in node.get_children():
		var result := _find_nav_region_recursive(child)
		if is_instance_valid(result):
			return result
	return null


func _ensure_collision_platform() -> void:
	if not is_instance_valid(collision_shape):
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(width, 0.4, length)
		col.shape = box
		col.position = Vector3(0.0, 0.1, 0.0) # Plataforma justo sobre el nivel acuático
		add_child(col)
		collision_shape = col

# ─── Mallas Procedurales y Swap de Eras ───────────────────────────────────────

func _ensure_procedural_era_meshes() -> void:
	# 1. Eras 0-2: Pontones de Troncos y Cuerdas (Primitivo)
	if not get_node_or_null("Primitive_Bridge_Mesh"):
		var inst := MeshInstance3D.new()
		inst.name = "Primitive_Bridge_Mesh"
		var box := BoxMesh.new()
		box.size = Vector3(width, 0.35, length)
		inst.mesh = box
		inst.position = Vector3(0.0, 0.05, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.40, 0.26, 0.13) # Madera tosca
		mat.roughness = 0.95
		inst.material_override = mat
		add_child(inst)

	# 2. Eras 3-5: Puente de Arco de Piedra Medieval (Histórico)
	if not get_node_or_null("Historical_Bridge_Mesh"):
		var inst := MeshInstance3D.new()
		inst.name = "Historical_Bridge_Mesh"
		var box := BoxMesh.new()
		box.size = Vector3(width * 1.1, 0.45, length)
		inst.mesh = box
		inst.position = Vector3(0.0, 0.10, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.50, 0.50, 0.52) # Sillar de Piedra
		mat.roughness = 0.70
		inst.material_override = mat
		add_child(inst)

	# 3. Eras 6-7: Viaducto de Vigas de Hierro Industrial (Industrial)
	if not get_node_or_null("Industrial_Bridge_Mesh"):
		var inst := MeshInstance3D.new()
		inst.name = "Industrial_Bridge_Mesh"
		var box := BoxMesh.new()
		box.size = Vector3(width * 1.15, 0.50, length)
		inst.mesh = box
		inst.position = Vector3(0.0, 0.12, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.30, 0.32, 0.36) # Hierro forjado remachado
		mat.metallic = 0.75
		mat.roughness = 0.45
		inst.material_override = mat
		add_child(inst)

	# 4. Eras 8-9: Pasarela de Repulsión Magnética Holográfica (Futurista)
	if not get_node_or_null("Futuristic_Bridge_Mesh"):
		var inst := MeshInstance3D.new()
		inst.name = "Futuristic_Bridge_Mesh"
		var box := BoxMesh.new()
		box.size = Vector3(width * 1.2, 0.30, length)
		inst.mesh = box
		inst.position = Vector3(0.0, 0.15, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.75, 1.0, 0.85) # Cian místico translúcido
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.85, 1.0)
		mat.emission_energy_multiplier = 1.6
		inst.material_override = mat
		add_child(inst)

# ─── Respuesta a Cambio de Era ─────────────────────────────────────────────────

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var era_val: int = 0
	if nueva_era != null and nueva_era is int:
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)
	else:
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and "era_actual" in rm:
			era_val = int(rm.era_actual)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	current_era = era_val
	era_changed.emit(era_val)

	var target_key: String = "Primitive_Bridge_Mesh"
	match era_val:
		0, 1, 2:
			target_key = "Primitive_Bridge_Mesh"
		3, 4, 5:
			target_key = "Historical_Bridge_Mesh"
		6, 7:
			target_key = "Industrial_Bridge_Mesh"
		8, 9:
			target_key = "Futuristic_Bridge_Mesh"

	for child in get_children():
		if child is MeshInstance3D:
			if child.name.contains(target_key) or child.name.begins_with("EraBridge_"):
				child.visible = true
			elif child.name.ends_with("_Bridge_Mesh"):
				child.visible = false
