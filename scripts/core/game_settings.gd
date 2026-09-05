## GameSettings — Configuración Global de Partida RTS (GDScript 2.0 / Godot 4).
##
## Almacena y aplica los parámetros de personalización de cada partida:
## - Era Inicial (0 a 9) y Era Máxima (0 a 9)
## - Límite de Población (50 a 500)
## - Recursos iniciales y presets
## - Dificultad de la IA y velocidad de simulación

extends Node

static var instance: Node = null

func _init() -> void:
	instance = self

func _ready() -> void:
	instance = self

static func get_game_speed_mod() -> float:
	if is_instance_valid(instance) and "game_speed_modifier" in instance:
		return float(instance.game_speed_modifier)
	var ml = Engine.get_main_loop()
	if ml and "root" in ml and ml.root:
		var gs = ml.root.get_node_or_null("GameSettings")
		if is_instance_valid(gs) and "game_speed_modifier" in gs:
			return float(gs.game_speed_modifier)
	return 1.0

# ─── Parámetros de Partida ───────────────────────────────────────────────────
var starting_era: int = 0             # 0: Prehistoria ... 9: Nano-Futurista
var max_era: int = 9                  # Era limite de desarrollo
var max_population_limit: int = 200    # 50 a 500 unidades
var player_count: int = 2              # 2, 3, 4
var starting_villagers: int = 5        # 3, 5, 8
var starting_resources: String = "normal"  # "escaso", "normal", "abundante", "deathmatch"
var game_speed: float = 1.0            # 0.5, 0.75, 1.0, 1.4, 2.0
var game_speed_modifier: float = 1.0:
	get:
		return _game_speed_modifier
	set(v):
		_game_speed_modifier = v
		game_speed = v
var _game_speed_modifier: float = 1.0
var ai_difficulty: String = "normal"   # "facil", "normal", "dificil", "experto"
var fog_of_war_enabled: bool = true
var map_size: float = 400.0
var civilization: String = "ninguna"   # "griegos", "romanos", "ingleses", "alemanes", "ninguna"
var resource_preset: int = 2           # 0-4, mapea a PRESETS_RECURSOS_INICIALES

# --- Presets de Civilizacion (dbpremadecivs.dat + dbcivilization.dat) ---------
## Bonificaciones pasivas nativas por civilizacion, activas desde el frame 1.
## Cada entrada contiene: gather_bonus (por recurso), population_bonus,
## attack_bonus, speed_bonus y description (texto para HUD).
const CIV_PRESETS: Dictionary = {
	"griegos": {
		"description":    "Filosofia y Democracia: Tecnologias mas baratas y Academias con investigacion acelerada.",
		"gather_food":    1.0,
		"gather_wood":    1.0,
		"gather_stone":   1.0,
		"gather_gold":    1.15, # +15% produccion de oro (comercio maritimo)
		"gather_iron":    1.0,
		"population":     0,    # Sin bono de poblacion
		"attack":         1.0,
		"speed":          1.1,  # +10% velocidad de unidades (agilidad griega)
		"tech_cost_mult": 0.85, # -15% costo en investigaciones tecnologicas
	},
	"romanos": {
		"description":    "Legion Romana: Infanteria mas fuerte y construccion acelerada.",
		"gather_food":    1.1,  # +10% recoleccion de comida (agricultura romana)
		"gather_wood":    1.0,
		"gather_stone":   1.2,  # +20% recoleccion de piedra (ingenieria romana)
		"gather_gold":    1.0,
		"gather_iron":    1.0,
		"population":     10,   # +10 poblacion extra (Legion)
		"attack":         1.1,  # +10% ataque de infanteria
		"speed":          1.0,
		"tech_cost_mult": 1.0,
	},
	"ingleses": {
		"description":    "Maestros del Arco: Arqueros con alcance y dano extendidos.",
		"gather_food":    1.0,
		"gather_wood":    1.15, # +15% recoleccion de madera (bosques de Inglaterra)
		"gather_stone":   1.0,
		"gather_gold":    1.0,
		"gather_iron":    1.0,
		"population":     0,
		"attack":         1.0,
		"speed":          1.0,
		"tech_cost_mult": 1.0,
		"archer_range_bonus": 3.0, # +3m de alcance para todos los arqueros
		"archer_damage_bonus": 1.2,# +20% dano de flecheros
	},
	"alemanes": {
		"description":    "Maquinaria de Guerra: Unidades de asedio mas baratas y resistentes.",
		"gather_food":    1.0,
		"gather_wood":    1.0,
		"gather_stone":   1.0,
		"gather_gold":    1.0,
		"gather_iron":    1.2,  # +20% recoleccion de hierro (industria pesada)
		"population":     5,    # +5 poblacion extra
		"attack":         1.0,
		"speed":          1.0,
		"tech_cost_mult": 1.0,
		"siege_hp_mult":  1.3,  # +30% HP de maquinas de asedio
		"siege_cost_mult":0.80, # -20% costo de unidades de asedio
	},
	"ninguna": {
		"description":    "Sin civilizacion especifica — configuracion neutral.",
		"gather_food":    1.0,
		"gather_wood":    1.0,
		"gather_stone":   1.0,
		"gather_gold":    1.0,
		"gather_iron":    1.0,
		"population":     0,
		"attack":         1.0,
		"speed":          1.0,
		"tech_cost_mult": 1.0,
	},
}

