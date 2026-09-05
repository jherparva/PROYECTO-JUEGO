## RTSResourceSpawner — Generador Procedural de Terreno y Recursos RTS (GDScript 2.0 / Godot 4).
##
## Genera mapas 3D procedurales y equilibrados mediante FastNoiseLite:
## - Elevación por Ruido Coherente (Colinas tácticas para +25% daño y valles navegables para Dock3D).
## - Spawn inicial garantizado (1 Oro, 1 Hierro, 2 Comida, Bosque de Madera) a 15-30m de cada TownCenter3D.
## - Yacimientos neutrales de alto valor en el centro del mapa para incentivar el control territorial.

class_name RTSResourceSpawner
extends Node3D

signal map_generation_completed()

# ─── Configuración de Semilla y Ruido FastNoiseLite ───────────────────────────
@export_group("Generación FastNoiseLite")
@export var seed_value: int = 1337
@export var map_size_x: float = 300.0
@export var map_size_z: float = 300.0
@export var elevation_amplitude: float = 6.0 # Cota Y máxima para colinas

@export_group("Recursos Iniciales Garantizados")
@export var min_tc_radius: float = 15.0
@export var max_tc_radius: float = 30.0

var noise: FastNoiseLite = null
var _resource_scene: PackedScene = null

var biome_mode: int = 0 # 0=Continental, 1=Islas, 2=Planicie

func _get_tree_safe() -> SceneTree:
	if is_inside_tree() and get_tree() != null:
		return get_tree()
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		return ml as SceneTree
	return null

func _ready() -> void:
	add_to_group("resource_spawner")
	if ResourceLoader.exists("res://scenes/world/resource_node_3d.tscn"):
		_resource_scene = load("res://scenes/world/resource_node_3d.tscn")
	_read_game_settings_config()
	_setup_fastnoise()
	call_deferred("generar_mapa_equilibrado")

func _read_game_settings_config() -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(gs):
		return

	# ── 1. Semilla Aleatoria Única (mapa diferente cada partida) ────────────────────────────────
	# Se lee 'map_seed' de GameSettings (generada en el lobby con randi()).
	# Si no existe, se genera una nueva semilla aleatoria como fallback.
	if "map_seed" in gs and int(gs.get("map_seed")) != 0:
		seed_value = int(gs.get("map_seed"))
	else:
		seed_value = randi()
		if is_instance_valid(gs):
			gs.set("map_seed", seed_value)

	# ── 2. Tamaño del Mapa (0=Pequeño 1=Mediano 2=Grande 3=Gigante) ─────────────────────
	var size_preset: int = int(gs.get("map_size_preset")) if "map_size_preset" in gs else 1
	match size_preset:
		0: # Pequeño: ideal para 2 jugadores (partidas rápidas)
			map_size_x = 150.0
			map_size_z = 150.0
		2: # Grande: ideal para 4 jugadores (guerras de 40+ minutos)
			map_size_x = 600.0
			map_size_z = 600.0
		3: # Gigante: ideal para 6-8 jugadores (campañas epicas)
			map_size_x = 1200.0
			map_size_z = 1200.0
		_: # Mediano (por defecto, 2-4 jugadores)
			map_size_x = 300.0
			map_size_z = 300.0

	# ── 3. Bioma con Parámetros Específicos de Ruido ───────────────────────────────────
	biome_mode = int(gs.get("map_biome")) if "map_biome" in gs else 0
	match biome_mode:
		0: # Continental: Cordilleras masivas que activan bono de altura +25%
			elevation_amplitude = 18.0 # Picos altos — máxima diferencia táctica
		1: # Islas: Valles de agua profunda obligatoria (Y = -1.8m) — fuerza uso de Dock3D
			elevation_amplitude = 5.5  # Islas bajas rodeadas de océano
		2: # Planicie: Terreno plano — combate de tanques y carga de caballeria
			elevation_amplitude = 1.5  # Sin colinas significativas

	print("RTSResourceSpawner: Config leída → Seed: %d | Mapa: %dx%d | Bioma: %d | Amplitud: %.1f" % [
		seed_value, int(map_size_x), int(map_size_z), biome_mode, elevation_amplitude
	])

