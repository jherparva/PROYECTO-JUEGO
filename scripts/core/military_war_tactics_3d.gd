## MilitaryWarTactics3D — Gestor de Tácticas de Guerra y Micro-Gestión Avanzada 3D (Godot 4).
##
## Módulo táctico militar superior que opera por encima del movimiento básico RTS:
## 1. FLANKING AI COMPONENT: Divide automático pelotones de >8 soldados (60% frontal, 40% flanqueo).
## 2. FORMACIÓN EN FALANGE Y ESCUDOS: +30% de armadura balística si 3+ infantes están en formación cohesiva a <2.0m.
## 3. SMART TARGETING PRIORITIZATION: Los arqueros/tiradores priorizan cortar soporte enemigo (Profetas/Hackers/Oficiales).

class_name MilitaryWarTactics3D
extends Node3D

const CombatDamageCalculator = preload("res://scripts/core/combat_damage_calculator.gd")


# ─── Instancia Global (Singleton en escena) ──────────────────────────────────
static var instance: MilitaryWarTactics3D = null

# ─── Configuración Táctica ───────────────────────────────────────────────────
@export_group("Maniobra de Flanqueo")
@export var umbral_flanqueo_peloton: int = 8
@export var angulo_desvio_flanqueo_deg: float = 65.0
@export var radio_flanqueo_offset: float = 12.0

@export_group("Formación en Falange")
@export var min_unidades_falange: int = 3
@export var distancia_max_falange: float = 2.2
@export var bono_escudo_falange: float = 0.30 # +30% resistencia balística

# ─── Estado Interno ──────────────────────────────────────────────────────────
var _check_timer: float = 0.0

# ─── Ciclo de Vida ───────────────────────────────────────────────────────────

func _ready() -> void:
	instance = self
	add_to_group("military_war_tactics")
	print("MilitaryWarTactics3D: Gestor de Tácticas de Guerra e Inteligencia Militar activado.")

func _physics_process(delta: float) -> void:
	_check_timer += delta
	if _check_timer >= 0.5: # Evaluar falanges cada 0.5s para optimizar 20Hz
		_check_timer = 0.0
		_evaluar_formaciones_falange()
		_actualizar_vision_por_altura()

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULO 1 — MANIOBRA DE FLANQUEO AUTOMÁTICO (FLANKING AI COMPONENT)
# ─────────────────────────────────────────────────────────────────────────────

## Intercepta órdenes de ataque masivo y coordina flanqueos estratégicos vía RPC.
@rpc("any_peer", "call_local", "reliable")
func rpc_coordinar_flanqueo(unidades_paths: Array, target_path: NodePath) -> void:
	var target_node := get_node_or_null(target_path) as Node3D
	if not is_instance_valid(target_node):
		return

	var unidades_validas: Array[Node3D] = []
	for p in unidades_paths:
		var u := get_node_or_null(NodePath(str(p))) as Node3D
		if is_instance_valid(u) and (u is CharacterBody3D or u.has_method("command_attack")):
			unidades_validas.append(u)

	if unidades_validas.is_empty():
		return

	# Si es un ataque masivo (N >= 8 unidades) contra estructura fortificada o línea enemiga
	var es_estructura_fortificada: bool = (
		target_node is TownCenter3D or 
		target_node.is_in_group("town_centers") or 
		target_node.is_in_group("fortified_buildings") or 
		target_node.is_in_group("wonders") or 
		target_node.is_in_group("towers") or
		target_node.is_in_group("buildings") or
		target_node.is_in_group("buildings_3d")
	)

	var es_linea_enemiga: bool = (
		target_node.is_in_group("military_units") or
		target_node.is_in_group("infantry_3d") or
		target_node.is_in_group("archers_3d") or
		target_node.is_in_group("vehicles_3d") or
		target_node.is_in_group("enemy_units") or
		target_node.is_in_group("player_units") or
		target_node is CharacterBody3D
	)

	if unidades_validas.size() >= umbral_flanqueo_peloton and (es_estructura_fortificada or es_linea_enemiga):
		_ejecutar_despliegue_flanqueo(unidades_validas, target_node)
	else:
		# Ataque directo estándar
		_ejecutar_ataque_directo(unidades_validas, target_node)

