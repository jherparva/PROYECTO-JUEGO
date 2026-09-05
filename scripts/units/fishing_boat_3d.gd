## FishingBoat3D — Barco Pesquero Inteligente 3D (GDScript 2.0 / Godot 4).
##
## Navega por agua profunda (Y = -1.8m) recolectando alimento de cardúmenes de peces:
## - Tasa base de extracción: 1.5 comida/s.
## - Carga máxima: 20 unidades de alimento.
## - Retorno automático al Dock3D más cercano al llenar la bodega y reanudación de pesca.
## - Evolución visual de mallas 3D según la era (0 a 9).

class_name FishingBoat3D
extends "res://scripts/units/unit_base_3d.gd"

signal cargo_changed(current: int, maximum: int)

const MAX_CARGA: int = 20
const GATHER_RATE: float = 1.5 # Comida por segundo

var current_cargo: int = 0
var target_fish_node: Node3D = null
var target_dock_node: Node3D = null

enum FishingState { IDLE, MOVING_TO_FISH, FISHING, MOVING_TO_DOCK, DEPOSITING }
var fishing_state: FishingState = FishingState.IDLE

var _gather_accumulator: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group("ships_3d")
	add_to_group("fishing_boats")
	speed = 5.0
	salud_maxima = 400.0
	salud_actual = 400.0

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		rm.era_evolucionada.connect(_on_era_evolucionada)
		_aplicar_evolucion_naval(int(rm.get("era_actual")))

func _process(delta: float) -> void:
	if is_dead:
		return

	match fishing_state:
		FishingState.MOVING_TO_FISH:
			if is_instance_valid(target_fish_node):
				var dist := global_position.distance_to(target_fish_node.global_position)
				if dist <= 3.5:
					fishing_state = FishingState.FISHING
					print("FishingBoat3D '%s': Arribó al cardumen. Iniciando extracción." % name)
				else:
					global_position = global_position.move_toward(target_fish_node.global_position, speed * delta)
			else:
				fishing_state = FishingState.IDLE

		FishingState.FISHING:
			if not is_instance_valid(target_fish_node):
				fishing_state = FishingState.IDLE
				return

			_gather_accumulator += GATHER_RATE * delta
			if _gather_accumulator >= 1.0:
				var amount := int(_gather_accumulator)
				_gather_accumulator -= float(amount)
				current_cargo = min(current_cargo + amount, MAX_CARGA)
				cargo_changed.emit(current_cargo, MAX_CARGA)

				if current_cargo >= MAX_CARGA:
					print("FishingBoat3D '%s': Bodega llena (%d/%d). Navegando hacia el Muelle." % [
						name, current_cargo, MAX_CARGA
					])
					_iniciar_retorno_a_muelle()

		FishingState.MOVING_TO_DOCK:
			if is_instance_valid(target_dock_node):
				var dist := global_position.distance_to(target_dock_node.global_position)
				if dist <= 4.0:
					_depositar_comida_y_regresar()
				else:
					global_position = global_position.move_toward(target_dock_node.global_position, speed * delta)
			else:
				fishing_state = FishingState.IDLE

## Ordena al barco pescar en un nodo de recurso acuático
func command_gather(fish_node: Node3D) -> void:
	if is_dead or not is_instance_valid(fish_node):
		return

	target_fish_node = fish_node
	fishing_state = FishingState.MOVING_TO_FISH
	print("FishingBoat3D '%s': Zarpando hacia cardumen de peces %s." % [name, fish_node.name])

func _iniciar_retorno_a_muelle() -> void:
	# Buscar Dock3D más cercano
	var nearest_dock: Node3D = null
	var min_dist := 99999.0
	var my_group := "player_buildings" if bando == Bando.PLAYER else "enemy_buildings"

	for bld in get_tree().get_nodes_in_group("docks") + get_tree().get_nodes_in_group("docks_3d") + get_tree().get_nodes_in_group(my_group):
		if is_instance_valid(bld) and bld is Node3D and bld.name.begins_with("Dock"):
			var dist := global_position.distance_to((bld as Node3D).global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_dock = bld as Node3D

	if is_instance_valid(nearest_dock):
		target_dock_node = nearest_dock
		fishing_state = FishingState.MOVING_TO_DOCK
	else:
		print("FishingBoat3D '%s': ¡No se encontró Muelle (Dock3D) activo! En espera." % name)
		fishing_state = FishingState.IDLE

func _depositar_comida_y_regresar() -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_method("agregar_recurso"):
			rm.call("agregar_recurso", "food", current_cargo)
		elif "resources" in rm and rm.resources is Dictionary:
			var cur: int = int(rm.resources.get("food", 0))
			rm.resources["food"] = cur + current_cargo

	print("FishingBoat3D '%s': ¡Entregados %d de Comida en Muelle! Retornando al cardumen." % [name, current_cargo])
	current_cargo = 0
	cargo_changed.emit(0, MAX_CARGA)

	if is_instance_valid(target_fish_node):
		fishing_state = FishingState.MOVING_TO_FISH
	else:
		fishing_state = FishingState.IDLE

# ─── Evolución Visual Naval por Eras ───────────────────────────────────────────

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var era_val: int = 0
	var p_id: int = 1
	if nueva_era != null and nueva_era is int:
		p_id = int(player_id_or_era)
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)

	if "owner_peer_id" in self and int(get("owner_peer_id")) != p_id:
		return

	_aplicar_evolucion_naval(era_val)

func _aplicar_evolucion_naval(era: int) -> void:
	match era:
		0, 1, 2: # Eras Primitivas: Balsas de caña y botes de madera
			speed = 5.0
		3, 4, 5: # Eras Históricas: Veleros pesqueros
			speed = 6.5
		6, 7:    # Eras Industriales: Pesqueros a vapor con redes mecánicas
			speed = 8.0
		8, 9:    # Eras Futuristas: Hidrodeslizadores cuánticos con rayos tractores
			speed = 10.0
