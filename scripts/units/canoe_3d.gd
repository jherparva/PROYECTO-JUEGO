## Canoe3D / CanoaMaderaEra0 — Transporte Náutico de la Era Prehistórica (GDScript 2.0 / Godot 4).
##
## Balsa de troncos y canoa náutica primitiva diseñada para la Era 0 (Prehistoria):
## - Navega a través de aguas profundas a nivel de flotación de Y = -1.8m.
## - Sistema de guarecido náutico ('garrison_array') con capacidad de hasta 4 unidades
##   del grupo 'infantry_3d'.
## - Oculta las mallas y desactiva colisiones de las unidades transportadas.
## - Función RPC 'rpc_descargar_todo()' que desembarca síncronamente a todas las unidades
##   alrededor de la canoa con desplazamientos (offsets) aleatorios seguros.

class_name Canoe3D
extends "res://scripts/units/unit_base_3d.gd"

signal garrison_updated(current_count: int, max_count: int)
signal units_unloaded(unloaded_units: Array[Node3D])

const MAX_GARRISON: int = 4
const WATER_LEVEL_Y: float = -1.8

var garrison_array: Array[Node3D] = []

func _init() -> void:
	unit_name = "Canoa de Madera Primitiva"
	salud_maxima = 350.0
	salud_actual = 350.0
	speed = 6.0
	era_entrenada = 0
	es_militar = false
	position.y = WATER_LEVEL_Y

func _ready() -> void:
	super._ready()
	add_to_group("ships")
	add_to_group("ships_3d")
	add_to_group("transports")
	add_to_group("naval_transports")

	# Fijar cota de flotación en agua profunda
	if is_inside_tree() and position.y != WATER_LEVEL_Y:
		global_position.y = WATER_LEVEL_Y

func _process(_delta: float) -> void:
	if is_dead:
		return
	# Mantener plano náutico Y = -1.8m
	if global_position.y != WATER_LEVEL_Y:
		global_position.y = WATER_LEVEL_Y

## Guarece a un infante dentro de la canoa
func guarecer_unidad(unit_node: Node3D) -> bool:
	if is_dead or not is_instance_valid(unit_node):
		return false

	if garrison_array.size() >= MAX_GARRISON:
		print("Canoe3D '%s': Capacidad máxima de transporte alcanzada (%d/%d)." % [name, garrison_array.size(), MAX_GARRISON])
		return false

	# Solo unidades de infantería admitidas
	if not unit_node.is_in_group("infantry_3d") and not unit_node.is_in_group("villagers") and not unit_node.is_in_group("unidades"):
		print("Canoe3D '%s': La unidad %s no es infantería transportable." % [name, unit_node.name])
		return false

	if garrison_array.has(unit_node):
		return false

	garrison_array.append(unit_node)

	# Ocultar malla y deshabilitar colisión/procesamiento
	unit_node.visible = false
	if unit_node is CollisionObject3D:
		(unit_node as CollisionObject3D).set_collision_layer_value(1, false)
		(unit_node as CollisionObject3D).set_collision_mask_value(1, false)
	unit_node.process_mode = Node.PROCESS_MODE_DISABLED

	garrison_updated.emit(garrison_array.size(), MAX_GARRISON)
	print("Canoe3D '%s': Infante '%s' guarecido a bordo (%d/%d)." % [
		name, unit_node.name, garrison_array.size(), MAX_GARRISON
	])
	return true

## Desembarco síncrono en red de todas las tropas a bordo con offsets radiales
@rpc("any_peer", "call_local", "reliable")
func rpc_descargar_todo() -> void:
	if garrison_array.is_empty():
		return

	var unloaded: Array[Node3D] = []
	var center_pos := global_position if is_inside_tree() else position

	for unit_node in garrison_array:
		if is_instance_valid(unit_node):
			# Offset radial seguro alrededor de la canoa
			var angle := randf() * TAU
			var dist := randf_range(2.5, 4.5)
			var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
			var unload_pos := center_pos + offset
			unload_pos.y = maxf(0.0, unload_pos.y) # Asignar a tierra firme

			if unit_node.is_inside_tree():
				unit_node.global_position = unload_pos
			else:
				unit_node.position = unload_pos
			unit_node.visible = true
			unit_node.process_mode = Node.PROCESS_MODE_INHERIT

			if unit_node is CollisionObject3D:
				(unit_node as CollisionObject3D).set_collision_layer_value(1, true)
				(unit_node as CollisionObject3D).set_collision_mask_value(1, true)

			if unit_node.has_method("set_status_text"):
				unit_node.call("set_status_text", "⚓ ¡Desembarco completado!", 2.0)

			unloaded.append(unit_node)

	garrison_array.clear()
	garrison_updated.emit(0, MAX_GARRISON)
	units_unloaded.emit(unloaded)
	print("Canoe3D '%s': ¡%d infantes desembarcados con éxito!" % [name, unloaded.size()])

## Alias local para descargar tropas
func descargar_todo() -> void:
	rpc_descargar_todo()

func morir() -> void:
	# Si la canoa es hundida, las unidades a bordo mueren o son destruidas
	for unit_node in garrison_array:
		if is_instance_valid(unit_node):
			if unit_node.has_method("morir"):
				unit_node.call("morir")
			else:
				unit_node.queue_free()
	garrison_array.clear()
	super.morir()
