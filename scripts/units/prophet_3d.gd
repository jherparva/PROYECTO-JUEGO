## Prophet3D — Unidad Especializada: El Profeta / Sacerdote 3D (GDScript 2.0 / Godot 4).
##
## Unidad mística y tecnológica capaz de convertir unidades enemigas al bando propio
## e invocar desastres climáticos (Terremotos DoT a edificios y Plagas DoT a infantería).

class_name Prophet3D
extends "res://scripts/units/unit_base_3d.gd"

signal conversion_started(target: Node3D)
signal conversion_completed(target: Node3D)
signal disaster_invoked(disaster_name: String, target_pos: Vector3)

# ─── Configuración de Conversión y Desastres ─────────────────────────────────
@export_group("Habilidades Místicas")
@export var unit_id: String = "prophet_standard"
@export var conversion_range: float = 14.0
@export var conversion_time: float = 4.0 # 4 segundos de rezo continuo
@export var conversion_faith_cost: float = 50.0
@export var disaster_faith_cost: float = 100.0

var conversion_target: Node3D = null
var conversion_timer: float = 0.0
var is_converting: bool = false

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _setup_stats() -> void:
	unit_name        = "Profeta Sagrado"
	salud_maxima     = 90.0
	salud_actual     = salud_maxima
	daño             = 0.0 # No tiene ataque físico directo
	rango_ataque     = conversion_range
	velocidad_ataque = 1.0
	speed            = 4.8
	radio_vision     = 30.0

	if unit_id == "prophet_stone" or unit_id == "profeta_piedra":
		unit_name = "Profeta de Piedra"
		era_entrenada = 1
		disaster_faith_cost = 40.0
		salud_maxima = 95.0
		salud_actual = 95.0

func _ready() -> void:
	super._ready()
	add_to_group("prophets")
	add_to_group("prophets_3d")
	add_to_group("vision_revealers")

func _process(delta: float) -> void:
	if is_dead:
		return

	# Bucle de canaleo de conversión
	if is_converting:
		_process_conversion_channeling(delta)

# ─── Mecánica de Conversión de Unidades ───────────────────────────────────────

## Inicia el rezo de conversión sobre una unidad enemiga.
func iniciar_conversion(target: Node3D) -> bool:
	if is_dead or not is_instance_valid(target) or is_converting:
		return false

	# Verificar que el objetivo sea enemigo y no esté muerto
	if target.has_method("is_dead") and target.call("is_dead"):
		return false

	# Verificar si tenemos un templo con suficiente Fe
	var temple := _find_friendly_temple()
	if is_instance_valid(temple) and temple.has_method("gastar_fe"):
		if not temple.call("gastar_fe", conversion_faith_cost):
			print("Prophet3D: Fe insuficiente para iniciar conversión.")
			return false

	conversion_target = target
	conversion_timer = 0.0
	is_converting = true

	# Rotar hacia el objetivo
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	conversion_started.emit(target)
	print("Prophet3D '%s': ¡Iniciando rezo de conversión sobre '%s'!" % [name, target.name])
	return true

func _process_conversion_channeling(delta: float) -> void:
	# Cancelar si el objetivo muere o escapa del rango extendido (+5m)
	if not is_instance_valid(conversion_target) or (conversion_target.has_method("is_dead") and conversion_target.call("is_dead")):
		_cancel_conversion("Objetivo muerto o destruido")
		return

	var dist := global_position.distance_to(conversion_target.global_position)
	if dist > (conversion_range + 5.0):
		_cancel_conversion("Objetivo fuera de alcance")
		return

	conversion_timer += delta

	# Efecto de partículas y sonido de rezo pasivo
	if Engine.get_process_frames() % 30 == 0:
		var sm = get_node_or_null("/root/SoundManager")
		if is_instance_valid(sm) and sm.has_method("play_attack_alert"):
			sm.play_attack_alert()

	# ¡Conversión Completada!
	if conversion_timer >= conversion_time:
		_execute_conversion_swap()

func _execute_conversion_swap() -> void:
	is_converting = false
	if not is_instance_valid(conversion_target):
		return

	print("Prophet3D: ¡CONVERSIÓN EXITOSA! '%s' ahora pertenece a nuestro bando." % conversion_target.name)

	# 1. Cambiar grupos de Godot
	if conversion_target.is_in_group("enemy_units"):
		conversion_target.remove_from_group("enemy_units")
		conversion_target.add_to_group("player_units")
	elif conversion_target.is_in_group("player_units"):
		conversion_target.remove_from_group("player_units")
		conversion_target.add_to_group("enemy_units")

	# 2. Cambiar propiedad bando
	if "bando" in conversion_target:
		conversion_target.set("bando", bando)

	# 3. Restablecer FSM de la unidad convertida a Idle
	if "state_machine" in conversion_target and is_instance_valid(conversion_target.state_machine):
		conversion_target.state_machine.change_state(&"Idle")

	conversion_completed.emit(conversion_target)
	conversion_target = null

func _cancel_conversion(reason: String) -> void:
	is_converting = false
	conversion_target = null
	conversion_timer = 0.0
	print("Prophet3D: Conversión cancelada — %s." % reason)

# ─── Invocación de Desastres Climáticos (Terremoto y Plaga) ────────────────────

