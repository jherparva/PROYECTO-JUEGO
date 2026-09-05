## RTSEnemyAI — Controlador de IA Enemiga Autónoma Skirmish (GDScript 2.0 / Godot 4).
##
## Simula el comportamiento de un jugador rival gestionando:
##   1. ECONOMÍA:    Aldeanos enemigos recolectan recursos de nodos del mapa.
##   2. EXPANSIÓN:   Si hay suficiente madera/comida, construye chozas o cuarteles.
##   3. MILITAR:     Entrena soldados en edificios de producción.
##                   Al acumular ≥ MIN_GUERREROS_ATAQUE, lanza el asalto al Town Center
##                   del jugador humano.
##
## El bucle de decisiones se ejecuta cada TICK_INTERVAL segundos (por defecto 3s).
## Toda la lógica usa los mismos métodos FSM 3D creados para el jugador.

class_name RTSEnemyAI
extends Node3D

# ─── Señales ─────────────────────────────────────────────────────────────────────────
## Emitida cuando la IA lanza un ataque. Incluye número de guerreros y la posición del objetivo.
signal ataque_lanzado(guerreros: int, posicion_objetivo: Vector3)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 1 — CONFIGURACIÓN EXPORTABLE
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Bucle de Decisiones")
## Intervalo en segundos entre cada ciclo de decisión de la IA.
@export var tick_interval: float = 3.0

@export_group("Umbrales Militares")
## Número mínimo de guerreros activos antes de lanzar el ataque al jugador.
@export var min_guerreros_ataque: int = 5
## Distancia máxima desde la base enemiga para reclutar objetivos de recurso.
@export var radio_busqueda_recursos: float = 250.0

@export_group("Economía y Construcción")
## Umbral mínimo de madera para construir una nueva estructura.
@export var umbral_madera_construccion: int = 100
## Umbral mínimo de comida para entrenar un aldeano o soldado.
@export var umbral_comida_reclutamiento: int = 60
## Máximo de aldeanos activos de la IA antes de dejar de crear más.
@export var max_aldeanos_ia: int = 6
## Máximo de edificios de producción que la IA puede construir.
@export var max_edificios_ia: int = 4

@export_group("Escenas de Unidades y Edificios")
## Escena del aldeano enemigo (debe tener bando = ENEMY).
@export var escena_aldeano_enemigo: PackedScene = null
## Escena del soldado enemigo (debe tener bando = ENEMY).
@export var escena_soldado_enemigo: PackedScene = null
## Escena del cuartel / choza de producción enemiga.
@export var escena_edificio_produccion: PackedScene = null

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 2 — RECURSOS PROPIOS DE LA IA
# ──────────────────────────────────────────────────────────────────────────────

## Reserva económica interna de la IA (independiente del ResourceManager del jugador).
var _recursos_ia: Dictionary = {
	"wood":  150,
	"food":  150,
	"stone": 50,
	"iron":  0,
	"gold":  0
}


## Costes de construcción y reclutamiento de la IA.
const COSTE_ALDEANO:  Dictionary = { "food": 50 }
const COSTE_SOLDADO:  Dictionary = { "food": 80, "wood": 20 }
const COSTE_CHOZA:    Dictionary = { "wood": 75 }
const COSTE_CUARTEL:  Dictionary = { "wood": 120, "stone": 40 }

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 3 — ESTADO INTERNO
# ──────────────────────────────────────────────────────────────────────────────

## Posición de la base de origen de la IA (Town Center enemigo o spawn inicial).
var _posicion_base: Vector3 = Vector3.ZERO

## Timer de Godot para el bucle de decisiones periódico.
var _decision_timer: Timer = null

## Referencia al Town Center del jugador humano (objetivo principal de ataque).
var _town_center_jugador: Node3D = null

## Cache de unidades/edificios enemigos para acceso rápido entre ticks.
var _aldeanos_cache:  Array[Node] = []
var _soldados_cache:  Array[Node] = []
var _edificios_cache: Array[Node] = []

var bando: int = 1 # Bando / Team (0: Player/Ally, 1: Enemy)
var ai_color: Color = Color(0.90, 0.15, 0.15, 1.0) # Color de ranura asignado en lobby
var _tick_count: int = 0

# Variables para Taunts automáticos estilo Empire Earth
var _edificios_conocidos_jugador: Dictionary = {}
var _taunt_asedio_timer: float = 0.0
var _taunt_destruccion_timer: float = 0.0

