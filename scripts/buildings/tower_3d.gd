## Tower3D — Torre de Vigilancia y Defensa 3D (GDScript 2.0 / Godot 4).
##
## Edificio de defensa defensiva a distancia. Registra un campo de visión extendido (35.0m)
## en el FogOfWarManager y dispara automáticamente a los enemigos dentro del rango visible.

class_name Tower3D
extends "res://scripts/buildings/building_base_3d.gd"

signal enemy_targeted(target: Node3D)

# ─── Configuración de Defensa ─────────────────────────────────────────────────
@export_group("Parámetros Defensivos")
@export var base_damage: float = 25.0
@export var attack_range: float = 22.0 # Era 0: 22.0m para Torre Trípode Prehistórica
@export var attack_cooldown: float = 1.0 # 1 disparo cada 1.0s
@export var max_garrison_capacity: int = 5

var garrisoned_units: Array[Node3D] = []
var _attack_timer: float = 0.0
var current_target: Node3D = null

## Retorna la coordenada global del socket ProjectileMuzzle de la plataforma superior
func get_muzzle_position() -> Vector3:
	var base_pos := global_position if is_inside_tree() else position
	var muzzle: Node3D = find_child("ProjectileMuzzle", true, false) as Node3D
	if is_instance_valid(muzzle):
		if muzzle.is_inside_tree():
			return muzzle.global_position
		return base_pos + muzzle.position
	return base_pos + Vector3(0.0, 3.5, 0.0)

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Torre de Vigilancia Trípode"
	salud_maxima = 950.0
	salud_actual = 950.0
	radio_vision = 30.0 # Rango extendido para revelar Niebla de Guerra

func _ready() -> void:
	super._ready()
	add_to_group("towers")
	add_to_group("towers_3d")
	add_to_group("vision_revealers")

	# En Era 0, el alcance base oficial es 22.0m
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		if int(rm.era_actual) == 0:
			attack_range = 22.0
		else:
			attack_range = 32.0

	# Bonificación por Ventaja de Altura (+30% Visión y Rango)
	var terrain_mgr = load("res://scripts/core/terrain_modifier_manager.gd")
	if is_instance_valid(terrain_mgr) and terrain_mgr.has_method("tiene_ventaja_altura"):
		if terrain_mgr.call("tiene_ventaja_altura", self):
			radio_vision *= 1.30
			attack_range *= 1.30
			print("Tower3D '%s': ¡Bonificación de Colina Activa! Visión: %.1fm | Rango: %.1fm" % [
				name, radio_vision, attack_range
			])

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _process(delta: float) -> void:
	if is_dead or is_under_construction:
		return

	_attack_timer += delta
	if _attack_timer >= attack_cooldown:
		_attack_timer = 0.0
		_execute_defensive_attack()

# ─── Ataque Defensivo y Filtro de Niebla de Guerra ────────────────────────────

func _execute_defensive_attack() -> void:
	# 1. Buscar el enemigo más cercano en rango que se encuentre VISIBLE en el FogOfWarManager
	var target_group: String = "enemy_units" if bando == Bando.PLAYER else "player_units"
	var fog_mgr := get_tree().get_first_node_in_group("fog_of_war_manager") if get_tree() else null

	var nearest_enemy: Node3D = null
	var min_dist: float = attack_range

	for u in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(u) or (u.has_method("is_dead") and u.call("is_dead")):
			continue

		var u_node := u as Node3D
		var dist := global_position.distance_to(u_node.global_position)

		if dist <= min_dist:
			# Si jugamos con Niebla de Guerra, verificar que la casilla esté iluminada
			var is_visible: bool = true
			if is_instance_valid(fog_mgr) and fog_mgr.has_method("is_position_visible"):
				is_visible = fog_mgr.call("is_position_visible", u_node.global_position)

			if is_visible:
				min_dist = dist
				nearest_enemy = u_node

	# 2. Ejecutar el disparo si hay objetivo válido
	current_target = nearest_enemy
	if is_instance_valid(current_target):
		var extra_dmg := float(garrisoned_units.size()) * 5.0
		# Matriz de daño por altura de dbcliffterrain.dat
		var mult := CombatDamageCalculator.calcular_modificador_altura(self, current_target)
		var total_damage := (base_damage + extra_dmg) * mult

		# 1. Búsqueda obligatoria del socket 'ProjectileMuzzle' ANTES de instanciar Projectile3D
		var spawn_pos := get_muzzle_position()

		# 2. Proyectil de roca pesada para Era 0
		var proj := Projectile3D.new()
		proj.projectile_type = "stone" # Roca pesada arrojadiza primitiva
		proj.damage = total_damage
		proj.bando = bando
		proj.source_unit = self
		proj.target_node = current_target
		proj.target_position = current_target.global_position + Vector3(0.0, 1.0, 0.0)

		var parent: Node = get_tree().current_scene.get_node_or_null("World/Projectiles") if get_tree() and get_tree().current_scene else get_parent()
		if is_instance_valid(parent):
			parent.add_child(proj)
			proj.global_position = spawn_pos

		var sm = get_node_or_null("/root/SoundManager")
		if is_instance_valid(sm) and sm.has_method("play_attack_alert"):
			sm.play_attack_alert()

		enemy_targeted.emit(current_target)

# ─── Guarnición de la Torre ───────────────────────────────────────────────────

func add_garrison_unit(unit: Node3D) -> bool:
	if garrisoned_units.size() >= max_garrison_capacity:
		return false
	if not garrisoned_units.has(unit):
		garrisoned_units.append(unit)
		return true
	return false

func remove_garrison_unit(unit: Node3D) -> void:
	garrisoned_units.erase(unit)

# ─── Evolución Estética por Era (Eras 0 a 9) ───────────────────────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return

	var rm: Node = get_node_or_null("/root/ResourceManager")
	var mult_atk: float = 1.0
	if is_instance_valid(rm) and "MULTIPLICADORES_ERA" in rm:
		var mults: Dictionary = rm.get("MULTIPLICADORES_ERA").get(era_val, {})
		mult_atk = float(mults.get("attack", 1.0))
	base_damage = 25.0 * mult_atk

	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1:
			_activar_mesh_por_nombre("EraMesh_WatchtowerPrimitive")
			building_name = "Torre de Vigilancia de Madera"
		2, 3:
			_activar_mesh_por_nombre("EraMesh_StoneTower")
			building_name = "Torreón de Piedra"
		4, 5:
			_activar_mesh_por_nombre("EraMesh_BallistaTower")
			building_name = "Torre de Balista y Cañón"
		6, 7:
			_activar_mesh_por_nombre("EraMesh_RadarBunkerTower")
			building_name = "Torre Radar con Torreta Neumática"
		8, 9:
			_activar_mesh_por_nombre("EraMesh_LaserDefenseTower")
			building_name = "Torre de Defensa Láser Modular"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