func _ejecutar_despliegue_flanqueo(peloton: Array[Node3D], target: Node3D) -> void:
	var total := peloton.size()
	var frontal_count := int(round(float(total) * 0.60)) # 60% asalto frontal
	
	# Calcular vector de dirección del pelotón al objetivo
	var target_pos := target.global_position
	var squad_center := Vector3.ZERO
	for u in peloton:
		squad_center += u.global_position
	squad_center /= float(total)

	var dir_to_squad := (squad_center - target_pos)
	dir_to_squad.y = 0.0
	if dir_to_squad.length_squared() < 0.01:
		dir_to_squad = Vector3.FORWARD
	else:
		dir_to_squad = dir_to_squad.normalized()

	# Calcular vectores de desvío lateral a ±65 grados tangenciales con offset de 12m
	var rad_ang := deg_to_rad(angulo_desvio_flanqueo_deg) # 65.0°
	var dir_flank_left  := dir_to_squad.rotated(Vector3.UP, rad_ang)
	var dir_flank_right := dir_to_squad.rotated(Vector3.UP, -rad_ang)

	var pos_flank_left  := target_pos + dir_flank_left * radio_flanqueo_offset   # 12.0m offset
	var pos_flank_right := target_pos + dir_flank_right * radio_flanqueo_offset  # 12.0m offset

	print("MilitaryWarTactics3D: ⚔️ Maniobra de Flanqueo activada para %d unidades (60%% Frontal, 40%% Envolvente ±65° / 12m)." % total)

	for i in range(total):
		var u := peloton[i]
		if not is_instance_valid(u):
			continue

		if i < frontal_count:
			# 60% Asalto Frontal Directo
			_ordenar_ataque_unidad(u, target)
		else:
			# 40% Asalto Envolvente por Flancos posicionándose a ±65° tangenciales (offset de 12m)
			var flank_dest := pos_flank_left if ((i - frontal_count) % 2 == 0) else pos_flank_right
			if u.has_method("set_status_text"):
				u.call("set_status_text", "🔄 Flanqueando Retaguardia", 3.0)

			# Desplazar a la posición del flanco y luego atacar al llegar
			if "state_machine" in u and u.state_machine:
				u.state_machine.change_state(&"Move", {
					"target_node": target,
					"target_position": flank_dest,
					"stopping_distance": 2.5,
					"on_arrival_state": &"Attacking",
					"on_arrival_context": {"target": target}
				})
			elif u.has_method("command_move"):
				u.call("command_move", flank_dest)

func _ejecutar_ataque_directo(peloton: Array[Node3D], target: Node3D) -> void:
	for u in peloton:
		if is_instance_valid(u):
			_ordenar_ataque_unidad(u, target)

func _ordenar_ataque_unidad(u: Node3D, target: Node3D) -> void:
	if u.has_method("command_attack"):
		u.call("command_attack", target)
	elif "state_machine" in u and u.state_machine:
		u.state_machine.change_state(&"Attacking", {"target": target})

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULO 2 — POSTURA DE FALANGE Y ESCUDOS (FORMACIÓN COHESIVA DEFENSIVA)
# ─────────────────────────────────────────────────────────────────────────────