func _aplicar_color_material(nodo: Node) -> void:
	if not is_instance_valid(nodo):
		return
	for child in nodo.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var mat := StandardMaterial3D.new()
			mat.albedo_color = ai_color
			mi.material_override = mat

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 4 — CICLO DE VIDA
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# ── Comprobación Estricta: 0 Enemigos / Modo Práctica 1 Jugador ─────────────
	var gs: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		gs = get_tree().root.get_node_or_null("GameSettings")
	if not is_instance_valid(gs):
		var cur: Node = get_parent()
		while is_instance_valid(cur):
			var found: Node = cur.get_node_or_null("GameSettings")
			if is_instance_valid(found):
				gs = found
				break
			cur = cur.get_parent()

	var mm: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		mm = get_tree().root.get_node_or_null("MultiplayerManager")

	var enemies_disabled: bool = false
	if is_instance_valid(gs) and "player_count" in gs and int(gs.player_count) <= 1:
		enemies_disabled = true

	# Validar slots de MultiplayerManager si están activos
	if not enemies_disabled and is_instance_valid(mm) and "lobby_slots" in mm and mm.lobby_slots is Array:
		var slots: Array = mm.lobby_slots
		if slots.size() > 0:
			var any_active_bot := false
			for i in range(1, slots.size()):
				var s: Dictionary = slots[i]
				var st: String = str(s.get("status", "")).to_upper()
				var ty: int = int(s.get("type", 0))
				if st == "BOT_IA" or st == "BOT" or ty == 2:
					any_active_bot = true
					break
			if not any_active_bot:
				# Si este nodo es el EnemyAI por defecto de la escena o slot sin bot
				enemies_disabled = true

	if enemies_disabled:
		print("RTSEnemyAI: Partida configurada en Modo 1 Jugador (Sin enemigos). Desactivando y liberando IA.")
		set_physics_process(false)
		set_process(false)
		queue_free()
		return

	add_to_group("enemy_ai")

	# Registrar la posición de base desde donde se instancia este nodo
	_posicion_base = global_position

	# Configurar el Timer del bucle de decisiones
	_decision_timer = Timer.new()
	_decision_timer.name = "DecisionTimer"
	_decision_timer.wait_time = tick_interval
	_decision_timer.one_shot = false
	_decision_timer.autostart = true
	_decision_timer.timeout.connect(_on_decision_tick)
	add_child(_decision_timer)

	# Localizar el Town Center del jugador al inicio y asegurar el Capitolio propio enemigo
	call_deferred("_localizar_town_center_jugador")
	call_deferred("_asegurar_town_center_enemigo")

	print("RTSEnemyAI: IA Enemiga inicializada en %s. Tick cada %.1fs." % [
		str(_posicion_base), tick_interval
	])

func _asegurar_town_center_enemigo() -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	if is_instance_valid(gs) and "player_count" in gs and int(gs.player_count) <= 1:
		return

	# Si la posición de base de la IA no se inicializó y quedó en (0,0,0) donde está el jugador,
	# relocalizar a la esquina predeterminada de la IA para no sobreescribir la base del jugador.
	if _posicion_base.length_squared() < 100.0:
		var player_tcs := get_tree().get_nodes_in_group("player_buildings") if get_tree() else []
		for p_bld in player_tcs:
			if is_instance_valid(p_bld) and (p_bld as Node3D).global_position.length_squared() < 100.0:
				_posicion_base = Vector3(120.0, 0.0, 120.0)
				break

	# Buscar si ya existe un Centro Urbano enemigo cerca de la base
	var tc_enemigos := get_tree().get_nodes_in_group("enemy_buildings") if get_tree() else []
	for bld in tc_enemigos:
		if is_instance_valid(bld) and (bld is TownCenter3D or bld.is_in_group("town_centers")):
			if (bld as Node3D).global_position.distance_to(_posicion_base) <= 35.0:
				return # Ya posee su Capitolio

	# Si no existe, instanciar un Capitolio Enemigo 3D
	var tc_scene := load("res://scenes/buildings/town_center_3d.tscn") as PackedScene
	var tc: TownCenter3D = tc_scene.instantiate() as TownCenter3D if tc_scene else TownCenter3D.new()
	tc.name = "TownCenterEnemigo"
	tc.set_multiplayer_authority(1000 + bando)
	tc.bando = BuildingBase3D.Bando.ENEMY
	tc.building_name = "Capitolio Enemigo"
	tc.is_under_construction = false
	tc.esta_construido = true
	tc.position = _posicion_base

	var parent := get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
	if is_instance_valid(parent):
		var bld_container := parent.get_node_or_null("World/Buildings")
		if is_instance_valid(bld_container):
			bld_container.add_child(tc)
		else:
			parent.add_child(tc)
	tc.global_position = _posicion_base

	print("RTSEnemyAI: Capitolio Enemigo 3D instanciado con éxito en %s." % str(_posicion_base))

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 5 — BUCLE PRINCIPAL DE DECISIONES
# ──────────────────────────────────────────────────────────────────────────────

