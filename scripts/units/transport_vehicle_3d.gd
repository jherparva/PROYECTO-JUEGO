## TransportVehicle3D — Vehículo de Transporte Terrestre 3D (GDScript 2.0 / Godot 4).
##
## Transportador de infantería con capacidad escalable según la era histórica:
## - "carro_primitivo" (Era 2): Capacidad 4 unidades, 5.5 m/s.
## - "camion_industrial" (Era 6): Capacidad 8 unidades, 7.5 m/s.
## - "apc_blindado" (Era 7): Capacidad 10 unidades, 8.0 m/s (Grupo "vehicles_3d").
## - "transporte_nano" (Era 9): Capacidad 12 unidades, 9.0 m/s (Grupo "cyber_robotic").

class_name TransportVehicle3D
extends "res://scripts/units/unit_base_3d.gd"

signal units_loaded_changed(count: int, max_cap: int)

@export var capacidad_maxima: int = 6

var unidades_cargadas: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	add_to_group("transports")
	add_to_group("transports_3d")
	_configure_vehicle_stats()

func _configure_vehicle_stats() -> void:
	match unit_id:
		"carro_primitivo":
			capacidad_maxima = 4
			speed = 5.5
			salud_maxima = 350.0
			salud_actual = 350.0
		"camion_industrial":
			capacidad_maxima = 8
			speed = 7.5
			salud_maxima = 600.0
			salud_actual = 600.0
		"apc_blindado":
			capacidad_maxima = 10
			speed = 8.0
			salud_maxima = 950.0
			salud_actual = 950.0
			add_to_group("vehicles_3d")
		"transporte_nano":
			capacidad_maxima = 12
			speed = 9.0
			salud_maxima = 1400.0
			salud_actual = 1400.0
			add_to_group("cyber_robotic")
		_:
			capacidad_maxima = 6
			speed = 6.0

## Carga un soldado en el transporte vía RPC
func cargar_soldado_local(soldier: Node3D) -> bool:
	if is_dead or unidades_cargadas.size() >= capacidad_maxima or not is_instance_valid(soldier):
		return false

	var soldier_path := soldier.get_path()
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("rpc_cargar_soldado", soldier_path)
	else:
		rpc_cargar_soldado(soldier_path)
	return true

@rpc("any_peer", "call_local", "reliable")
func rpc_cargar_soldado(soldier_path: NodePath) -> void:
	var soldier := get_node_or_null(soldier_path) as Node3D
	if not is_instance_valid(soldier) or unidades_cargadas.has(soldier):
		return

	unidades_cargadas.append(soldier)

	# Ocultar visualmente y congelar procesamiento/colisiones
	soldier.visible = false
	soldier.process_mode = PROCESS_MODE_DISABLED

	var col: CollisionShape3D = soldier.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if is_instance_valid(col):
		col.disabled = true

	print("TransportVehicle3D '%s': Soldado %s guarecido (%d/%d)." % [
		name, soldier.name, unidades_cargadas.size(), capacidad_maxima
	])
	units_loaded_changed.emit(unidades_cargadas.size(), capacidad_maxima)

## Descarga todas las unidades en la posición global actual
func descargar_todo_local() -> void:
	if unidades_cargadas.is_empty():
		return

	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("rpc_descargar_todo")
	else:
		rpc_descargar_todo()

@rpc("any_peer", "call_local", "reliable")
func rpc_descargar_todo() -> void:
	var count := unidades_cargadas.size()
	for i in range(count - 1, -1, -1):
		var u := unidades_cargadas[i]
		if is_instance_valid(u):
			# Posicionar alrededor del vehículo
			var offset := Vector3(randf_range(-2.5, 2.5), 0.0, randf_range(-2.5, 2.5))
			u.global_position = global_position + offset

			u.visible = true
			u.process_mode = PROCESS_MODE_INHERIT

			var col: CollisionShape3D = u.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if is_instance_valid(col):
				col.disabled = false

		unidades_cargadas.remove_at(i)

	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.jugar_sfx_interfaz("minimap_alert")

	print("TransportVehicle3D '%s': ¡Se han desembarcado %d soldados!" % [name, count])
	units_loaded_changed.emit(0, capacidad_maxima)

func morir() -> void:
	# Si el transporte es destruido, expulsar a todos los soldados supervivientes
	descargar_todo_local()
	super.morir()