func _evaluar_formaciones_falange() -> void:
	var military_units := get_tree().get_nodes_in_group("military_units")
	if military_units.is_empty():
		military_units = get_tree().get_nodes_in_group("units_3d")

	# Limpiar estado previo de falange
	for u in military_units:
		if is_instance_valid(u):
			u.set_meta("phalanx_active", false)

	# Filtrar infantes vivos en postura táctica MANTENER_TERRENO
	var phalanx_candidates: Array[Node3D] = []
	for u in military_units:
		if is_instance_valid(u) and u is Node3D:
			if not (u.has_method("is_dead") and u.call("is_dead")):
				if _es_infanteria(u) and _verificar_postura_mantener_terreno(u):
					phalanx_candidates.append(u as Node3D)

	# Agrupar unidades por cercanía <= 2.2m en postura MANTENER_TERRENO
	var visited: Array[Node3D] = []
	for i in range(phalanx_candidates.size()):
		var u1 := phalanx_candidates[i]
		if visited.has(u1):
			continue

		var cluster: Array[Node3D] = [u1]
		var my_bando: int = int(u1.get("bando")) if "bando" in u1 else 0

		for j in range(i + 1, phalanx_candidates.size()):
			var u2 := phalanx_candidates[j]
			var other_bando: int = int(u2.get("bando")) if "bando" in u2 else 0
			if my_bando == other_bando:
				if u1.global_position.distance_to(u2.global_position) <= distancia_max_falange: # 2.2m
					cluster.append(u2)

		# Si hay 3+ infantes aliados agrupados a <= 2.2m en postura MANTENER_TERRENO
		if cluster.size() >= min_unidades_falange: # 3
			for member in cluster:
				visited.append(member)
				member.set_meta("phalanx_active", true)
				member.set_meta("phalanx_armor_bonus", bono_escudo_falange) # 0.30

				# Aplicar feedback visual de falange
				if member.has_method("set_status_text") and not member.has_meta("status_falange_shown"):
					member.call("set_status_text", "🛡️ Falange Activa (-30% Daño Balístico)", 1.5)
					member.set_meta("status_falange_shown", true)

static func _es_infanteria(u: Node) -> bool:
	if not is_instance_valid(u):
		return false
	if u.is_in_group("infantry_3d") or u.is_in_group("infantry") or (u is Soldier3D):
		return true
	var u_type: String = str(u.get("unit_type")) if "unit_type" in u else ""
	return u_type.to_lower() == "melee" or u_type.to_lower() == "infantry"

static func _verificar_postura_mantener_terreno(u: Node) -> bool:
	if not is_instance_valid(u):
		return false
	if "postura_actual" in u:
		var p = u.get("postura_actual")
		# Postura.MANTENER_TERRENO es enum valor 2
		if str(p) == "2" or str(p) == "MANTENER_TERRENO":
			return true
	if "postura" in u:
		var p = u.get("postura")
		if str(p) == "2" or str(p) == "MANTENER_TERRENO":
			return true
	return false

## Consulta pública estática utilizada por Projectile3D para reducir daño de proyectiles balísticos
static func aplicar_reduccion_danio_falange(victim: Node, incoming_damage: float) -> float:
	if not is_instance_valid(victim):
		return incoming_damage

	# 1. Comprobar si ya tiene meta activo verificado por el gestor
	if victim.has_meta("phalanx_active") and bool(victim.get_meta("phalanx_active")):
		var bonus: float = float(victim.get_meta("phalanx_armor_bonus", 0.30))
		return incoming_damage * (1.0 - bonus) # Mitigación estricta del -30%

	# 2. Evaluación pasiva local síncrona sin RPC: verificar si cumple 3+ infantes a <= 2.2m en MANTENER_TERRENO
	if es_victima_en_falange(victim):
		victim.set_meta("phalanx_active", true)
		victim.set_meta("phalanx_armor_bonus", 0.30)
		return incoming_damage * 0.70 # -30% estricto

	return incoming_damage

## Evalúa síncronamente si una unidad está dentro de una falange de 3+ infantes aliados a <= 2.2m en MANTENER_TERRENO
static func es_victima_en_falange(victim: Node) -> bool:
	if not is_instance_valid(victim) or not (victim is Node3D):
		return false
	var v_node := victim as Node3D
	if not _es_infanteria(v_node) or not _verificar_postura_mantener_terreno(v_node):
		return false

	var tree := v_node.get_tree()
	if not tree:
		return false

	var my_bando: int = int(v_node.get("bando")) if "bando" in v_node else 0
	var group_name := "player_units" if my_bando == 0 else "enemy_units"
	var allies := tree.get_nodes_in_group(group_name)

	var count_in_formation := 1
	for ally in allies:
		if ally == v_node or not is_instance_valid(ally) or not (ally is Node3D):
			continue
		var a_node := ally as Node3D
		if _es_infanteria(a_node) and _verificar_postura_mantener_terreno(a_node):
			if v_node.global_position.distance_to(a_node.global_position) <= 2.2:
				count_in_formation += 1
				if count_in_formation >= 3:
					return true
	return false

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULO 3 — MÁQUINA DE ESTADOS .TAI ORIGINAL Y FOCO DE ATAQUE INTELIGENTE
# ─────────────────────────────────────────────────────────────────────────────