# ─── Valores Predeterminados ──────────────────────────────────────────────────
func reset_to_defaults() -> void:
	starting_era = 0
	max_era = 9
	max_population_limit = 200
	player_count = 2
	starting_villagers = 5
	starting_resources = "normal"
	game_speed = 1.0
	game_speed_modifier = 1.0
	ai_difficulty = "normal"
	fog_of_war_enabled = true
	map_size = 400.0

## Aplica la configuración a la partida activa (Llamado en ready de main_3d o ResourceManager)
func apply_to_game(tree: SceneTree) -> void:
	# 1. Velocidad de tiempo
	Engine.time_scale = game_speed

	# 2. Configurar ResourceManager (Era Inicial, Recursos y Límite de Población)
	var rm: Node = tree.root.get_node_or_null("ResourceManager")
	if not is_instance_valid(rm):
		rm = tree.current_scene.get_node_or_null("ResourceManager")

	if is_instance_valid(rm):
		# Aplicar Límite de Población
		if "max_population" in rm:
			rm.max_population = max_population_limit

		# Aplicar Era Límite
		if "max_era" in rm:
			rm.max_era = max_era

		# Aplicar Recursos Iniciales
		var amounts: Dictionary = get_starting_resource_amounts()
		for res in amounts:
			if res in rm:
				rm.set(res, amounts[res])
		if rm.has_signal("recursos_actualizados"):
			rm.recursos_actualizados.emit(
				rm.get("food") if "food" in rm else 0,
				rm.get("wood") if "wood" in rm else 0,
				rm.get("stone") if "stone" in rm else 0,
				rm.get("gold") if "gold" in rm else 0,
				rm.get("iron") if "iron" in rm else 0
			)

		# Aplicar Era Inicial
		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", starting_era)

	# 3. Dificultad de la IA
	_apply_ai_difficulty(tree)

	# 4. Niebla de Guerra
	var fow := tree.get_first_node_in_group("fog_of_war_manager")
	if is_instance_valid(fow) and "visible" in fow:
		fow.visible = fog_of_war_enabled

	# 5. Bonificaciones de Civilizacion (dbpremadecivs.dat) — aplicadas desde frame 1
	apply_civ_bonuses(tree)

	print("GameSettings: Configuracion aplicada a la partida:")
	print("  -> Era Inicial: %d | Era Maxima: %d | Pob Max: %d | Recursos: %s | IA: %s | Civ: %s" % [
		starting_era, max_era, max_population_limit, starting_resources, ai_difficulty, civilization
	])

func get_starting_resource_amounts() -> Dictionary:
	match starting_resources:
		"escaso":
			return {"food": 100, "wood": 100, "stone": 100, "gold": 100, "iron": 100}
		"abundante":
			return {"food": 2000, "wood": 2000, "stone": 2000, "gold": 2000, "iron": 2000}
		"deathmatch":
			return {"food": 50000, "wood": 50000, "stone": 50000, "gold": 50000, "iron": 50000}
		_: # "normal" / "estandar"
			return {"food": 500, "wood": 500, "stone": 500, "gold": 500, "iron": 500}