func _setup_fastnoise() -> void:
	noise = FastNoiseLite.new()
	# Usa la semilla leída ESTRICTAMENTE de GameSettings (inyección forzada de red)
	var gs: Node = get_node_or_null("/root/GameSettings")
	if is_instance_valid(gs) and "map_seed" in gs:
		noise.seed = int(gs.get("map_seed"))
	else:
		noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	# Frecuencia adaptada al tamaño del mapa (mapas grandes necesitan mayor detalle)
	var base_freq: float = 300.0 / maxf(map_size_x, 1.0) * 0.015
	noise.frequency   = clampf(base_freq, 0.008, 0.035)
	noise.fractal_octaves = 5 if map_size_x >= 600.0 else 4 # Más detalle en mapas grandes
	noise.fractal_gain    = 0.5

func calcular_puntos_de_nacimiento(num_slots: int = 8) -> Array[Vector3]:
	var puntos: Array[Vector3] = []
	var radius: float = maxf(map_size_x, map_size_z) * 0.38
	radius = maxf(radius, 85.0) # Separación estricta de bases en el plano XZ (>= 80m - 170m)

	for i in range(num_slots):
		var angulo := (float(i) * TAU) / float(num_slots)
		var x := cos(angulo) * radius
		var z := sin(angulo) * radius
		var y := obtener_altura_terreno(x, z)
		if y < 0.0:
			y = 0.0 # Cota emergida sobre nivel acuático
		puntos.append(Vector3(x, y, z))
	return puntos

# ─── Algoritmo de Generación Procedural Sincronizada ──────────────────────────

func generar_mapa_equilibrado() -> void:
	# Retardo seguro de inicialización (Pre-load Timing Sync):
	# Espera un frame para garantizar que el diccionario de red de GameSettings esté completamente escrito en RAM
	if get_tree():
		await get_tree().process_frame

	_read_game_settings_config()
	_setup_fastnoise()

	print("RTSResourceSpawner: Generando terreno 3D (Dim: %.0fx%.0f, Bioma: %d, Seed: %d)..." % [
		map_size_x, map_size_z, biome_mode, noise.seed
	])

	# ─── PASO 0: Inyección de Era Inicial (Initial Era Injection) ─────────────────
	# Recuperar el valor definitivo de la era configurada desde GameSettings
	var gs: Node = get_node_or_null("/root/GameSettings")
	var era_configurada: int = int(gs.get("starting_era")) if (is_instance_valid(gs) and "starting_era" in gs) else 0

	# Establecer de forma inmediata y global en GlobalResourceManager
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		rm.set("era_actual", era_configurada)
		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", era_configurada)
		if rm.has_method("configurar_balance_recursos_era_inicial"):
			rm.call("configurar_balance_recursos_era_inicial", era_configurada)
		print("RTSResourceSpawner: ✅ Era inicial %d inyectada globalmente con balance de recursos." % era_configurada)

	# Inyectar y forzar actualización visual inmediata en todos los TownCenter3D ya instanciados
	var tree_inst := _get_tree_safe()
	var tc_era_list := tree_inst.get_nodes_in_group("town_centers") if is_instance_valid(tree_inst) else []
	for tc_node in tc_era_list:
		if not is_instance_valid(tc_node):
			continue
		if "era_actual" in tc_node:
			tc_node.set("era_actual", era_configurada)
		if tc_node.has_method("_actualizar_modelo_visual_era"):
			tc_node.call("_actualizar_modelo_visual_era", era_configurada)

	# Inyectar y forzar actualización visual inmediata en todos los aldeanos existentes
	var vil_era_list := tree_inst.get_nodes_in_group("villagers") if is_instance_valid(tree_inst) else []
	for vil_node in vil_era_list:
		if not is_instance_valid(vil_node):
			continue
		if vil_node.has_method("_actualizar_modelo_visual_era"):
			vil_node.call("_actualizar_modelo_visual_era", era_configurada)

	# Purga síncrona inmediata de placeholders de editor en (0, 0, 0)
	_purgar_placeholders_editor()

	# 1. Obtener posiciones de TODOS los Centros Urbanos (TownCenters) dispersos de la partida
	var town_centers: Array[Node] = tree_inst.get_nodes_in_group("town_centers") if is_instance_valid(tree_inst) else []
	if town_centers.is_empty():
		# Fallback: Usar los 8 puntos calculados si aún no se instancian nodos TC
		var puntos := calcular_puntos_de_nacimiento(8)
		for p in puntos:
			_spawn_starting_resources_for_base(p)
	else:
		for tc in town_centers:
			if is_instance_valid(tc) and tc is Node3D:
				_spawn_starting_resources_for_base((tc as Node3D).global_position)

	# 2. Generar Recursos Neutrales de Alto Valor en el Centro y Periferia
	_spawn_neutral_high_value_resources()

	# 3. Instanciar Puentes Evolutivos sobre Ríos y Canales Navegables
	_spawn_cross_water_bridges()

	# 4. Rebake Centralizado del NavMesh (Síncrono/Asíncrono)
	if multiplayer.is_server():
		call_deferred("_centralized_navmesh_rebake")

	print("RTSResourceSpawner: Mapa 3D equilibrado completado con éxito para %d bases." % town_centers.size())
	map_generation_completed.emit()