## Callback principal ejecutado cada `tick_interval` segundos.
## Toma decisiones en orden de prioridad estratégica.
func _on_decision_tick() -> void:
	_tick_count += 1
	_actualizar_caches()

	# Monitoreo reactivo de destrucción de edificios del jugador
	_monitorear_destruccion_edificios_jugador()

	# ── Prioridad 1: Economía — Asignar aldeanos a recolectar ─────────────────
	_gestionar_economia()

	# ── Prioridad 2: Crecimiento — Crear más aldeanos si hay fondos ───────────
	_gestionar_creacion_aldeanos()

	# ── Prioridad 3: Expansión — Construir edificios de producción ────────────
	# Se ejecuta cada 3 ticks para no saturar la lógica
	if _tick_count % 3 == 0:
		_gestionar_expansion()

	# ── Prioridad 3.5: Evolución de Eras — Avanzar de era si hay reservas suficientes ──
	if _tick_count % 5 == 0:
		_gestionar_avance_era()

	# ── Prioridad 4: Reclutamiento militar ────────────────────────────────────
	_gestionar_reclutamiento_militar()

	# ── Prioridad 4.5: Defensa Reactiva — Responder a amenazas inmediatas ──────
	_gestionar_defensa_base()

	# ── Prioridad 5: Ataque — Lanzar asalto si hay suficientes guerreros ──────
	var guerreros_activos: int = _soldados_cache.size()
	if guerreros_activos >= min_guerreros_ataque:
		_lanzar_ataque()

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 6 — ECONOMÍA (Gestión de Aldeanos Recolectores)
# ──────────────────────────────────────────────────────────────────────────────

## Asigna todos los aldeanos ociosos a recolectar el recurso más escaso.
func _gestionar_economia() -> void:
	if _aldeanos_cache.is_empty():
		return

	# Determinar qué recurso necesita más la IA
	var recurso_objetivo: String = _recurso_mas_escaso()
	var nodo_recurso: ResourceNode3D = _buscar_nodo_recurso(recurso_objetivo)

	if not is_instance_valid(nodo_recurso):
		# Fallback: buscar cualquier recurso disponible
		for tipo: String in ["wood", "food", "stone"]:
			nodo_recurso = _buscar_nodo_recurso(tipo)
			if is_instance_valid(nodo_recurso):
				recurso_objetivo = tipo
				break

	if not is_instance_valid(nodo_recurso):
		return  # Sin recursos en el mapa, esperar

	for unit_node in _aldeanos_cache:
		if not is_instance_valid(unit_node):
			continue
		# Enviar solo aldeanos que estén en estado Idle
		var en_idle: bool = _unidad_esta_idle(unit_node)
		if en_idle and unit_node.has_method("command_gather"):
			unit_node.command_gather(nodo_recurso)

## Gestiona el depósito de recursos: simula que los aldeanos regresan recursos a la IA.
## En ausencia de un Town Center enemigo real, se incrementan los recursos internos
## proporcionalmente a los aldeanos activos (1 recurso/aldano/tick).
func _simular_recoleccion_pasiva() -> void:
	var aldeanos_activos: int = _aldeanos_cache.size()
	if aldeanos_activos <= 0:
		return

	var ganancia_por_aldano: int = 2  # Recursos acumulados por aldeano por tick
	var recurso_escaso: String = _recurso_mas_escaso()
	_recursos_ia[recurso_escaso] = int(_recursos_ia.get(recurso_escaso, 0)) + (aldeanos_activos * ganancia_por_aldano)

	# También acumular madera y comida básicas siempre
	_recursos_ia["wood"] = int(_recursos_ia.get("wood", 0)) + aldeanos_activos
	_recursos_ia["food"] = int(_recursos_ia.get("food", 0)) + aldeanos_activos

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 7 — CREACIÓN DE ALDEANOS
# ──────────────────────────────────────────────────────────────────────────────

## Crea un nuevo aldeano enemigo si hay fondos y no se ha superado el límite.
func _gestionar_creacion_aldeanos() -> void:
	# Simular recolección pasiva si los aldeanos están activos
	_simular_recoleccion_pasiva()

	if _aldeanos_cache.size() >= max_aldeanos_ia:
		return

	if not _puede_costear(COSTE_ALDEANO):
		return

	_gastar_recursos_ia(COSTE_ALDEANO)
	_instanciar_unidad_enemiga(escena_aldeano_enemigo, "Villager3D_Enemy", true)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 8 — EXPANSIÓN (Construcción de Edificios)
# ──────────────────────────────────────────────────────────────────────────────

