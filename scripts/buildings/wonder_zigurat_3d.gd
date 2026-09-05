## WonderZigurat3D — La Maravilla Sagrada del Cobre / Zigurat Era 2 (GDScript 2.0 / Godot 4).
##
## Estructura monumental de la Edad del Cobre.
## Hereda el cronómetro de victoria de 10 minutos de Wonder3D (rpc_iniciar_cuenta_regresiva_maravilla).
## Al completarse su construcción, el servidor lanza el RPC fiable a todos los slots.
## Si el Zigurat es demolido antes de que el reloj llegue a cero, se cancela la victoria.
##
## Costo de construcción (dbupgrade.dat Era 2):
##   Food: 3000, Wood: 2500, Gold: 1500, Stone: 1000
##
## HERENCIA TOTAL: Todo el sistema de cronómetro, RPC, señales, y MatchEndManager
## se reutiliza sin modificaciones desde Wonder3D.

class_name WonderZigurat3D
extends "res://scripts/buildings/wonder_3d.gd"

# ─── Costo Oficial dbupgrade.dat (Era 2 — Edad del Cobre) ────────────────────
const COSTO_CONSTRUCCION: Dictionary = {
	"food":  3000,
	"wood":  2500,
	"gold":  1500,
	"stone": 1000
}

func _init() -> void:
	building_name = "Zigurat Sagrado — Maravilla del Cobre"
	salud_maxima  = 3500.0  # Mayor que Wonder base (2500) por ser monumental
	salud_actual  = 3500.0
	radio_vision  = 55.0   # Radio visual extendido del monumento

func _ready() -> void:
	super._ready()
	add_to_group("wonders_era2")
	add_to_group("zigurat")

	# Verificar que la era actual permite construir el Zigurat (Era >= 2)
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		var cur_era: int = int(rm.era_actual) if "era_actual" in rm else 0
		if cur_era < 2:
			push_warning("WonderZigurat3D: El Zigurat es una Maravilla de la Era 2+. Era actual: %d" % cur_era)

# ─── Override visual post-construcción ───────────────────────────────────────

## Al completarse la construcción, el servidor lanza el RPC fiable de cronómetro.
## Wonder3D._on_wonder_completed() ya lo hace — este override añade VFX y anuncio.
func _on_wonder_completed() -> void:
	# Llamar al padre que ejecuta el RPC del cronómetro de 10 minutos
	super._on_wonder_completed()

	# Anuncio extendido del Zigurat (chat de red)
	var ncm: Node = get_node_or_null("/root/NetworkChatManager")
	if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
		ncm.call("enviar_mensaje_local",
			"🏛️ ¡EL ZIGURAT SAGRADO HA SIDO COMPLETADO! Era del Cobre — Cronómetro de Victoria: 10 Minutos."
		)

	# Activar halo de luz sagrada (si existe el nodo de efecto en la escena)
	var halo: Node = get_node_or_null("WonderGlowEffect")
	if is_instance_valid(halo) and halo.has_method("activate"):
		halo.call("activate")

	print("WonderZigurat3D '%s': Construcción completada. RPC de cronómetro enviado a todos los slots." % name)

# ─── RPC fiable: Iniciar Cronómetro de Victoria ──────────────────────────────
@rpc("call_local", "reliable")
func rpc_iniciar_cronometro_maravilla(duracion: float = 600.0) -> void:
	wonder_time_left = duracion
	is_wonder_active = true

	var ncm: Node = get_node_or_null("/root/NetworkChatManager")
	if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
		ncm.call("enviar_mensaje_local",
			"🏛️ ¡EL ZIGURAT SAGRADO HA SIDO COMPLETADO! Era del Cobre — Cronómetro de Victoria: 10 Minutos."
		)

	print("WonderZigurat3D '%s': Cronómetro de 10 minutos iniciado vía RPC síncrono (%.0fs)." % [name, wonder_time_left])

func declarar_victoria_match() -> void:
	print("WonderZigurat3D '%s': ¡Tiempo del Zigurat completado! Victoria de Maravilla." % name)
	is_wonder_active = false
	var is_player_win: bool = (bando == Bando.PLAYER)
	var mem: Node = get_node_or_null("/root/MatchEndManager")
	if is_instance_valid(mem):
		if mem.has_method("forzar_fin_partida"):
			mem.call("forzar_fin_partida", is_player_win, "Victoria por Maravilla (Zigurat Era 2)")
		elif mem.has_method("trigger_match_end"):
			mem.call("trigger_match_end", is_player_win)

## Verifica si el costo está disponible antes de permitir la construcción.
static func puede_construirse(rm: Node) -> bool:
	if not is_instance_valid(rm):
		return false
	var cur_era: int = int(rm.era_actual) if "era_actual" in rm else 0
	if cur_era < 2:
		return false
	if rm.has_method("puede_permitirse"):
		return rm.puede_permitirse(COSTO_CONSTRUCCION)
	return false