## Actualiza el bono de vision por elevacion (dbcliffterrain.dat) para todas las
## unidades activas: unidades a >= 2m de altura sobre Y=0 reciben +2m de radio_vision.
func _actualizar_vision_por_altura() -> void:
	var all_units: Array[Node] = []
	all_units.append_array(get_tree().get_nodes_in_group("player_units"))
	all_units.append_array(get_tree().get_nodes_in_group("enemy_units"))
	all_units.append_array(get_tree().get_nodes_in_group("military_units"))

	for unit in all_units:
		if not is_instance_valid(unit) or not (unit is Node3D):
			continue
		var u := unit as Node3D
		if not ("radio_vision" in u):
			continue

		# Calcular bonus de vision segun altura
		var height_bonus: float = CombatDamageCalculator.calcular_bonus_vision_altura(u, 0.0)
		var base_vision: float

		# Guardar vision base si no existe la meta
		if u.has_meta("base_radio_vision"):
			base_vision = float(u.get_meta("base_radio_vision"))
		else:
			base_vision = float(u.get("radio_vision"))
			u.set_meta("base_radio_vision", base_vision)

		var new_vision := base_vision + height_bonus
		if absf(float(u.get("radio_vision")) - new_vision) > 0.01:
			u.set("radio_vision", new_vision)

## Calcula el bono táctico de altura entre un atacante y un defensor (dbcliffterrain.dat).
## Retorna un diccionario con multiplicadores de daño, bono de visión y penalización de valle.
static func calcular_bono_altura(atacante: Node3D, defensor: Node3D) -> Dictionary:
	var result: Dictionary = {
		"damage_mult": 1.0,
		"vision_bonus": 0.0,
		"penalty_mult": 1.0,
		"is_elevated": false
	}
	if not is_instance_valid(atacante) or not is_instance_valid(defensor):
		return result
	
	var dy: float = _posicion_segura(atacante).y - _posicion_segura(defensor).y
	if dy >= 1.5:
		result["damage_mult"] = 1.25 # +25% de daño
		result["vision_bonus"] = 2.0  # +2.0m de visión
		result["penalty_mult"] = 0.85 # -15% para quien dispara hacia arriba
		result["is_elevated"] = true
	elif dy <= -1.5:
		result["damage_mult"] = 0.85
		result["penalty_mult"] = 0.85
	
	return result

static func _posicion_segura(n: Node3D) -> Vector3:
	return n.global_position if n.is_inside_tree() else n.position

## Regla FSM 'CheckRange' de Empire Earth (generic attack.tai)
## Determina si el objetivo se encuentra dentro de la distancia de ataque efectiva.
static func check_range(attacker: Node3D, target: Node3D) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false

	var dist := _posicion_segura(attacker).distance_to(_posicion_segura(target))
	var atk_range: float = 2.5 # Default melee
	if attacker.has_meta("attack_range"):
		atk_range = float(attacker.get_meta("attack_range"))
	elif "attack_range" in attacker:
		atk_range = float(attacker.get("attack_range"))
	elif attacker.has_method("get_attack_range"):
		atk_range = float(attacker.call("get_attack_range"))
	elif attacker.is_in_group("archers_3d") or attacker.is_in_group("ranged"):
		atk_range = 14.0

	return dist <= atk_range