## Decide si construir una nueva choza o cuartel según los recursos disponibles.
func _gestionar_expansion() -> void:
	if _edificios_cache.size() >= max_edificios_ia:
		return

	# Si tiene madera suficiente para un cuartel y ya tiene aldeanos
	if _puede_costear(COSTE_CUARTEL) and _aldeanos_cache.size() >= 2:
		_gastar_recursos_ia(COSTE_CUARTEL)
		_instanciar_edificio_enemigo(escena_edificio_produccion, "EnemyBarracks")
		print("RTSEnemyAI: IA construye un cuartel enemigo.")
		return

	# Si tiene madera básica, construye una choza (aumenta límite de población implícitamente)
	if _puede_costear(COSTE_CHOZA) and not _aldeanos_cache.is_empty():
		_gastar_recursos_ia(COSTE_CHOZA)
		_instanciar_edificio_enemigo(null, "EnemyHut")
		print("RTSEnemyAI: IA construye una choza enemiga.")

var era_actual_ia: int = 0

## Evalúa si la IA posee los recursos necesarios para evolucionar de Era y ejecuta el avance.
func _gestionar_avance_era() -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		return

	var costo_era: Dictionary = {
		0: { "food": 500, "stone": 200 },
		1: { "food": 800, "stone": 400, "wood": 300 },
		2: { "food": 1200, "iron": 300, "stone": 600 },
		3: { "food": 1800, "iron": 600, "gold": 200 },
		4: { "food": 2500, "gold": 500, "iron": 500 }
	}.get(era_actual_ia, {})

	if costo_era.is_empty():
		return

	if _puede_costear(costo_era):
		_gastar_recursos_ia(costo_era)
		era_actual_ia += 1
		print("RTSEnemyAI: ¡LA IA ENEMIGA EVOLUCIONA A LA ERA %d!" % era_actual_ia)

		# Notificar a los soldados enemigos vivos para escalar sus estadísticas
		for sld in _soldados_cache:
			if is_instance_valid(sld) and "daño" in sld:
				sld.set("daño", float(sld.get("daño")) * 1.35)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 9 — RECLUTAMIENTO MILITAR
# ──────────────────────────────────────────────────────────────────────────────

## Entrena un soldado enemigo si hay fondos y edificios de producción activos.
func _gestionar_reclutamiento_militar() -> void:
	if not _puede_costear(COSTE_SOLDADO):
		return

	# Necesita al menos un edificio de producción para entrenar
	if _edificios_cache.is_empty():
		# Sin edificios, la IA intenta entrenar directamente desde la base (modo simplificado)
		_gastar_recursos_ia(COSTE_SOLDADO)
		_instanciar_unidad_enemiga(escena_soldado_enemigo, "Soldier3D_Enemy", false)
		return

	# Entrenar desde el primer edificio de producción válido
	var edificio: Node3D = _edificios_cache[0] as Node3D
	if is_instance_valid(edificio) and edificio.has_method("crear_aldeano"):
		# Si el edificio es un TownCenter enemigo, usar su cola
		edificio.crear_aldeano()
	else:
		_gastar_recursos_ia(COSTE_SOLDADO)
		_instanciar_unidad_enemiga(escena_soldado_enemigo, "Soldier3D_Enemy", false)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 9.5 — DEFENSA REACTIVA DE LA BASE ENEMIGA
# ──────────────────────────────────────────────────────────────────────────────

## Detecta si aldeanos o edificios enemigos están siendo atacados y despacha tropas a defenderlos.
func _gestionar_defensa_base() -> void:
	var amenaza_detectada: Node3D = null
	
	# Buscar si alguna unidad enemiga está en combate o sufriendo daño
	for enemigo in _aldeanos_cache + _edificios_cache:
		if is_instance_valid(enemigo) and ("hp" in enemigo and "max_hp" in enemigo):
			if (enemigo.get("hp") as float) < (enemigo.get("max_hp") as float):
				# Buscar agresor cercano del jugador
				for ju in get_tree().get_nodes_in_group("player_units"):
					if is_instance_valid(ju) and (ju is Node3D):
						if (enemigo as Node3D).global_position.distance_to((ju as Node3D).global_position) < 25.0:
							amenaza_detectada = ju as Node3D
							break
		if is_instance_valid(amenaza_detectada):
			break

	if is_instance_valid(amenaza_detectada):
		for sld in _soldados_cache:
			if is_instance_valid(sld) and _unidad_esta_idle(sld):
				if sld.has_method("command_attack"):
					sld.command_attack(amenaza_detectada)
				elif "state_machine" in sld and sld.state_machine:
					sld.state_machine.change_state(&"Attacking", {"target": amenaza_detectada})

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 10 — ATAQUE ESTRATÉGICO AL JUGADOR
# ──────────────────────────────────────────────────────────────────────────────