func _centralized_navmesh_rebake() -> void:
	var tree_inst := _get_tree_safe()
	var nav_region: NavigationRegion3D = null
	if is_instance_valid(tree_inst):
		var region_in_group: Node = tree_inst.get_first_node_in_group("navigation_region")
		if is_instance_valid(region_in_group) and region_in_group is NavigationRegion3D:
			nav_region = region_in_group as NavigationRegion3D
		if not is_instance_valid(nav_region) and tree_inst.current_scene:
			nav_region = _find_nav_region_recursive(tree_inst.current_scene)
		elif not is_instance_valid(nav_region) and tree_inst.root:
			nav_region = _find_nav_region_recursive(tree_inst.root)

	if is_instance_valid(nav_region):
		nav_region.bake_navigation_mesh(false)
		print("RTSResourceSpawner: ✅ NavigationRegion3D re-horneado asincrónamente. Puentes registrados.")
	else:
		print("RTSResourceSpawner: ⚠️ NavigationRegion3D no encontrado para re-horneado.")

func _find_nav_region_recursive(node: Node) -> NavigationRegion3D:
	if node is NavigationRegion3D:
		return node as NavigationRegion3D
	for child in node.get_children():
		var result := _find_nav_region_recursive(child)
		if is_instance_valid(result):
			return result
	return null


# ─── Sistema de Puentes Evolutivos sobre Agua ─────────────────────────────────

func _spawn_cross_water_bridges() -> void:
	var tree_inst := _get_tree_safe()
	var tc_nodes := tree_inst.get_nodes_in_group("town_centers") if is_instance_valid(tree_inst) else []
	if tc_nodes.size() < 2:
		return

	print("RTSResourceSpawner: Escaneando valles de agua profunda para instanciar puentes...")
	var bridge_script = load("res://scripts/world/bridge_3d.gd")
	if not is_instance_valid(bridge_script):
		return

	# Trazar rutas entre capitolios opuestos y colocar puentes si cortan agua profunda (Y < 0.0)
	for i in range(tc_nodes.size()):
		for j in range(i + 1, tc_nodes.size()):
			var p1 := (tc_nodes[i] as Node3D).global_position
			var p2 := (tc_nodes[j] as Node3D).global_position
			var dir := (p2 - p1)
			var dist := dir.length()
			var steps := int(dist / 12.0)

			for s in range(1, steps):
				var check_pos := p1 + (dir.normalized() * (float(s) * 12.0))
				var h := obtener_altura_terreno(check_pos.x, check_pos.z)
				if h < 0.0:
					# Encontrado canal acuático: instanciar Bridge3D si no hay otro cercano
					if not _has_bridge_nearby(check_pos, 25.0):
						var bridge := Bridge3D.new()
						var parent: Node = null
						if is_instance_valid(tree_inst):
							parent = tree_inst.current_scene if tree_inst.current_scene else tree_inst.root
						if not is_instance_valid(parent):
							parent = self
						var bld_container := parent.get_node_or_null("World/Buildings")
						if is_instance_valid(bld_container):
							bld_container.add_child(bridge)
						else:
							parent.add_child(bridge)

						bridge.global_position = Vector3(check_pos.x, 0.0, check_pos.z)
						var rad_ang := atan2(dir.x, dir.z)
						bridge.rotation.y = rad_ang
						print("Bridge3D instanciado en %s (Ángulo: %.2frad)" % [str(bridge.global_position), rad_ang])