## Regla FSM 'ShouldIFollow' de Empire Earth (generic movement.tai / generic attack.tai)
## Determina si la unidad debe continuar persiguiendo al enemigo o romper el contacto (Disengage/Leash).
static func should_i_follow(attacker: Node3D, target: Node3D, max_leash: float = 35.0) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false

	# 1. Si la unidad está en postura MANTENER_TERRENO (Hold Ground), nunca persigue
	if _verificar_postura_mantener_terreno(attacker):
		return false

	# 2. Si el objetivo está muerto o destruido
	if target.has_method("is_dead") and bool(target.call("is_dead")):
		return false
	if target.has_method("is_destroyed") and bool(target.call("is_destroyed")):
		return false

	# 3. Leash de distancia máxima entre atacante y objetivo
	var dist := _posicion_segura(attacker).distance_to(_posicion_segura(target))
	if dist > max_leash:
		return false

	# 4. Leash respecto a la posición base o de anclaje de la unidad
	if attacker.has_meta("anchor_position"):
		var anchor: Vector3 = attacker.get_meta("anchor_position")
		if _posicion_segura(attacker).distance_to(anchor) > max_leash * 1.5:
			return false

	return true

## Calcula el valor numérico de prioridad táctica (Smart Targeting EE):
## Sacerdotes (100) > Aldeanos (75) > Cuarteles (50) > Capitolio (30) > Otros (10)
static func calcular_prioridad_objetivo(target: Node) -> int:
	if not is_instance_valid(target):
		return 0

	var t_name: String = target.name.to_lower()
	var t_title: String = str(target.get("unit_name")).to_lower() if "unit_name" in target else ""
	var bld_name: String = str(target.get("building_name")).to_lower() if "building_name" in target else ""

	# 1. Sacerdotes / Profetas (Corta conversiones y milagros)
	if "prophet" in t_name or "priest" in t_name or "sacerdote" in t_title or "profeta" in t_title or target.is_in_group("priests") or target.is_in_group("prophets"):
		return 100

	# 2. Aldeanos (Asfixia económica)
	if target is Villager3D or target.is_in_group("villagers") or target.has_method("command_gather") or "villager" in t_name or "aldeano" in t_title:
		return 75

	# 3. Cuarteles / Edificios Militares de Producción (Frena refuerzos bélicos)
	if target is Barracks3D or target.is_in_group("barracks") or target.is_in_group("military_buildings") or "cuartel" in t_name or "barrack" in t_name or "cuartel" in bld_name:
		return 50

	# 4. Capitolio / TownCenter (Objetivo de asedio masivo)
	if target is TownCenter3D or target.is_in_group("town_centers") or "towncenter" in t_name or "capitolio" in bld_name:
		return 30

	# 5. Otras unidades de combate y defensas
	return 10

## Redistribuye objetivos de combate aplicando la jerarquía estricta de EE:
## Sacerdotes > Aldeanos > Cuarteles > Capitolio
func evaluar_prioridades_peloton(peloton_atacantes: Array[Node3D], peloton_enemigo: Array[Node3D]) -> void:
	if peloton_atacantes.is_empty() or peloton_enemigo.is_empty():
		return

	# Separar objetivos enemigos por jerarquía de prioridad táctica
	var sacerdotes: Array[Node3D] = []
	var aldeanos: Array[Node3D] = []
	var cuarteles: Array[Node3D] = []
	var capitolios: Array[Node3D] = []
	var otros: Array[Node3D] = []

	for enemy in peloton_enemigo:
		if not is_instance_valid(enemy):
			continue
		var prio := calcular_prioridad_objetivo(enemy)
		match prio:
			100:
				sacerdotes.append(enemy)
			75:
				aldeanos.append(enemy)
			50:
				cuarteles.append(enemy)
			30:
				capitolios.append(enemy)
			_:
				otros.append(enemy)

	# Ordenar el conjunto final respetando estrictamente la jerarquía oficial
	var target_pool: Array[Node3D] = []
	target_pool.append_array(sacerdotes)
	target_pool.append_array(aldeanos)
	target_pool.append_array(cuarteles)
	target_pool.append_array(capitolios)
	target_pool.append_array(otros)

	if target_pool.is_empty():
		return

	var idx: int = 0
	for attacker in peloton_atacantes:
		if is_instance_valid(attacker):
			var selected_target: Node3D = target_pool[idx % target_pool.size()]
			idx += 1
			_ordenar_ataque_unidad(attacker, selected_target)
