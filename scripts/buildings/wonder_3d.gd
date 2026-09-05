## Wonder3D — Monumento / Maravilla 3D (GDScript 2.0 / Godot 4).
##
## Edificio supremo de condición de victoria por tiempo (10 Minutos / 600s).

class_name Wonder3D
extends "res://scripts/buildings/building_base_3d.gd"

signal wonder_countdown_ticked(time_left: float)

var wonder_time_left: float = 600.0
var is_wonder_active: bool = false

func _init() -> void:
	building_name = "Maravilla del Mundo"
	salud_maxima = 2500.0
	salud_actual = 2500.0
	radio_vision = 45.0

func _ready() -> void:
	super._ready()
	add_to_group("wonders")
	add_to_group("wonders_3d")
	construction_completed.connect(_on_wonder_completed)
	destroyed.connect(_on_wonder_destroyed)

func _process(delta: float) -> void:
	if not is_wonder_active or is_dead or is_under_construction:
		return

	wonder_time_left -= delta
	wonder_countdown_ticked.emit(wonder_time_left)

	if wonder_time_left <= 0.0:
		is_wonder_active = false
		declarar_victoria_match()

func _on_wonder_completed() -> void:
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			rpc("rpc_iniciar_cronometro_maravilla", 600.0)
	else:
		rpc_iniciar_cronometro_maravilla(600.0)

@rpc("call_local", "reliable")
func rpc_iniciar_cronometro_maravilla(duracion: float = 600.0) -> void:
	wonder_time_left = duracion
	is_wonder_active = true

	var ncm: Node = get_node_or_null("/root/NetworkChatManager")
	if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
		ncm.call("enviar_mensaje_local", "🏛️ ¡UNA MARAVILLA HA SIDO CONSTRUIDA! Cronómetro de Victoria: 10 Minutos.")

	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("era_evolution")

	print("Wonder3D '%s': Cronómetro de victoria iniciado (%.0fs)." % [name, wonder_time_left])

@rpc("call_local", "reliable")
func rpc_iniciar_cuenta_regresiva_maravilla(duracion: float = 600.0) -> void:
	rpc_iniciar_cronometro_maravilla(duracion)

func _on_wonder_destroyed() -> void:
	is_wonder_active = false
	var ncm: Node = get_node_or_null("/root/NetworkChatManager")
	if is_instance_valid(ncm) and ncm.has_method("enviar_mensaje_local"):
		ncm.call("enviar_mensaje_local", "💥 ¡LA MARAVILLA HA SIDO DESTRUIDA! El cronómetro de victoria se ha cancelado.")

func declarar_victoria_match() -> void:
	print("Wonder3D '%s': ¡Tiempo agotado! Victoria de Maravilla." % name)
	var mem: Node = get_node_or_null("/root/MatchEndManager")
	if is_instance_valid(mem):
		var is_player_win: bool = (bando == Bando.PLAYER)
		if mem.has_method("forzar_fin_partida"):
			mem.call("forzar_fin_partida", is_player_win, "Victoria por Maravilla")
		elif mem.has_method("trigger_match_end"):
			mem.call("trigger_match_end", is_player_win)

func _trigger_wonder_victory() -> void:
	declarar_victoria_match()