func _has_bridge_nearby(pos: Vector3, min_dist: float) -> bool:
	var tree_inst := _get_tree_safe()
	var bridges := tree_inst.get_nodes_in_group("bridges_3d") if is_instance_valid(tree_inst) else []
	for b in bridges:
		if is_instance_valid(b) and b is Node3D:
			if (b as Node3D).global_position.distance_to(pos) < min_dist:
				return true
	return false

# ─── Spawn de Recursos Iniciales Garantizados por Base (15-30m) ───────────────

func _spawn_starting_resources_for_base(tc_pos: Vector3) -> void:
	# A. Bosque Denso de Madera (4 árboles)
	for i in range(4):
		var ang := float(i) * (TAU / 4.0) + randf_range(-0.2, 0.2)
		var pos := tc_pos + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(10.0, 16.0)
		pos.y = obtener_altura_terreno(pos.x, pos.z)
		_instanciar_nodo_recurso("wood", 350, pos)

	# B. 1 Mina de Oro Garantizada
	var gold_ang := randf() * TAU
	var gold_pos := tc_pos + Vector3(cos(gold_ang), 0.0, sin(gold_ang)) * randf_range(12.0, 18.0)
	gold_pos.y = obtener_altura_terreno(gold_pos.x, gold_pos.z)
	_instanciar_nodo_recurso("gold", 999999, gold_pos)

	# C. 1 Veta de Hierro Garantizada
	var iron_ang := gold_ang + PI * 0.75
	var iron_pos := tc_pos + Vector3(cos(iron_ang), 0.0, sin(iron_ang)) * randf_range(14.0, 20.0)
	iron_pos.y = obtener_altura_terreno(iron_pos.x, iron_pos.z)
	_instanciar_nodo_recurso("iron", 999999, iron_pos)

	# D. 2 Parcelas de Alimento (Bayas)
	for k in range(2):
		var berry_ang := gold_ang - PI * 0.6 + float(k) * 0.4
		var berry_pos := tc_pos + Vector3(cos(berry_ang), 0.0, sin(berry_ang)) * randf_range(8.0, 14.0)
		berry_pos.y = obtener_altura_terreno(berry_pos.x, berry_pos.z)
		_instanciar_nodo_recurso("food", 850, berry_pos)

# ─── Spawn de Recursos Neutrales en Centro y Periferia ───────────────────────

func _spawn_neutral_high_value_resources() -> void:
	# Cúmulo Central Neutral (Yacimiento de Gran Escala)
	var center_pos := Vector3.ZERO
	for type in ["gold", "iron", "stone", "wood"]:
		for n in range(3):
			var offset_ang := randf() * TAU
			var offset_dist := randf_range(10.0, 45.0)
			var n_pos := center_pos + Vector3(cos(offset_ang), 0.0, sin(offset_ang)) * offset_dist
			n_pos.y = obtener_altura_terreno(n_pos.x, n_pos.z)
			var qty: int = 999999 if type in ["gold", "iron", "stone"] else 800
			_instanciar_nodo_recurso(type, qty, n_pos)

	# Cardúmenes de Peces Acuáticos (Agua Profunda Y = -1.8m)
	for f in range(4):
		var fish_ang := float(f) * (TAU / 4.0) + randf_range(-0.3, 0.3)
		var fish_pos := Vector3(cos(fish_ang), 0.0, sin(fish_ang)) * randf_range(50.0, 110.0)
		fish_pos.y = -1.8 # Cota acuática
		_instanciar_nodo_recurso("food", 600, fish_pos, true)

	# Manadas de Fauna Salvaje (Servidor)
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_spawn_wild_fauna_clusters()