## Invoca un Terremoto DoT que destruye edificios y murallas en el área objetivo.
func invocar_terremoto(target_pos: Vector3) -> bool:
	var temple := _find_friendly_temple()
	if is_instance_valid(temple) and temple.has_method("gastar_fe"):
		if not temple.call("gastar_fe", disaster_faith_cost):
			print("Prophet3D: Fe insuficiente para invocar Terremoto.")
			return false

	_crear_area_desastre(target_pos, "earthquake", 12.0, 6.0, 40.0, ["buildings", "walls_3d"])
	disaster_invoked.emit("Terremoto", target_pos)
	return true

## Habilidad Activa RPC del Profeta de Piedra (Era 1): Terremoto de área en 8 metros que drena 5 HP/s por 6 segundos
@rpc("any_peer", "call_local", "reliable")
func rpc_invocar_terremoto_piedra(target_pos: Vector3) -> bool:
	return invocar_terremoto_piedra(target_pos)

func invocar_terremoto_piedra(target_pos: Vector3) -> bool:
	var faith_cost := 40.0
	var faith_deducted := false
	var temple := _find_friendly_temple()
	if is_instance_valid(temple) and temple.has_method("gastar_fe"):
		faith_deducted = temple.call("gastar_fe", faith_cost)

	if not faith_deducted:
		if is_inside_tree() and get_tree():
			var cpm: Node = get_node_or_null("/root/CivPointsManager")
			if is_instance_valid(cpm) and cpm.has_method("gastar_fe"):
				faith_deducted = cpm.call("gastar_fe", faith_cost)

	if not faith_deducted and is_instance_valid(temple):
		print("Prophet3D: Fe insuficiente para invocar Terremoto de Piedra.")
		return false

	# Radio 8.0m, Duración 6.0s, Drena 5 HP/s contra estructuras
	_crear_area_desastre(target_pos, "earthquake_stone", 8.0, 6.0, 5.0, ["buildings", "walls", "walls_3d", "player_buildings", "enemy_buildings"])
	disaster_invoked.emit("Terremoto de Piedra", target_pos)
	return true

## Invoca una Plaga DoT que drena la vida de unidades orgánicas e infantería.
func invocar_plaga(target_pos: Vector3) -> bool:
	var temple := _find_friendly_temple()
	if is_instance_valid(temple) and temple.has_method("gastar_fe"):
		if not temple.call("gastar_fe", disaster_faith_cost * 0.9):
			print("Prophet3D: Fe insuficiente para invocar Plaga.")
			return false

	_crear_area_desastre(target_pos, "plague", 14.0, 8.0, 15.0, ["units", "units_3d"])
	disaster_invoked.emit("Plaga", target_pos)
	return true

func _crear_area_desastre(pos: Vector3, type_id: String, radius: float, duration: float, damage_per_sec: float, target_groups: Array) -> void:
	var area := Area3D.new()
	area.name = "DisasterArea_" + type_id
	area.position = pos

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	col.shape = sphere
	area.add_child(col)

	var parent: Node = null
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		parent = get_tree().current_scene.get_node_or_null("World")
		if not parent:
			parent = get_tree().current_scene
	elif get_parent():
		parent = get_parent()
	else:
		parent = self

	if is_instance_valid(parent) and parent != self:
		parent.add_child(area)
		if area.is_inside_tree():
			area.global_position = pos

	var current_tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)

	var process_damage = func():
		# 1. Chequeo por superposición de física
		var targets_hit: Array[Node] = []
		if area.is_inside_tree():
			for b in area.get_overlapping_bodies():
				if b not in targets_hit:
					targets_hit.append(b)

		# 2. Chequeo directo por distancia esférica (árbol de grupos + nodos hijos en escena)
		var candidates: Array[Node] = []
		if current_tree != null:
			for grp in target_groups:
				for node in current_tree.get_nodes_in_group(grp):
					if node not in candidates:
						candidates.append(node)

		if is_instance_valid(parent):
			for child in parent.get_children():
				if child not in candidates:
					candidates.append(child)

		for node in candidates:
			if is_instance_valid(node) and node is Node3D and node != self and node not in targets_hit:
				var n3d := node as Node3D
				var n_pos: Vector3 = n3d.global_position if n3d.is_inside_tree() else n3d.position
				if n_pos.distance_to(pos) <= radius:
					targets_hit.append(node)

		for t in targets_hit:
			if is_instance_valid(t) and t != self:
				# Bloqueo de daño a estructuras aliadas
				if "bando" in t and int(t.bando) == int(bando):
					continue
				if t.has_method("recibir_daño"):
					t.call("recibir_daño", damage_per_sec, self)

	# Aplicar el primer pulso de daño inmediatamente
	process_damage.call()

	# Configurar pulsos recurrentes y auto-limpieza
	if is_inside_tree() and get_tree():
		var timer := get_tree().create_timer(duration)
		var loops := maxi(1, int(duration) - 1)
		var tween := create_tween().set_loops(loops)
		tween.tween_callback(process_damage).set_delay(1.0)
		timer.timeout.connect(area.queue_free)

	print("Prophet3D: ¡Desastre '%s' (Radio: %.1fm, %.1f HP/s por %.1fs) invocado en %s!" % [
		type_id.capitalize(), radius, damage_per_sec, duration, str(pos)
	])

func _find_friendly_temple() -> Node:
	if not is_inside_tree() or not get_tree():
		return null
	var temples := get_tree().get_nodes_in_group("temples_3d")
	for t in temples:
		if is_instance_valid(t) and ("bando" in t and t.bando == bando):
			return t
	return null
