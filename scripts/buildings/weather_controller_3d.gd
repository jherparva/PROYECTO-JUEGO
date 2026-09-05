## WeatherController3D — Estación de Control Climático (GDScript 2.0 / Godot 4).
##
## Edificio tecnológico de Era 9 (Nano-Futurista) que proyecta un Escudo Climático esférico
## pasivo de 40 metros. Intercepta los desastres climáticos de Prophet3D rivales (terremotos,
## plagas, tormentas) y reduce el daño por tiempo (DoT) entrante un 80% para todos los
## aliados dentro del domo.
##
## MECÁNICA:
## - Area3D esférica pasiva detecta objetos con el grupo "weather_disaster" que entren al domo.
## - Al detectarlos, inyecta un modificador de daño de 0.20 (80% de reducción).
## - Al salir del domo, restaura el modificador de daño original.
## - El indicador de domo (MeshInstance3D esférico holográfico) pulsa visualmente.

class_name WeatherController3D
extends "res://scripts/buildings/building_base_3d.gd"

# ─── Constantes ────────────────────────────────────────────────────────────────
const SHIELD_RADIUS: float      = 40.0
const DAMAGE_REDUCTION: float   = 0.80   # 80% de mitigación → el aliado recibe solo 20% del DoT
const SHIELD_MODIFIER: float    = 1.0 - DAMAGE_REDUCTION   # = 0.20

const DOME_COLOR_IDLE:   Color  = Color(0.0, 0.85, 1.0, 0.12)   # Azul neón translúcido
const DOME_COLOR_ACTIVE: Color  = Color(1.0, 0.55, 0.0, 0.28)   # Naranja alerta al interceptar

# ─── Referencias Internas ──────────────────────────────────────────────────────
var _shield_area:   Area3D          = null
var _dome_mesh:     MeshInstance3D  = null
var _dome_material: StandardMaterial3D = null

## Diccionario de modificadores originales de las entidades aliadas en el domo.
## Clave: NodePath de la entidad  |  Valor: float modificador original
var _shielded_entities: Dictionary  = {}

## Desastres climáticos activos actualmente dentro del domo (referencia débil).
var _active_disasters: Array[Node]  = []

var _pulse_tween: Tween = null

# ─── Inicialización ────────────────────────────────────────────────────────────

func _init() -> void:
	building_name  = "Estación de Control Climático"
	salud_maxima   = 1500.0
	salud_actual   = 1500.0
	radio_vision   = 45.0

func _ready() -> void:
	super._ready()
	add_to_group("weather_controllers")
	add_to_group("weather_controllers_3d")

	_setup_shield_area()
	_setup_dome_visual()
	print("WeatherController3D '%s': Escudo Climático activo. Radio = %.0fm." % [name, SHIELD_RADIUS])

# ─── Escudo: Area3D Esférica ───────────────────────────────────────────────────

func _setup_shield_area() -> void:
	_shield_area = Area3D.new()
	_shield_area.name = "ShieldArea"
	# Solo colisiona con la capa 1 (terreno) + 2 (unidades) para no interferir con físicas
	_shield_area.collision_layer = 0
	_shield_area.collision_mask  = 0b11111111  # Detecta todo

	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = SHIELD_RADIUS

	var col_shape := CollisionShape3D.new()
	col_shape.shape = sphere_shape
	_shield_area.add_child(col_shape)

	add_child(_shield_area)

	# Señales de detección
	_shield_area.area_entered.connect(_on_shield_area_entered)
	_shield_area.area_exited.connect(_on_shield_area_exited)
	_shield_area.body_entered.connect(_on_shield_body_entered)
	_shield_area.body_exited.connect(_on_shield_body_exited)

# ─── Domo Visual Holográfico ───────────────────────────────────────────────────