func _spawn_wild_fauna_clusters() -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	var cur_era: int = int(rm.era_actual) if is_instance_valid(rm) and "era_actual" in rm else 0

	# 1. Manadas Mixtas de Fauna (Tigres Dientes de Sable, Ciervos, Lobos u Osos)
	for cluster in range(3):
		var base_ang := float(cluster) * (TAU / 3.0) + randf_range(-0.4, 0.4)
		var base_dist := randf_range(40.0, 85.0)
		var center_fauna := Vector3(cos(base_ang), 0.0, sin(base_ang)) * base_dist

		for i in range(3):
			var offset := Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
			var spawn_pos := center_fauna + offset
			spawn_pos.y = obtener_altura_terreno(spawn_pos.x, spawn_pos.z)
			if spawn_pos.y >= 0.0:
				_instanciar_animal_fauna(spawn_pos, (i == 0)) # 1 Agresivo, 2 Pasivos

	# 2. Manada Especial de Mamuts Ancestrales (600u comida) en Eras Primitivas
	if cur_era <= 2:
		var mammoth_ang := randf() * TAU
		var mammoth_center := Vector3(cos(mammoth_ang), 0.0, sin(mammoth_ang)) * randf_range(35.0, 60.0)
		for m in range(2):
			var m_pos := mammoth_center + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
			m_pos.y = obtener_altura_terreno(m_pos.x, m_pos.z)
			if m_pos.y >= 0.0:
				var mamut := FaunaAnimal3D.new()
				mamut.is_aggressive = false
				mamut.era_bloque = 0
				mamut.global_position = m_pos
				var tree_inst := _get_tree_safe()
				var parent: Node = null
				if is_instance_valid(tree_inst):
					parent = tree_inst.current_scene if tree_inst.current_scene else tree_inst.root
				if not is_instance_valid(parent):
					parent = self
				var res_container := parent.get_node_or_null("World/Resources")
				if is_instance_valid(res_container):
					res_container.add_child(mamut)
				else:
					parent.add_child(mamut)
				mamut.configurar_especie("mamut")
				print("RTSResourceSpawner: 🦣 Mamut de 600u de comida instanciado en %s" % str(m_pos))

func _instanciar_animal_fauna(pos: Vector3, es_agresivo: bool) -> void:
	var animal := FaunaAnimal3D.new()
	animal.is_aggressive = es_agresivo

	var rm: Node = get_node_or_null("/root/ResourceManager")
	var cur_era: int = int(rm.era_actual) if is_instance_valid(rm) and "era_actual" in rm else 0
	animal.era_bloque = _obtener_bloque_era(cur_era)
	animal.global_position = pos

	var tree_inst := _get_tree_safe()
	var parent: Node = null
	if is_instance_valid(tree_inst):
		parent = tree_inst.current_scene if tree_inst.current_scene else tree_inst.root
	if not is_instance_valid(parent):
		parent = self
	var res_container := parent.get_node_or_null("World/Resources")
	if is_instance_valid(res_container):
		res_container.add_child(animal)
	else:
		parent.add_child(animal)

	animal._aplicar_mutacion_era(cur_era)

## Reemplazo biológico fiable por RPC en red multijugador
@rpc("call_local", "reliable")
func rpc_reemplazar_fauna_extinta(pos: Vector3, era_destino: int, es_agresivo: bool) -> void:
	_instanciar_fauna_reemplazo(pos, era_destino, es_agresivo)

## Instancia fauna biológica evolucionada en el lugar exacto de extinción
func reemplazar_fauna_extinta(pos: Vector3, era_destino: int, es_agresivo: bool = false) -> FaunaAnimal3D:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("rpc_reemplazar_fauna_extinta", pos, era_destino, es_agresivo)
		return null
	return _instanciar_fauna_reemplazo(pos, era_destino, es_agresivo)

func _instanciar_fauna_reemplazo(pos: Vector3, era_destino: int, es_agresivo: bool) -> FaunaAnimal3D:
	var animal := FaunaAnimal3D.new()
	animal.is_aggressive = es_agresivo
	animal.era_bloque = _obtener_bloque_era(era_destino)
	animal.global_position = pos

	var tree_inst := _get_tree_safe()
	var parent: Node = null
	if is_instance_valid(tree_inst):
		parent = tree_inst.current_scene if tree_inst.current_scene else tree_inst.root
	if not is_instance_valid(parent):
		parent = self
	var res_container := parent.get_node_or_null("World/Resources")
	if is_instance_valid(res_container):
		res_container.add_child(animal)
	else:
		parent.add_child(animal)

	animal._aplicar_mutacion_era(era_destino)
	print("RTSResourceSpawner: ✨ Nueva fauna adaptada a Era %d nacida en %s." % [era_destino, str(pos)])
	return animal

