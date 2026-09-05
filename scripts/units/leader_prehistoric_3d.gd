## LeaderPrehistoric3D — Héroe Chamán Tribal de la Era Prehistórica (GDScript 2.0 / Godot 4).
##
## Héroe y líder militar de la Era 0 (Prehistoria) inspirado en Empire Earth:
## - Dispone de un componente local Area3D con radio de 12.0 metros.
## - Al entonar su cántico ritual ('activar_cantico_ritual()'), otorga un bufo pasivo
##   de +15% de daño de ataque y +10% de velocidad a todas las unidades aliadas cercanas
##   sin generar spam o lag RPC redundante en la red.

class_name LeaderPrehistoric3D
extends "res://scripts/units/soldier_3d.gd"

signal ritual_chant_activated()

@export var aura_radius: float = 12.0
@export var damage_buff_percent: float = 0.15 # +15% de daño
@export var speed_buff_percent: float = 0.10  # +10% de velocidad

var aura_area: Area3D = null
var affected_allies: Array[Node3D] = []
var is_ritual_active: bool = true

func _setup_stats() -> void:
	unit_name        = "Chamán Tribal Prehistórico"
	unit_id          = "leader_prehistoric"
	_salud_base      = 350.0
	_daño_base       = 22.0
	salud_maxima     = _salud_base
	salud_actual     = salud_maxima
	daño             = _daño_base
	weapon_type      = "club"
	rango_ataque     = 3.2
	velocidad_ataque = 0.8
	speed            = 5.4
	radio_vision     = 32.0
	_guard_position  = global_position

func _ready() -> void:
	unit_id = "leader_prehistoric"
	super._ready()
	add_to_group("heroes")
	add_to_group("heroes_3d")
	add_to_group("leaders")
	_setup_aura_component()

func _setup_aura_component() -> void:
	aura_area = get_node_or_null("RitualAuraArea3D") as Area3D
	if not is_instance_valid(aura_area):
		aura_area = Area3D.new()
		aura_area.name = "RitualAuraArea3D"
		aura_area.collision_layer = 0
		aura_area.collision_mask = 1 # Capa de colisión estándar para unidades
		aura_area.monitorable = false
		aura_area.monitoring = true

		var col_shape := CollisionShape3D.new()
		col_shape.name = "AuraSphereShape"
		var sphere := SphereShape3D.new()
		sphere.radius = aura_radius
		col_shape.shape = sphere
		aura_area.add_child(col_shape)
		add_child(aura_area)

	if not aura_area.body_entered.is_connected(_on_aura_body_entered):
		aura_area.body_entered.connect(_on_aura_body_entered)
	if not aura_area.body_exited.is_connected(_on_aura_body_exited):
		aura_area.body_exited.connect(_on_aura_body_exited)

func _process(delta: float) -> void:
	super._process(delta)
	if is_dead:
		_cleanup_all_buffs()
		return
	if is_ritual_active:
		_maintain_aura_buffs()

## Activa la habilidad especial del cántico ritual del Chamán Tribal
@rpc("any_peer", "call_local", "reliable")
func activar_cantico_ritual() -> void:
	if is_dead:
		return
	is_ritual_active = true
	ritual_chant_activated.emit()
	_apply_buff_to_all_nearby_allies()
	print("LeaderPrehistoric3D '%s': ¡Cántico Ritual activado! Bufo zonal +15%% Daño / +10%% Vel." % name)

func _get_safe_tree() -> SceneTree:
	if is_inside_tree() and get_tree():
		return get_tree()
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop as SceneTree
	return null

func _get_pos(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	return node.position

func _get_allies_list() -> Array:
	var my_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
	var tree := _get_safe_tree()
	var list: Array = []
	if is_instance_valid(tree):
		list = tree.get_nodes_in_group(my_group)
	if list.is_empty() and get_parent():
		for child in get_parent().get_children():
			if child is Node3D and child.is_in_group(my_group):
				list.append(child)
	return list

func _apply_buff_to_all_nearby_allies() -> void:
	var my_pos := _get_pos(self)
	for ally in _get_allies_list():
		if is_instance_valid(ally) and ally != self and ally is Node3D:
			var ally_node := ally as Node3D
			var dist := my_pos.distance_to(_get_pos(ally_node))
			if dist <= aura_radius:
				_apply_buff_to_unit(ally_node)

func _maintain_aura_buffs() -> void:
	# Mantiene y refresca bufos para aliados dentro del radio de 12.0m
	var my_pos := _get_pos(self)
	for ally in _get_allies_list():
		if is_instance_valid(ally) and ally != self and ally is Node3D:
			var ally_node := ally as Node3D
			var dist := my_pos.distance_to(_get_pos(ally_node))
			if dist <= aura_radius:
				if not affected_allies.has(ally_node):
					_apply_buff_to_unit(ally_node)
			else:
				if affected_allies.has(ally_node):
					_remove_buff_from_unit(ally_node)

func _on_aura_body_entered(body: Node3D) -> void:
	if not is_ritual_active or is_dead or body == self:
		return
	var my_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
	if body.is_in_group(my_group):
		_apply_buff_to_unit(body)

func _on_aura_body_exited(body: Node3D) -> void:
	if body == self:
		return
	if affected_allies.has(body):
		_remove_buff_from_unit(body)

func _apply_buff_to_unit(unit_node: Node3D) -> void:
	if affected_allies.has(unit_node) or not is_instance_valid(unit_node):
		return
	affected_allies.append(unit_node)

	# Bufo de Daño (+15%)
	if "damage_modifier" in unit_node:
		var cur_dmg_mod: float = float(unit_node.get("damage_modifier"))
		unit_node.set("damage_modifier", cur_dmg_mod * (1.0 + damage_buff_percent))

	# Bufo de Velocidad (+10%)
	if "speed_modifier" in unit_node:
		var cur_spd_mod: float = float(unit_node.get("speed_modifier"))
		unit_node.set("speed_modifier", cur_spd_mod * (1.0 + speed_buff_percent))
	elif "speed" in unit_node:
		var cur_spd: float = float(unit_node.get("speed"))
		unit_node.set_meta("original_speed", cur_spd)
		unit_node.set("speed", cur_spd * (1.0 + speed_buff_percent))

	if unit_node.has_method("set_status_text"):
		unit_node.call("set_status_text", "✨ ¡Cántico Chamánico (+15% Atk)!", 1.5)

func _remove_buff_from_unit(unit_node: Node3D) -> void:
	affected_allies.erase(unit_node)
	if not is_instance_valid(unit_node):
		return

	# Revertir daño
	if "damage_modifier" in unit_node:
		var cur_dmg_mod: float = float(unit_node.get("damage_modifier"))
		unit_node.set("damage_modifier", maxf(1.0, cur_dmg_mod / (1.0 + damage_buff_percent)))

	# Revertir velocidad
	if "speed_modifier" in unit_node:
		var cur_spd_mod: float = float(unit_node.get("speed_modifier"))
		unit_node.set("speed_modifier", maxf(1.0, cur_spd_mod / (1.0 + speed_buff_percent)))
	elif unit_node.has_meta("original_speed"):
		var orig: float = float(unit_node.get_meta("original_speed"))
		unit_node.set("speed", orig)
		unit_node.remove_meta("original_speed")

func _cleanup_all_buffs() -> void:
	for ally in affected_allies.duplicate():
		if is_instance_valid(ally):
			_remove_buff_from_unit(ally)
	affected_allies.clear()

func morir() -> void:
	_cleanup_all_buffs()
	super.morir()
