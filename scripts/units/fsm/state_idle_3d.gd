## StateIdle3D — Estado de Reposo y Guardia 3D (GDScript 2.0 / Godot 4).

class_name StateIdle3D
extends StateBase3D

var _facing_direction: Vector3 = Vector3.ZERO
var _aggro_timer: float = 0.0

func _init() -> void:
	state_name = &"Idle"

func enter(context: Dictionary = {}) -> void:
	_aggro_timer = 0.0
	if unit:
		unit.velocity = Vector3.ZERO
		unit.play_animation("idle")
		if context.has("facing_direction"):
			_facing_direction = context["facing_direction"]
		elif "desired_facing_direction" in unit:
			_facing_direction = unit.desired_facing_direction

func physics_update(delta: float) -> void:
	if unit and _facing_direction.length_squared() > 0.01:
		unit.rotate_towards_direction(_facing_direction, delta)
		var target_rad := atan2(_facing_direction.x, _facing_direction.z)
		if absf(angle_difference(unit.rotation.y, target_rad)) < 0.05:
			_facing_direction = Vector3.ZERO
			if "desired_facing_direction" in unit:
				unit.desired_facing_direction = Vector3.ZERO

	# Bloqueo Estricto de Pacificación Civil: Villager3D y FishingBoat3D NUNCA escanean enemigos
	var is_civilian: bool = (unit is Villager3D) or (unit.is_in_group("villagers")) or (unit.is_in_group("civilian_units"))
	var is_fishing_boat: bool = false
	if unit.get_class() == "FishingBoat3D" or unit.is_in_group("fishing_boats") or unit.is_in_group("ships_3d"):
		# No usamos 'unit is FishingBoat3D' directamente si no está pre-cargado globalmente para evitar parse errors
		if "fishing_state" in unit:
			is_fishing_boat = true

	if unit and not (is_civilian or is_fishing_boat):
		if (unit.is_in_group("soldiers") or unit.is_in_group("military_units") or "attack_range" in unit):
			_aggro_timer += delta
			if _aggro_timer >= 0.35:
				_aggro_timer = 0.0
				var enemy := _find_nearby_hostile(14.0)
				if is_instance_valid(enemy):
					if unit.has_method("set_status_text"):
						unit.set_status_text("⚔️ ¡Al combate!", 1.5)
					state_machine.change_state(&"Attacking", {"target": enemy})

func _find_nearby_hostile(max_range: float) -> Node3D:
	if not is_instance_valid(unit):
		return null
	var my_bando: int = int(unit.bando)
	var best_target: Node3D = null
	var min_dist: float = max_range

	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("units_3d"))
	candidates.append_array(get_tree().get_nodes_in_group("buildings_3d"))

	for c in candidates:
		if is_instance_valid(c) and c is Node3D and c != unit:
			if "is_dead" in c and c.is_dead:
				continue
			if "salud_actual" in c and c.salud_actual <= 0.0:
				continue
			var bando_val: int = int(c.bando) if "bando" in c else -1
			if bando_val != -1 and bando_val != my_bando:
				var dist: float = unit.global_position.distance_to((c as Node3D).global_position)
				if dist < min_dist:
					min_dist = dist
					best_target = c as Node3D

	return best_target