## Agrupa a todos los guerreros enemigos y los lanza contra el objetivo más estratégico del jugador.
func _lanzar_ataque() -> void:
	_localizar_town_center_jugador()

	# Selección dinámica de objetivo: Sacerdotes > Aldeanos > Cuarteles > Capitolio
	var objetivo: Node3D = _seleccionar_objetivo_estrategico()

	if not is_instance_valid(objetivo):
		_atacar_unidad_jugador_mas_cercana()
		return

	# Si el objetivo es el Capitolio o Town Center, disparar burla clásica de asedio
	if objetivo == _town_center_jugador or objetivo is TownCenter3D or objetivo.is_in_group("town_centers"):
		_disparar_taunt_asedio_capitolio()

	var soldados_ordenados: int = 0
	var total_soldados := _soldados_cache.size()

	# ─── INTEGRACIÓN TÁCTICA MILITAR ───────────────────────────────────────────
	# Si hay suficiente ejército (N >= 8), delegar a MilitaryWarTactics3D para flanqueo real
	# e inteligencia de Smart Targeting de arqueros / sacerdotes / infantería
	var tactics := MilitaryWarTactics3D.instance if MilitaryWarTactics3D.instance != null else get_tree().get_first_node_in_group("military_war_tactics") as MilitaryWarTactics3D
	if is_instance_valid(tactics) and total_soldados >= tactics.umbral_flanqueo_peloton:
		var unit_paths: Array = []
		for s in _soldados_cache:
			if is_instance_valid(s) and s is Node3D:
				unit_paths.append((s as Node3D).get_path())
				soldados_ordenados += 1

		tactics.rpc_coordinar_flanqueo(unit_paths, objetivo.get_path())

		# Smart Targeting: redistribuir atacantes de la IA contra soportes enemigos (profetas/sacerdotes)
		var enemigos_en_zona: Array[Node3D] = []
		for pu in get_tree().get_nodes_in_group("player_units"):
			if is_instance_valid(pu) and pu is Node3D:
				if _posicion_base.distance_to((pu as Node3D).global_position) <= 200.0:
					enemigos_en_zona.append(pu as Node3D)

		var attackers_typed: Array[Node3D] = []
		for s in _soldados_cache:
			if is_instance_valid(s) and s is Node3D:
				attackers_typed.append(s as Node3D)
		tactics.evaluar_prioridades_peloton(attackers_typed, enemigos_en_zona)

	else:
		# Asalto estándar (< 8 soldados): pinza básica existente
		var es_ataque_pinza := total_soldados >= 6

		for idx in range(total_soldados):
			var unit_node := _soldados_cache[idx]
			if not is_instance_valid(unit_node):
				continue

			var target_actual := objetivo
			if es_ataque_pinza and idx % 2 == 1 and is_instance_valid(_town_center_jugador):
				target_actual = _town_center_jugador

			if unit_node.has_method("command_attack"):
				unit_node.command_attack(target_actual)
				soldados_ordenados += 1
			elif "state_machine" in unit_node and unit_node.state_machine:
				unit_node.state_machine.change_state(&"Attacking", {"target": target_actual})
				soldados_ordenados += 1

	if soldados_ordenados > 0:
		print("RTSEnemyAI: ¡ATAQUE ESTRATÉGICO! %d guerreros asaltan objetivos en %s." % [
			soldados_ordenados, str(objetivo.global_position)
		])
		ataque_lanzado.emit(soldados_ordenados, objetivo.global_position)

## Selecciona un objetivo prioritario según la jerarquía táctica oficial de EE:
## 1. Sacerdotes / Profetas (Corta conversiones y soporte)
## 2. Aldeanos (Asfixia económica)
## 3. Cuarteles / Edificios militares (Frena producción bélica)
## 4. Capitolio / Town Center (Asedio definitivo)
func _seleccionar_objetivo_estrategico() -> Node3D:
	var player_units := get_tree().get_nodes_in_group("player_units") if get_tree() else []
	var player_buildings := get_tree().get_nodes_in_group("player_buildings") if get_tree() else []

	# Prioridad 1: Sacerdotes / Profetas del jugador
	for u in player_units:
		if is_instance_valid(u) and u is Node3D:
			var u_name: String = u.name.to_lower()
			var u_title: String = str(u.get("unit_name")).to_lower() if "unit_name" in u else ""
			if u.is_in_group("priests") or u.is_in_group("prophets") or "prophet" in u_name or "priest" in u_name or "sacerdote" in u_title or "profeta" in u_title:
				return u as Node3D

	# Prioridad 2: Aldeanos recolectores del jugador
	for u in player_units:
		if is_instance_valid(u) and u is Node3D:
			if u is Villager3D or u.is_in_group("villagers") or u.has_method("command_gather"):
				var dist_base := _posicion_base.distance_to((u as Node3D).global_position)
				if dist_base < 220.0:
					return u as Node3D

	# Prioridad 3: Cuarteles y edificios militares de producción
	for bld in player_buildings:
		if is_instance_valid(bld) and bld is Node3D:
			var b_name: String = bld.name.to_lower()
			var b_title: String = str(bld.get("building_name")).to_lower() if "building_name" in bld else ""
			if bld is Barracks3D or bld.is_in_group("barracks") or bld.is_in_group("military_buildings") or "cuartel" in b_name or "barrack" in b_name or "cuartel" in b_title:
				return bld as Node3D

	# Fallback a otros edificios periféricos (granjas, depósitos, torres)
	var edificio_cercano: Node3D = null
	var min_dist := INF
	for bld in player_buildings:
		if is_instance_valid(bld) and bld is Node3D and not (bld is TownCenter3D or bld.is_in_group("town_centers")):
			var dist := _posicion_base.distance_to((bld as Node3D).global_position)
			if dist < min_dist:
				min_dist = dist
				edificio_cercano = bld as Node3D

	if is_instance_valid(edificio_cercano):
		return edificio_cercano

	# Prioridad 4: Capitolio / Town Center principal
	return _town_center_jugador