## Aplica los bonos nativos de la civilizacion seleccionada al ResourceManager y
## a las unidades existentes en la escena (dbpremadecivs.dat + dbcivilization.dat).
func apply_civ_bonuses(tree: SceneTree) -> void:
	var civ_key: String = civilization.to_lower().strip_edges()
	if not CIV_PRESETS.has(civ_key) or civ_key == "ninguna":
		return

	var preset: Dictionary = CIV_PRESETS[civ_key] as Dictionary

	# 1. Aplicar bonos de recoleccion al ResourceManager
	var rm: Node = tree.root.get_node_or_null("ResourceManager")
	if not is_instance_valid(rm):
		rm = tree.current_scene.get_node_or_null("ResourceManager")

	if is_instance_valid(rm):
		# Bono de poblacion de civilizacion
		var pop_bonus: int = int(preset.get("population", 0))
		if pop_bonus > 0 and rm.has_method("change_max_population"):
			rm.call("change_max_population", pop_bonus)

		# Guardar multiplicadores de recoleccion en el RM para que los aldeanos los lean
		if "tech_gather_bonuses" in rm:
			var tgb: Dictionary = rm.get("tech_gather_bonuses") as Dictionary
			tgb["food"]  = float(tgb.get("food",  1.0)) * float(preset.get("gather_food",  1.0))
			tgb["wood"]  = float(tgb.get("wood",  1.0)) * float(preset.get("gather_wood",  1.0))
			tgb["stone"] = float(tgb.get("stone", 1.0)) * float(preset.get("gather_stone", 1.0))
			tgb["gold"]  = float(tgb.get("gold",  1.0)) * float(preset.get("gather_gold",  1.0))
			tgb["iron"]  = float(tgb.get("iron",  1.0)) * float(preset.get("gather_iron",  1.0))
			rm.set("tech_gather_bonuses", tgb)

	# 2. Aplicar bonos de ataque y velocidad a las unidades activas del jugador
	var attack_mult: float = float(preset.get("attack", 1.0))
	var speed_mult: float  = float(preset.get("speed",  1.0))

	if attack_mult != 1.0 or speed_mult != 1.0:
		for unit in tree.get_nodes_in_group("player_units"):
			if not is_instance_valid(unit):
				continue
			if "dano" in unit and attack_mult != 1.0:
				unit.set("dano", float(unit.get("dano")) * attack_mult)
			if "speed" in unit and speed_mult != 1.0:
				unit.set("speed", float(unit.get("speed")) * speed_mult)

	# 3. Bono de alcance de arqueros (Ingleses)
	var archer_range_bonus: float  = float(preset.get("archer_range_bonus",  0.0))
	var archer_damage_bonus: float = float(preset.get("archer_damage_bonus", 1.0))
	if archer_range_bonus > 0.0 or archer_damage_bonus != 1.0:
		for archer in tree.get_nodes_in_group("archers_3d") + tree.get_nodes_in_group("player_units"):
			if not is_instance_valid(archer):
				continue
			var at: String = str(archer.get("attack_type")) if "attack_type" in archer else ""
			if at != "ranged":
				continue
			if "rango_ataque" in archer and archer_range_bonus > 0.0:
				archer.set("rango_ataque", float(archer.get("rango_ataque")) + archer_range_bonus)
			if "dano" in archer and archer_damage_bonus != 1.0:
				archer.set("dano", float(archer.get("dano")) * archer_damage_bonus)

	print("GameSettings: Civilizacion '%s' aplicada — %s" % [civ_key, str(preset.get("description", ""))])

func _apply_ai_difficulty(tree: SceneTree) -> void:
	if player_count <= 1:
		for ai in tree.get_nodes_in_group("enemy_ai"):
			if is_instance_valid(ai) and ai is Node:
				ai.queue_free()
		for eb in tree.get_nodes_in_group("enemy_buildings"):
			if is_instance_valid(eb) and eb is Node:
				eb.queue_free()
		for eu in tree.get_nodes_in_group("enemy_units"):
			if is_instance_valid(eu) and eu is Node:
				eu.queue_free()
		return

	for ai in tree.get_nodes_in_group("enemy_ai"):
		if not is_instance_valid(ai):
			continue
		match ai_difficulty:
			"facil":
				if "intervalo_ataque_segundos" in ai:
					ai.intervalo_ataque_segundos = 120.0
				if "tropas_minimas_para_atacar" in ai:
					ai.tropas_minimas_para_atacar = 8
			"dificil":
				if "intervalo_ataque_segundos" in ai:
					ai.intervalo_ataque_segundos = 40.0
				if "tropas_minimas_para_atacar" in ai:
					ai.tropas_minimas_para_atacar = 4
			"experto":
				if "intervalo_ataque_segundos" in ai:
					ai.intervalo_ataque_segundos = 25.0
				if "tropas_minimas_para_atacar" in ai:
					ai.tropas_minimas_para_atacar = 3
			_: # "normal"
				if "intervalo_ataque_segundos" in ai:
					ai.intervalo_ataque_segundos = 65.0
				if "tropas_minimas_para_atacar" in ai:
					ai.tropas_minimas_para_atacar = 5

# ─── Reinicio de Sesión (State Reset Loop) ────────────────────────────────────

## Restablece todos los parámetros de partida a los valores predeterminados y limpia slots de lobby.
## Llamado por PauseMenu / MatchEndScreen antes de regresar al menú principal.
func reiniciar_banco_partida() -> void:
	reset_to_defaults()
	starting_era = 0
	max_era = 9
	# Restablecer velocidad de simulación al valor normal inmediatamente
	Engine.time_scale = 1.0

	# Limpiar el diccionario y slots del lobby de red en MultiplayerManager
	var mm: Node = get_node_or_null("/root/MultiplayerManager")
	if is_instance_valid(mm) and mm.has_method("reiniciar_banco_partida"):
		mm.call("reiniciar_banco_partida")

	print("GameSettings: ✅ reiniciar_banco_partida() ejecutado — Configuración y slots de lobby reseteados a valores iniciales.")
