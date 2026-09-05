## NetworkChatManager — Gestor de Chat y Eventos en Red RTS (GDScript 2.0 / Godot 4).
##
## Administra la comunicación de texto y las notificaciones globales entre jugadores y bots:
## - Envíos RPC fiables de mensajes de chat (@rpc("any_peer", "call_local", "reliable")).
## - Notificaciones globales sincrónicas de avance de era con banner y sonido.
## - Catálogo completo de los 30 Taunts clásicos de Empire Earth (texto y audio).
## - Llamadas automáticas 'bot_taunt_destruccion_edificio' y 'bot_taunt_asedio_capitolio'.
## - Formateo RichTextLabel con colores por bando (Dorado Host, Cian Clientes, Verde Sistema).

class_name NetworkChatManager
extends Node

signal message_received(sender_name: String, text: String, color_code: String)
signal era_banner_announced(player_name: String, era_id: int)

# ─── Instancia Autoload / Acceso Global ─────────────────────────────────────────
static var instance: NetworkChatManager = null

const ERA_NAMES: Array[String] = [
	"Prehistórica", "Piedra", "Bronce", "Hierro", "Medieval",
	"Renacimiento", "Industrial", "Atómica", "Digital", "Nano-Futurista"
]

# ─── Base de Datos de los 30 Taunts Oficiales de Empire Earth ────────────────
const TAUNTS_OFICIALES_EE: Dictionary = {
	1: "Sí.",
	2: "No.",
	3: "Necesito comida.",
	4: "Necesito madera.",
	5: "Necesito piedra.",
	6: "Necesito oro.",
	7: "Necesito hierro.",
	8: "Por favor, dame recursos.",
	9: "¿Tienes recursos sobrantes?",
	10: "¡A la carga!",
	11: "¡Retirada!",
	12: "¡Ayuda! ¡Me están atacando!",
	13: "¡Destruye su Centro Urbano!",
	14: "Construye una maravilla.",
	15: "¡No te rindas!",
	16: "¡Ríndete mientras puedas!",
	17: "¡Buen juego!",
	18: "Estoy listo.",
	19: "¡Tus defensas son de papel!",
	20: "¡Mis sacerdotes convertirán a todo tu ejército!",
	21: "¡Mis tropas están listas para el asalto!",
	22: "¡Tus aldeanos están indefensos!",
	23: "¡Victoria o muerte!",
	24: "¡Has cometido un grave error estratégico!",
	25: "¡Mis arqueros oscurecerán el cielo!",
	26: "¡Cuidado con las armas de asedio!",
	27: "¡Nuestra tecnología es superior!",
	28: "¡No podrás resistir este asedio!",
	29: "¡Tus edificios arderán!",
	30: "¡Ríndete y acepta tu destino!"
}

func _ready() -> void:
	instance = self
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("network_chat_manager")

	# Escuchar eventos locales de evolución de era
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		rm.era_evolucionada.connect(_on_local_era_evolucionada)

# ─── Transmisión de Mensajes por RPC ──────────────────────────────────────────

func enviar_mensaje_local(texto: String) -> void:
	var texto_limpio := texto.strip_edges()
	if texto_limpio.is_empty():
		return

	var my_id := 1
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		my_id = multiplayer.get_unique_id()

	var my_name := "Jugador_%d" % my_id
	if my_id == 1:
		my_name = "Host (Jugador 1)"

	var mensaje_a_transmitir := texto_limpio

	# Comprobar si es un número de burla (Taunt 1..30)
	if texto_limpio.is_valid_int():
		var t_id := texto_limpio.to_int()
		if TAUNTS_OFICIALES_EE.has(t_id):
			mensaje_a_transmitir = "[Taunt #%d] %s" % [t_id, TAUNTS_OFICIALES_EE[t_id]]
			_reproducir_sfx_taunt()
		elif t_id > 0:
			mensaje_a_transmitir = "[Taunt #%d]" % t_id
			_reproducir_sfx_taunt()

	# Transmitir por RPC a todos los clientes y host
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("rpc_enviar_mensaje", my_id, my_name, mensaje_a_transmitir)
	else:
		rpc_enviar_mensaje(my_id, my_name, mensaje_a_transmitir)