# ──────────────────────────────────────────────────────────────────────────────
# MONITOREO Y TAUNTS AUTOMÁTICOS DEL BOT
# ──────────────────────────────────────────────────────────────────────────────

func _monitorear_destruccion_edificios_jugador() -> void:
	var edificios_actuales := get_tree().get_nodes_in_group("player_buildings") if get_tree() else []
	var activos_map: Dictionary = {}

	for bld in edificios_actuales:
		if is_instance_valid(bld):
			var b_name: String = str(bld.get("building_name")) if "building_name" in bld else bld.name
			activos_map[bld] = b_name
			if not _edificios_conocidos_jugador.has(bld):
				_edificios_conocidos_jugador[bld] = b_name

	# Detectar edificios previamente registrados que ya no existen
	var destruidos: Array = []
	for bld in _edificios_conocidos_jugador.keys():
		if not is_instance_valid(bld) or not activos_map.has(bld):
			var nombre_edificio: String = str(_edificios_conocidos_jugador.get(bld, "Estructura"))
			destruidos.append(bld)
			_disparar_taunt_destruccion_edificio(nombre_edificio)

	for d in destruidos:
		_edificios_conocidos_jugador.erase(d)

func _disparar_taunt_asedio_capitolio() -> void:
	var cur_time := Time.get_ticks_msec() / 1000.0
	if cur_time - _taunt_asedio_timer >= 45.0:
		_taunt_asedio_timer = cur_time
		var chat := NetworkChatManager.instance if NetworkChatManager.instance != null else get_node_or_null("/root/NetworkChatManager")
		if is_instance_valid(chat) and chat.has_method("bot_taunt_asedio_capitolio"):
			chat.call("bot_taunt_asedio_capitolio", "General Rival (IA)")

func _disparar_taunt_destruccion_edificio(bld_name: String) -> void:
	var cur_time := Time.get_ticks_msec() / 1000.0
	if cur_time - _taunt_destruccion_timer >= 20.0:
		_taunt_destruccion_timer = cur_time
		var chat := NetworkChatManager.instance if NetworkChatManager.instance != null else get_node_or_null("/root/NetworkChatManager")
		if is_instance_valid(chat) and chat.has_method("bot_taunt_destruccion_edificio"):
			chat.call("bot_taunt_destruccion_edificio", "General Rival (IA)", bld_name)

## Fallback: si no hay Town Center, atacar a la unidad del jugador más cercana a la base.
func _atacar_unidad_jugador_mas_cercana() -> void:
	if _soldados_cache.is_empty():
		return

	var unidades_jugador: Array[Node] = []
	unidades_jugador.append_array(get_tree().get_nodes_in_group("player_units"))
	unidades_jugador.append_array(get_tree().get_nodes_in_group("player_buildings"))

	if unidades_jugador.is_empty():
		return

	# Encontrar el objetivo más cercano a la base enemiga
	var objetivo_cercano: Node3D = null
	var distancia_minima: float  = INF

	for candidato in unidades_jugador:
		if is_instance_valid(candidato) and candidato is Node3D:
			var dist: float = _posicion_base.distance_to((candidato as Node3D).global_position)
			if dist < distancia_minima:
				distancia_minima = dist
				objetivo_cercano = candidato as Node3D

	if not is_instance_valid(objetivo_cercano):
		return

	for unit_node in _soldados_cache:
		if not is_instance_valid(unit_node):
			continue
		if unit_node.has_method("command_attack"):
			unit_node.command_attack(objetivo_cercano)
		elif "state_machine" in unit_node and unit_node.state_machine:
			unit_node.state_machine.change_state(&"Attacking", {"target": objetivo_cercano})

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 11 — INSTANCIACIÓN DE UNIDADES Y EDIFICIOS
# ──────────────────────────────────────────────────────────────────────────────