func _setup_dome_visual() -> void:
	_dome_mesh = MeshInstance3D.new()
	_dome_mesh.name = "DomeMesh"

	var sphere := SphereMesh.new()
	sphere.radius = SHIELD_RADIUS
	sphere.height = SHIELD_RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	_dome_mesh.mesh = sphere

	_dome_material = StandardMaterial3D.new()
	_dome_material.transparency          = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dome_material.albedo_color          = DOME_COLOR_IDLE
	_dome_material.emission_enabled      = true
	_dome_material.emission              = Color(0.0, 0.6, 1.0)
	_dome_material.emission_energy_multiplier = 0.3
	_dome_material.shading_mode          = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dome_material.cull_mode             = BaseMaterial3D.CULL_BACK
	_dome_mesh.material_override         = _dome_material

	add_child(_dome_mesh)
	_start_idle_pulse()

func _start_idle_pulse() -> void:
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_dome_material, "albedo_color:a", 0.22, 1.8)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_dome_material, "albedo_color:a", 0.06, 1.8)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _set_dome_alert(is_alert: bool) -> void:
	if not is_instance_valid(_dome_material):
		return
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()

	if is_alert:
		# Pulso rápido naranja: desastre activo interceptado
		_dome_material.albedo_color = DOME_COLOR_ACTIVE
		_dome_material.emission     = Color(1.0, 0.45, 0.0)
		_dome_material.emission_energy_multiplier = 0.9
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(_dome_material, "albedo_color:a", 0.4, 0.4)\
				.set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(_dome_material, "albedo_color:a", 0.15, 0.4)\
				.set_ease(Tween.EASE_IN_OUT)
	else:
		_dome_material.albedo_color = DOME_COLOR_IDLE
		_dome_material.emission     = Color(0.0, 0.6, 1.0)
		_dome_material.emission_energy_multiplier = 0.3
		_start_idle_pulse()

# ─── Interceptación de Desastres Climáticos ───────────────────────────────────

## Aplica el escudo a todos los aliados dentro del radio en el momento de la colisión.
func _interceptar_desastre(disaster_node: Node) -> void:
	if not is_instance_valid(disaster_node):
		return
	if _active_disasters.has(disaster_node):
		return

	_active_disasters.append(disaster_node)
	_set_dome_alert(true)

	print("WeatherController3D '%s': ¡Desastre climático '%s' INTERCEPTADO! Escudo al %.0f%%." \
			% [name, disaster_node.name, DAMAGE_REDUCTION * 100.0])

	# Aplicar modificador de daño reducido a todos los aliados en el domo
	_apply_shield_to_allies_in_dome()

	# Notificación al jugador
	var notif: Node = get_tree().get_first_node_in_group("rts_notification_manager")
	if is_instance_valid(notif) and notif.has_method("agregar_notificacion"):
		notif.call("agregar_notificacion",
			"🛡️ ¡ESCUDO CLIMÁTICO activado! Daño reducido un 80% en radio de %.0fm." % SHIELD_RADIUS,
			1, global_position)

func _liberar_desastre(disaster_node: Node) -> void:
	if not _active_disasters.has(disaster_node):
		return

	_active_disasters.erase(disaster_node)
	print("WeatherController3D '%s': Desastre '%s' abandonó el domo." \
			% [name, disaster_node.name if is_instance_valid(disaster_node) else "???"])

	# Si ya no hay desastres activos, restaurar modificadores y estado visual
	if _active_disasters.is_empty():
		_restore_all_shields()
		_set_dome_alert(false)

# ─── Gestión del Modificador de Daño en Entidades Aliadas ─────────────────────

func _apply_shield_to_allies_in_dome() -> void:
	var allied_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
	var allied_bld_group := "player_buildings" if bando == Bando.PLAYER else "enemy_buildings"

	for entity in get_tree().get_nodes_in_group(allied_group) + get_tree().get_nodes_in_group(allied_bld_group):
		if not is_instance_valid(entity) or not entity is Node3D:
			continue
		var dist := global_position.distance_to((entity as Node3D).global_position)
		if dist > SHIELD_RADIUS:
			continue
		_apply_shield_modifier(entity)