func _obtener_bloque_era(era_val: int) -> int:
	match era_val:
		0, 1, 2:
			return 0
		3, 4, 5, 6:
			return 1
		_:
			return 2

# ─── Evaluación de Elevación por Ruido Coherente ──────────────────────────────

func obtener_altura_terreno(x: float, z: float) -> float:
	if not is_instance_valid(noise):
		return 0.0
	var n_val := noise.get_noise_2d(x, z)

	if biome_mode == 1: # Islas (60% inundado a Y = -1.8m para navegación marítima)
		if n_val < -0.05:
			return -1.8 # Agua profunda para Dock3D y barcos pesqueros
		return (n_val + 0.05) * (elevation_amplitude / 0.95)
	elif biome_mode == 2: # Planicie (sin trincheras de agua profunda)
		return n_val * elevation_amplitude
	else: # Continental (Cordilleras masivas)
		if n_val > 0.15:
			return (n_val - 0.15) * (elevation_amplitude / 0.85)
		elif n_val < -0.40:
			return -1.8 # Valles navegables ocasionales
		return 0.0

func _instanciar_nodo_recurso(tipo: String, cantidad_max: int, pos: Vector3, es_acuatico: bool = false) -> void:
	var node: ResourceNode3D = null
	if is_instance_valid(_resource_scene):
		node = _resource_scene.instantiate() as ResourceNode3D
	else:
		node = ResourceNode3D.new()

	node.resource_type = tipo
	var final_qty: int = cantidad_max
	if tipo in ["iron", "stone", "gold"]:
		final_qty = 999999
	elif tipo == "food" and not es_acuatico:
		final_qty = 850

	node.max_amount = final_qty
	node.current_amount = final_qty
	node.is_aquatic = es_acuatico

	var res_container: Node = null
	if get_parent() != null:
		res_container = get_parent().get_node_or_null("Resources")
	if not is_instance_valid(res_container):
		var tree_inst := _get_tree_safe()
		if is_instance_valid(tree_inst) and is_instance_valid(tree_inst.current_scene):
			res_container = tree_inst.current_scene.get_node_or_null("World/Resources")

	if is_instance_valid(res_container):
		res_container.add_child(node)
	else:
		add_child(node)

	node.position = pos
	if node.is_inside_tree():
		node.global_position = pos

## Purga síncrona inmediata de nodos placeholder del editor (TownCenter central y aldeanos de prueba)
## para evitar que los recursos iniciales se siembren en el origen en lugar de las bases territoriales reales.
func _purgar_placeholders_editor() -> void:
	var tree_inst: SceneTree = _get_tree_safe()
	var candidates: Array[Node] = []
	if is_instance_valid(tree_inst):
		candidates.append_array(tree_inst.get_nodes_in_group("town_centers"))
		candidates.append_array(tree_inst.get_nodes_in_group("town_centers_3d"))
		candidates.append_array(tree_inst.get_nodes_in_group("villagers"))
		candidates.append_array(tree_inst.get_nodes_in_group("placeholders"))
		if is_instance_valid(tree_inst.root):
			candidates.append_array(tree_inst.root.get_children())
		if is_instance_valid(tree_inst.current_scene):
			candidates.append_array(tree_inst.current_scene.get_children())
	if get_parent():
		candidates.append_array(get_parent().get_children())

	var purged_ids: Dictionary = {}
	for node in candidates:
		if not is_instance_valid(node) or node == self or node.is_queued_for_deletion():
			continue
		var id := node.get_instance_id()
		if purged_ids.has(id):
			continue

		var n_name := node.name.to_lower()
		var is_tc := n_name.begins_with("towncenter") or node.is_in_group("town_centers") or (node is TownCenter3D)
		var is_vil := n_name.begins_with("villager") or node.is_in_group("villagers")
		var is_ph := n_name.contains("placeholder") or node.is_in_group("placeholders")

		if (is_tc or is_vil or is_ph) and (node is Node3D):
			var node3d := node as Node3D
			if is_ph:
				purged_ids[id] = true
				node3d.free()