## Instancia una unidad enemiga (aldeano o soldado) cerca de la base de la IA.
func _instanciar_unidad_enemiga(escena: PackedScene, nombre_nodo: String, es_aldeano: bool) -> void:
	var nueva_unidad: Node3D = null

	var pscene: PackedScene = escena
	if not is_instance_valid(pscene):
		if es_aldeano:
			pscene = load("res://scenes/units/villager_3d.tscn") as PackedScene
		else:
			pscene = load("res://scenes/units/soldier_3d.tscn") as PackedScene

	if is_instance_valid(pscene):
		nueva_unidad = pscene.instantiate() as Node3D

	if not is_instance_valid(nueva_unidad):
		push_error("RTSEnemyAI: No se pudo instanciar la unidad '%s'." % nombre_nodo)
		return

	nueva_unidad.name = nombre_nodo

	# Forzar bando ENEMY si el nodo tiene la propiedad
	if "bando" in nueva_unidad:
		nueva_unidad.set("bando", 1) # Bando.ENEMY

	# Posicionar con desplazamiento aleatorio desde la base
	var offset := Vector3(
		randf_range(-8.0, 8.0),
		0.0,
		randf_range(-8.0, 8.0)
	)
	# Añadir al árbol de escena bajo el contenedor de unidades primero
	var contenedor := _buscar_contenedor_unidades()
	contenedor.add_child(nueva_unidad)
	nueva_unidad.global_position = _posicion_base + offset

	# Registrar en grupos
	nueva_unidad.add_to_group("units")
	nueva_unidad.add_to_group("units_3d")
	nueva_unidad.add_to_group("enemy_units")

	_aplicar_color_material(nueva_unidad)

	print("RTSEnemyAI: Instanciada unidad '%s' en %s." % [
		nombre_nodo, str(nueva_unidad.global_position)
	])

## Instancia un edificio enemigo cerca de la base de la IA con desplazamiento aleatorio.
func _instanciar_edificio_enemigo(escena: PackedScene, nombre_nodo: String) -> void:
	var nuevo_edificio: Node3D = null

	if is_instance_valid(escena):
		nuevo_edificio = escena.instantiate() as Node3D
	else:
		nuevo_edificio = BuildingBase3D.new()

	if not is_instance_valid(nuevo_edificio):
		push_error("RTSEnemyAI: No se pudo instanciar el edificio '%s'." % nombre_nodo)
		return

	nuevo_edificio.name = nombre_nodo

	# Forzar bando ENEMY
	if "bando" in nuevo_edificio:
		nuevo_edificio.set("bando", BuildingBase3D.Bando.ENEMY)

	# Desplazamiento estratégico de edificios alrededor de la base
	var angulo: float = randf_range(0.0, TAU)
	var radio: float  = randf_range(10.0, 25.0)
	var offset := Vector3(cos(angulo) * radio, 0.0, sin(angulo) * radio)

	# Añadir al árbol primero
	var contenedor_bld := _buscar_contenedor_edificios()
	contenedor_bld.add_child(nuevo_edificio)
	nuevo_edificio.global_position = _posicion_base + offset

	nuevo_edificio.add_to_group("buildings")
	nuevo_edificio.add_to_group("buildings_3d")
	nuevo_edificio.add_to_group("enemy_buildings")

	_aplicar_color_material(nuevo_edificio)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 12 — ACTUALIZACIÓN DE CACHES
# ──────────────────────────────────────────────────────────────────────────────

## Refresca los arrays de caché con las unidades/edificios enemigos activos en el árbol.
func _actualizar_caches() -> void:
	_aldeanos_cache.clear()
	_soldados_cache.clear()
	_edificios_cache.clear()

	for node in get_tree().get_nodes_in_group("enemy_units"):
		if not is_instance_valid(node):
			continue
		if node is Villager3D:
			_aldeanos_cache.append(node)
		elif node is Soldier3D:
			_soldados_cache.append(node)

	for node in get_tree().get_nodes_in_group("enemy_buildings"):
		if is_instance_valid(node):
			_edificios_cache.append(node)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 13 — HELPERS DE RECURSOS Y BÚSQUEDA
# ──────────────────────────────────────────────────────────────────────────────

## Retorna el nombre del recurso con menor cantidad en los cofres de la IA.
func _recurso_mas_escaso() -> String:
	var recurso_escaso: String = "wood"
	var minimo: int = int(_recursos_ia.get("wood", 0))

	for res: String in ["food", "stone"]:
		var cantidad: int = int(_recursos_ia.get(res, 0))
		if cantidad < minimo:
			minimo = cantidad
			recurso_escaso = res

	return recurso_escaso

## Busca el ResourceNode3D no agotado más cercano a la base de la IA del tipo indicado.
func _buscar_nodo_recurso(tipo_recurso: String) -> ResourceNode3D:
	var mejor_nodo: ResourceNode3D = null
	var distancia_minima: float    = radio_busqueda_recursos

	for node in get_tree().get_nodes_in_group("resources_3d"):
		if not is_instance_valid(node) or not (node is ResourceNode3D):
			continue

		var nodo_rec := node as ResourceNode3D
		if nodo_rec.is_depleted():
			continue
		if nodo_rec.get_resource_type() != tipo_recurso:
			continue

		var dist: float = _posicion_base.distance_to(nodo_rec.global_position)
		if dist < distancia_minima:
			distancia_minima = dist
			mejor_nodo = nodo_rec

	return mejor_nodo