@rpc("any_peer", "call_local", "reliable")
func rpc_enviar_mensaje(sender_id: int, sender_name: String, mensaje: String) -> void:
	var color_hex := "#33CCFF" # Cian para clientes

	if sender_id == 1:
		color_hex = "#FFCC00" # Dorado para Host
	elif sender_id == 0:
		color_hex = "#33FF66" # Verde brillante para el Sistema / Servidor

	if mensaje.begins_with("[Taunt #") or mensaje.begins_with("🤖"):
		_reproducir_sfx_taunt()

	message_received.emit(sender_name, mensaje, color_hex)
	print("Chat: [%s] %s" % [sender_name, mensaje])

func _reproducir_sfx_taunt() -> void:
	var sm: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.call("jugar_sfx_interfaz", "minimap_alert")

# ─── Banderas Globales de Avance de Era ───────────────────────────────────────

func _on_local_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var era_val: int = 0
	var player_id: int = 1
	if nueva_era != null and nueva_era is int:
		player_id = int(player_id_or_era)
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)

	var p_name := "Jugador_%d" % player_id
	if multiplayer.is_server():
		rpc("rpc_notificar_avance_era", p_name, era_val)

@rpc("authority", "call_local", "reliable")
func rpc_notificar_avance_era(player_name: String, nueva_era_id: int) -> void:
	var era_str := ERA_NAMES[nueva_era_id] if (nueva_era_id >= 0 and nueva_era_id < ERA_NAMES.size()) else "Nueva Era"
	var msg_banner := "📢 ¡%s HA AVANZADO A LA ERA %s!" % [player_name.to_upper(), era_str.to_upper()]

	# Reproducir sonido síncrono de fanfarria
	var sm: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.call("jugar_sfx_interfaz", "era_evolution")

	# Emitir a la UI del HUD
	era_banner_announced.emit(player_name, nueva_era_id)
	rpc_enviar_mensaje(0, "SISTEMA", msg_banner)

# ─── Burlas Automáticas de Bots de Skirmish ─────────────────────────────────

## Disparado automáticamente cuando la IA o sus tropas destruyen un edificio
func bot_taunt_destruccion_edificio(bot_name: String, building_name: String) -> void:
	var frases: Array[String] = [
		"¡Tus edificios arderán!",
		"¡Otro de tus bastiones ha sido destruido! (%s)" % building_name,
		"¡Tus defensas son de papel! Caída de %s." % building_name
	]
	var frase: String = frases[randi() % frases.size()]
	var mensaje := "🤖 %s" % frase
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("rpc_enviar_mensaje", 0, bot_name, mensaje)
	else:
		rpc_enviar_mensaje(0, bot_name, mensaje)

## Disparado automáticamente cuando la IA asedia el Capitolio / Town Center
func bot_taunt_asedio_capitolio(bot_name: String) -> void:
	var frases: Array[String] = [
		"¡No podrás resistir este asedio! ¡Tu Capitolio caerá!",
		"¡Ríndete y acepta tu destino! El Capitolio está rodeado.",
		"¡Destruye su Centro Urbano! ¡Victoria o muerte!"
	]
	var frase: String = frases[randi() % frases.size()]
	var mensaje := "🤖 %s" % frase
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("rpc_enviar_mensaje", 0, bot_name, mensaje)
	else:
		rpc_enviar_mensaje(0, bot_name, mensaje)

## Disparado por la IA cuando elimina el Capitolio del jugador
func bot_taunt_victoria(bot_name: String) -> void:
	var mensaje := "🤖 ¡Tu civilización ha caído ante la máquina! ¡Victoria total!"
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("rpc_enviar_mensaje", 0, bot_name, mensaje)
	else:
		rpc_enviar_mensaje(0, bot_name, mensaje)
