## CivPointsManager — Gestor de Puntos de Civilización y Mejoras Personalizadas (Godot 4.3).
##
## Administra los puntos de civilización (Civ Points) y las ramas de mejoras tecnológicas:
## - "infantry_melee": +10% Daño Melee por nivel (Máx Nivel 3).
## - "infantry_ranged": +15% Rango de Ataque por nivel (Máx Nivel 3).
## - "cyber_robotic": +10% HP Máximo en Drones y Cyborgs por nivel (Máx Nivel 3).
## - "economy_speed": +10% Tasa de Recolección de Aldeanos por nivel (Máx Nivel 3).

extends Node

signal civ_points_changed(new_points: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal civ_settings_locked()

const MAX_UPGRADE_LEVEL: int = 3

# ─── Estado Interno ────────────────────────────────────────────────────────────
var total_civ_points: int = 100
var puntos_civ: int = 100
var is_locked: bool = false
var puntos_fe: float = 0.0

signal fe_cambiada(nuevos_puntos: float)

var upgrade_levels: Dictionary = {
	"infantry_melee": 0,
	"infantry_ranged": 0,
	"cyber_robotic": 0,
	"economy_speed": 0,
	"cavalry_speed": 0,
	"siege_power": 0,
	"defense_walls": 0
}

## Acumula puntos de fe generados por la teocracia eclesiástica (ej. aldeanos rezando en templos)
func agregar_fe(cantidad: float) -> void:
	puntos_fe += cantidad
	fe_cambiada.emit(puntos_fe)

## Consume puntos de fe para milagros o cataclismos divinos (ej. Profetas)
func gastar_fe(cantidad: float) -> bool:
	if puntos_fe >= cantidad:
		puntos_fe -= cantidad
		fe_cambiada.emit(puntos_fe)
		return true
	return false

# ─── Instancia Autoload / Acceso Global ─────────────────────────────────────────
static var instance: Node = null

func _ready() -> void:
	instance = self
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("civ_points_manager")

	# Escuchar avance de Era para otorgar +2 puntos
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		rm.era_evolucionada.connect(_on_era_evolucionada)

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var player_id: int = 1
	if nueva_era != null and nueva_era is int:
		player_id = int(player_id_or_era)
	elif player_id_or_era is int:
		player_id = int(player_id_or_era)

	if player_id != local_id:
		return

	puntos_civ += 2
	print("CivPointsManager: ¡Era evolucionada! +2 Puntos de Civilización otorgados (Total: %d)." % puntos_civ)
	civ_points_changed.emit(puntos_civ)

# ─── Compras por RPC Fiables ──────────────────────────────────────────────────

func comprar_mejora_local(upgrade_id: String) -> void:
	if is_locked:
		print("CivPointsManager: 🔒 Las ventajas de civilización están bloqueadas.")
		return
	if not upgrade_levels.has(upgrade_id):
		return
	if puntos_civ < 1 or int(upgrade_levels[upgrade_id]) >= MAX_UPGRADE_LEVEL:
		return

	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("rpc_comprar_mejora_civ", upgrade_id)
	else:
		rpc_comprar_mejora_civ(upgrade_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_comprar_mejora_civ(upgrade_id: String) -> void:
	if is_locked:
		print("CivPointsManager: 🔒 Rechazando compra por RPC: árbol bloqueado.")
		return
	if not upgrade_levels.has(upgrade_id):
		return
	if puntos_civ < 1:
		print("CivPointsManager: Puntos insuficientes para comprar '%s'." % upgrade_id)
		return

	var cur_lvl: int = int(upgrade_levels[upgrade_id])
	if cur_lvl >= MAX_UPGRADE_LEVEL:
		print("CivPointsManager: Rama '%s' ya alcanzó el Nivel Máximo (3/3)." % upgrade_id)
		return

	puntos_civ -= 1
	total_civ_points = puntos_civ
	upgrade_levels[upgrade_id] = cur_lvl + 1

	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("minimap_alert")

	_aplicar_multiplicadores_globales(upgrade_id, cur_lvl + 1)
	civ_points_changed.emit(puntos_civ)
	upgrade_purchased.emit(upgrade_id, cur_lvl + 1)

	print("CivPointsManager: Mejora '%s' comprada a Nivel %d/3. Puntos restantes: %d" % [
		upgrade_id, cur_lvl + 1, puntos_civ
	])

# ─── Aplicación de Multiplicadores a Unidades Existentes y Futuras ───────────

func _aplicar_multiplicadores_globales(upgrade_id: String, level: int) -> void:
	match upgrade_id:
		"infantry_melee":
			var mult := 1.0 + (float(level) * 0.10) # +10% por nivel
			for u in get_tree().get_nodes_in_group("units_3d"):
				if is_instance_valid(u) and u.has_method("command_move") and "attack_type" in u and u.get("attack_type") == "melee":
					if "daño" in u:
						u.set("daño", float(u.get("_daño_base")) * mult)
		"infantry_ranged":
			var mult := 1.0 + (float(level) * 0.15) # +15% por nivel
			for u in get_tree().get_nodes_in_group("units_3d"):
				if is_instance_valid(u) and "attack_type" in u and u.get("attack_type") == "ranged":
					if "rango_ataque" in u:
						u.set("rango_ataque", float(u.get("rango_ataque")) * mult)
		"cyber_robotic":
			var mult := 1.0 + (float(level) * 0.10) # +10% HP por nivel
			for u in get_tree().get_nodes_in_group("drones"):
				if is_instance_valid(u) and "salud_maxima" in u:
					u.set("salud_maxima", float(u.get("salud_maxima")) * mult)
		"economy_speed":
			var mult := 1.0 + (float(level) * 0.10) # +10% gather rate
			var rm: Node = get_node_or_null("/root/ResourceManager")
			if is_instance_valid(rm) and "tech_gather_bonuses" in rm:
				var cur_bonus: float = float(rm.tech_gather_bonuses.get("wood", 1.0))
				rm.tech_gather_bonuses["wood"] = cur_bonus + 0.10
				rm.tech_gather_bonuses["food"] = cur_bonus + 0.10
				rm.tech_gather_bonuses["gold"] = cur_bonus + 0.10
				rm.tech_gather_bonuses["iron"] = cur_bonus + 0.10
				rm.tech_gather_bonuses["stone"] = cur_bonus + 0.10
		"cavalry_speed":
			var mult := 1.0 + (float(level) * 0.15) # +15% velocidad caballería
			for u in get_tree().get_nodes_in_group("units_3d"):
				if is_instance_valid(u) and "speed" in u and ("cavalry" in u.name.to_lower() or "caballero" in u.name.to_lower()):
					u.set("speed", float(u.get("speed")) * mult)
		"siege_power":
			var mult := 1.0 + (float(level) * 0.20) # +20% asedio
			for u in get_tree().get_nodes_in_group("units_3d"):
				if is_instance_valid(u) and "daño" in u and ("catapult" in u.name.to_lower() or "canon" in u.name.to_lower() or "tanque" in u.name.to_lower()):
					u.set("daño", float(u.get("daño")) * mult)
		"defense_walls":
			var mult := 1.0 + (float(level) * 0.20) # +20% HP murallas y edificios
			for b in get_tree().get_nodes_in_group("player_buildings"):
				if is_instance_valid(b) and "salud_maxima" in b:
					b.set("salud_maxima", float(b.get("salud_maxima")) * mult)

func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))

