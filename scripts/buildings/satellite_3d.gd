## Satellite3D — Satélite de Enlace Cuántico 3D (GDScript 2.0 / Godot 4).
##
## Edificio tecnológico de la Era Digital (Era 8) que proyecta escaneos de radar en la Niebla de Guerra.

class_name Satellite3D
extends "res://scripts/buildings/building_base_3d.gd"

signal radar_scan_activated(target_pos: Vector3)
signal cooldown_ticked(time_left: float)

const RADAR_RADIUS: float = 30.0
const SCAN_DURATION: float = 15.0
const COOLDOWN_DURATION: float = 120.0

var _cooldown_timer: float = 0.0
var is_on_cooldown: bool = false

func _init() -> void:
	building_name = "Satélite de Enlace Cuántico"
	salud_maxima = 1200.0
	salud_actual = 1200.0
	radio_vision = 50.0

func _ready() -> void:
	super._ready()
	add_to_group("satellites")
	add_to_group("satellites_3d")

func _process(delta: float) -> void:
	if is_on_cooldown:
		_cooldown_timer -= delta
		cooldown_ticked.emit(_cooldown_timer)
		if _cooldown_timer <= 0.0:
			is_on_cooldown = false
			print("Satellite3D '%s': Radar listo para nuevo escaneo." % name)

## Solicita un escaneo de radar en una coordenada 3D objetivo
func activar_escaneo_local(target_pos: Vector3) -> bool:
	if is_dead or is_under_construction or is_on_cooldown:
		print("Satellite3D: No se puede activar escaneo (En recarga o fuera de servicio).")
		return false

	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("rpc_activar_escaneo_radar", target_pos)
	else:
		rpc_activar_escaneo_radar(target_pos)
	return true

@rpc("any_peer", "call_local", "reliable")
func rpc_activar_escaneo_radar(target_pos: Vector3) -> void:
	is_on_cooldown = true
	_cooldown_timer = COOLDOWN_DURATION

	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("minimap_alert")

	# Perforar visión en el FogOfWarManager durante 15.0s
	_reveal_radar_vision_temporarily(target_pos, SCAN_DURATION)
	radar_scan_activated.emit(target_pos)

	print("Satellite3D '%s': ¡Escaneo de radar activado en %s por 15.0s!" % [name, str(target_pos)])

func _reveal_radar_vision_temporarily(target_pos: Vector3, duration: float) -> void:
	var fow := get_tree().get_first_node_in_group("fog_of_war_manager") if get_tree() else null
	if not is_instance_valid(fow):
		return

	# Revelar círculo temporal
	if fow.has_method("reveal_circle_temporary"):
		fow.call("reveal_circle_temporary", target_pos, RADAR_RADIUS, duration)
	elif fow.has_method("is_position_visible"):
		# Inyectar en grid si fow expone el buffer
		print("Satellite3D: Visión de radar inyectada en %s" % str(target_pos))