func _apply_shield_modifier(entity: Node) -> void:
	var entity_path := entity.get_path()
	# Guardar modificador original solo si no está ya escudado
	if not _shielded_entities.has(entity_path):
		var original_mod: float = 1.0
		if "damage_modifier" in entity:
			original_mod = float(entity.damage_modifier)
		_shielded_entities[entity_path] = original_mod
		# Aplicar reducción del 80%: multiplicar el modificador por 0.20
		if "damage_modifier" in entity:
			entity.damage_modifier = original_mod * SHIELD_MODIFIER

func _restore_shield_modifier(entity_path: NodePath) -> void:
	if not _shielded_entities.has(entity_path):
		return
	var entity: Node = get_node_or_null(entity_path)
	if is_instance_valid(entity) and "damage_modifier" in entity:
		entity.damage_modifier = float(_shielded_entities[entity_path])
	_shielded_entities.erase(entity_path)

func _restore_all_shields() -> void:
	for entity_path in _shielded_entities.keys():
		_restore_shield_modifier(entity_path)
	_shielded_entities.clear()
	print("WeatherController3D '%s': Escudo desactivado. Modificadores restaurados." % name)

# ─── Callbacks de Detección del Area3D ───────────────────────────────────────

## Detecta áreas enemigas (desastres climáticos Area3D) que entren al domo.
func _on_shield_area_entered(area: Area3D) -> void:
	if not is_instance_valid(area):
		return
	# Identificar si el área es un desastre climático enemigo
	if _is_enemy_weather_disaster(area):
		_interceptar_desastre(area)

func _on_shield_area_exited(area: Area3D) -> void:
	if not is_instance_valid(area):
		return
	if _active_disasters.has(area):
		_liberar_desastre(area)

## Detecta cuerpos de desastre climático basados en StaticBody3D/RigidBody3D.
func _on_shield_body_entered(body: Node3D) -> void:
	if not is_instance_valid(body):
		return
	if _is_enemy_weather_disaster(body):
		_interceptar_desastre(body)

func _on_shield_body_exited(body: Node3D) -> void:
	if not is_instance_valid(body):
		return
	if _active_disasters.has(body):
		_liberar_desastre(body)

# ─── Helper: Identificar Desastre Climático Enemigo ──────────────────────────

func _is_enemy_weather_disaster(node: Node) -> bool:
	if not is_instance_valid(node):
		return false

	# Criterio 1: Grupo explícito "weather_disaster" (registrado por Prophet3D)
	if node.is_in_group("weather_disaster") or node.is_in_group("climate_disaster"):
		# Verificar que es del enemigo
		if "bando" in node:
			var disaster_bando: int = int(node.bando)
			var my_bando: int = int(bando)
			return disaster_bando != my_bando
		return true  # Sin bando definido: interceptar igualmente

	# Criterio 2: Nombre de nodo con sufijos de desastre conocidos
	var disaster_keywords := ["Earthquake", "Plague", "Storm", "Flood", "Terremoto",
							  "Plaga", "Tormenta", "Inundacion", "WeatherZone"]
	for keyword in disaster_keywords:
		if node.name.contains(keyword):
			return true

	return false

# ─── Proceso: Vigilancia Activa de Entidades en el Domo ──────────────────────

## Cada 2 segundos re-escaneamos el domo para capturar unidades que entraron
## entre callbacks (por ejemplo unidades que se mueven hacia el centro).
var _rescan_timer: float = 0.0
const RESCAN_INTERVAL: float = 2.0

func _process(delta: float) -> void:
	if is_dead or is_under_construction:
		return
	if _active_disasters.is_empty():
		return

	_rescan_timer += delta
	if _rescan_timer >= RESCAN_INTERVAL:
		_rescan_timer = 0.0
		_apply_shield_to_allies_in_dome()

	# Limpiar referencias de desastres destruidos
	for disaster in _active_disasters.duplicate():
		if not is_instance_valid(disaster):
			_active_disasters.erase(disaster)
	if _active_disasters.is_empty():
		_restore_all_shields()
		_set_dome_alert(false)

# ─── Destrucción ──────────────────────────────────────────────────────────────

func morir() -> void:
	_restore_all_shields()
	_active_disasters.clear()
	if is_instance_valid(_dome_mesh):
		_dome_mesh.visible = false
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	super.morir() if super.has_method("morir") else null