func lock_civ_settings(points_spent: int = 0) -> void:
	if is_locked:
		return
	is_locked = true
	if points_spent > 0:
		puntos_civ = maxi(0, puntos_civ - points_spent)
		total_civ_points = puntos_civ
		civ_points_changed.emit(puntos_civ)

	# Guardar y aplicar permanentemente los multiplicadores en el ResourceManager local
	var ml = Engine.get_main_loop()
	var rm: Node = null
	if ml and "root" in ml and ml.root:
		rm = ml.root.get_node_or_null("ResourceManager")
		if not is_instance_valid(rm):
			rm = ml.root.get_node_or_null("GlobalResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")

	if is_instance_valid(rm):
		for up_id in upgrade_levels:
			var lvl: int = int(upgrade_levels[up_id])
			if lvl > 0:
				_aplicar_multiplicadores_globales(up_id, lvl)

	civ_settings_locked.emit()
	print("CivPointsManager: 🔒 Ventajas de civilización BLOQUEADAS permanentemente (Puntos restantes: %d)." % puntos_civ)

# ─── Reinicio de Sesión (State Reset Loop) ────────────────────────────────────

## Restablece los puntos de civilización a 100 y vacía todos los niveles del árbol de ventajas de civilización.
## Llamado por PauseMenu / MatchEndScreen antes de regresar al menú principal.
func reiniciar_banco_partida() -> void:
	total_civ_points = 100
	puntos_civ = 100
	puntos_fe = 0.0
	is_locked = false
	for key in upgrade_levels.keys():
		upgrade_levels[key] = 0
	civ_points_changed.emit(puntos_civ)
	print("CivPointsManager: ✅ reiniciar_banco_partida() ejecutado — Puntos=100, is_locked=false, Niveles=0.")