## Localiza y guarda la referencia al Town Center del jugador humano.
func _localizar_town_center_jugador() -> void:
	_town_center_jugador = null

	for node in get_tree().get_nodes_in_group("town_centers"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		# Filtrar solo el del jugador (no de la IA)
		if "bando" in node:
			if int(node.bando) == int(BuildingBase3D.Bando.PLAYER):
				_town_center_jugador = node as Node3D
				return
		else:
			# Si no tiene bando definido, asumir que es del jugador
			_town_center_jugador = node as Node3D
			return

## Retorna true si la unidad está en estado Idle (sin tarea activa).
func _unidad_esta_idle(unit_node: Node) -> bool:
	if not is_instance_valid(unit_node):
		return false
	if "state_machine" in unit_node and unit_node.state_machine:
		var sm: StateMachine3D = unit_node.state_machine as StateMachine3D
		if is_instance_valid(sm) and sm.current_state:
			var nombre: StringName = sm.current_state.state_name
			return nombre == &"Idle"
	return true  # Si no tiene FSM, tratar como idle

## Verifica si los recursos internos de la IA cubren el costo indicado.
func _puede_costear(costo: Dictionary) -> bool:
	for res: String in costo:
		var requerido: int  = int(costo[res])
		var disponible: int = int(_recursos_ia.get(res.to_lower(), 0))
		if disponible < requerido:
			return false
	return true

## Descuenta los recursos internos de la IA.
func _gastar_recursos_ia(costo: Dictionary) -> void:
	for res: String in costo:
		var key: String = res.to_lower()
		var gasto: int  = int(costo[res])
		_recursos_ia[key] = maxi(0, int(_recursos_ia.get(key, 0)) - gasto)

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 14 — HELPERS DE ESCENA
# ──────────────────────────────────────────────────────────────────────────────

## Busca el contenedor de unidades en la escena principal para añadir hijos.
func _buscar_contenedor_unidades() -> Node:
	if get_tree() and get_tree().current_scene:
		var root: Node = get_tree().current_scene
		var contenedor := root.get_node_or_null("World/Units")
		if is_instance_valid(contenedor):
			return contenedor
		var units := root.get_node_or_null("Units")
		if is_instance_valid(units):
			return units
	return get_parent() if is_instance_valid(get_parent()) else self

## Busca el contenedor de edificios en la escena principal.
func _buscar_contenedor_edificios() -> Node:
	if get_tree() and get_tree().current_scene:
		var root: Node = get_tree().current_scene
		var contenedor := root.get_node_or_null("World/Buildings")
		if is_instance_valid(contenedor):
			return contenedor
		var buildings := root.get_node_or_null("Buildings")
		if is_instance_valid(buildings):
			return buildings
	return get_parent() if is_instance_valid(get_parent()) else self

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 15 — API PÚBLICA
# ──────────────────────────────────────────────────────────────────────────────

## Pausa o reanuda el bucle de decisiones de la IA.
func set_ia_activa(activa: bool) -> void:
	if not is_instance_valid(_decision_timer):
		return
	if activa:
		_decision_timer.start()
	else:
		_decision_timer.stop()
	print("RTSEnemyAI: IA %s." % ("activada" if activa else "pausada"))

## Inyecta recursos adicionales en la economía interna de la IA.
## Soporta tanto un Dictionary {"wood": 10} como (tipo: String, cantidad: int).
func agregar_recursos_ia(tipo_o_dict: Variant, cantidad: int = 0) -> void:
	if tipo_o_dict is Dictionary:
		for rk in tipo_o_dict:
			var key := str(rk).to_lower()
			_recursos_ia[key] = int(_recursos_ia.get(key, 0)) + int(tipo_o_dict[rk])
	elif tipo_o_dict is String:
		var key: String = (tipo_o_dict as String).to_lower()
		_recursos_ia[key] = int(_recursos_ia.get(key, 0)) + cantidad

## Devuelve un snapshot del estado de la IA para debugging o el HUD de debug.
func get_estado_debug() -> Dictionary:
	return {
		"tick":          _tick_count,
		"aldeanos":      _aldeanos_cache.size(),
		"soldados":      _soldados_cache.size(),
		"edificios":     _edificios_cache.size(),
		"recursos_ia":   _recursos_ia.duplicate(),
		"en_ataque":     _soldados_cache.size() >= min_guerreros_ataque,
		"objetivo":      str(_town_center_jugador) if is_instance_valid(_town_center_jugador) else "N/A"
	}
