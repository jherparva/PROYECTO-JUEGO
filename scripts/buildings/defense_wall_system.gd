## DefenseWallSystem — Sistema de Muros y Fortificaciones Dinámicas (GDScript 2.0 / Godot 4).
##
## Gestiona la colocación trazada de murallas 3D y la conexión dinámica (auto-tiling)
## entre segmentos contiguos (Recto, Esquina en L, Intersección en T, Cruz y Terminal).

class_name DefenseWallSystem
extends Node3D

const GRID_SIZE: float = 4.0

# ─── Clase de Segmento de Muro Individal ─────────────────────────────────────
class WallSegment3D extends "res://scripts/buildings/building_base_3d.gd":
	var wall_type: String = "straight" # "straight", "corner_l", "inter_t", "cross", "end"
	var neighbors: Dictionary = {"N": false, "S": false, "E": false, "W": false}

	func _init() -> void:
		building_name = "Muro Defensivo"
		salud_maxima = 800.0
		salud_actual = 800.0

	func _ready() -> void:
		super._ready()
		add_to_group("walls")
		add_to_group("walls_3d")
		add_to_group("player_buildings" if bando == Bando.PLAYER else "enemy_buildings")

		# Escuchar la señal global de eras
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
			if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
				rm.era_evolucionada.connect(_on_era_evolucionada)

		# Auto-conectar vecinos al ser colocado
		call_deferred("actualizar_conexiones")

	## Detecta muros contiguos en las 4 direcciones cardinales (N, S, E, W)
	func actualizar_conexiones() -> void:
		neighbors = {"N": false, "S": false, "E": false, "W": false}
		var space_state := get_world_3d().direct_space_state
		if space_state == null:
			return

		var directions := {
			"N": Vector3(0.0, 0.0, -GRID_SIZE),
			"S": Vector3(0.0, 0.0, GRID_SIZE),
			"E": Vector3(GRID_SIZE, 0.0, 0.0),
			"W": Vector3(-GRID_SIZE, 0.0, 0.0)
		}

		for dir_key in directions:
			var target_pos := global_position + directions[dir_key]
			for w in get_tree().get_nodes_in_group("walls_3d"):
				if is_instance_valid(w) and w != self and (w as Node3D).global_position.distance_to(target_pos) < 1.2:
					neighbors[dir_key] = true
					break

		_determinar_malla_auto_tiling()

	## Selecciona el tipo de malla visual según la disposición de vecinos
	func _determinar_malla_auto_tiling() -> void:
		var count := 0
		for k in neighbors:
			if neighbors[k]:
				count += 1

		match count:
			0, 1:
				wall_type = "end"
			2:
				if (neighbors["N"] and neighbors["S"]) or (neighbors["E"] and neighbors["W"]):
					wall_type = "straight"
				else:
					wall_type = "corner_l"
			3:
				wall_type = "inter_t"
			4:
				wall_type = "cross"

		_actualizar_visibilidad_malla()

	func _actualizar_visibilidad_malla() -> void:
		for child in get_children():
			if child is MeshInstance3D and child.name.begins_with("Mesh_"):
				child.visible = false

		var mesh_node := get_node_or_null("Mesh_" + wall_type)
		if is_instance_valid(mesh_node):
			mesh_node.visible = true

	func _on_era_evolucionada(player_id: Variant = 1, nueva_era: Variant = null, _extra: Variant = null) -> void:
		if is_dead:
			return
		var p_id: int = int(player_id) if (player_id is int or player_id is float) else 1
		var era_val: int = int(nueva_era) if (nueva_era != null and (nueva_era is int or nueva_era is float)) else (int(player_id) if (player_id is int or player_id is float) else 0)
		if self.owner_peer_id != p_id:
			return

		# Escalar HP según la Era
		var prev_ratio := salud_actual / salud_maxima if salud_maxima > 0.0 else 1.0
		salud_maxima = 800.0 * (1.0 + era_val * 0.45)
		salud_actual = salud_maxima * prev_ratio
		super._on_era_evolucionada(p_id, era_val)

# ─── API del Sistema Global de Muros ──────────────────────────────────────────

## Traza una línea de murallas entre dos coordenadas 3D.
func trazar_linea_muros(start_pos: Vector3, end_pos: Vector3, bando: int = 0) -> Array[WallSegment3D]:
	var created_segments: Array[WallSegment3D] = []
	var dir := (end_pos - start_pos)
	var distance := dir.length()
	if distance < 1.0:
		return created_segments

	var steps := int(round(distance / GRID_SIZE))
	var step_vector := dir.normalized() * GRID_SIZE

	for i in range(steps + 1):
		var pos := start_pos + step_vector * float(i)
		pos.x = snapf(pos.x, GRID_SIZE)
		pos.z = snapf(pos.z, GRID_SIZE)
		pos.y = start_pos.y

		var seg := WallSegment3D.new()
		seg.global_position = pos
		seg.set("bando", bando)
		add_child(seg)
		created_segments.append(seg)

	# Recalcular auto-tiling para todos los segmentos trazados y sus colindantes
	get_tree().call_group("walls_3d", "actualizar_conexiones")
	return created_segments
