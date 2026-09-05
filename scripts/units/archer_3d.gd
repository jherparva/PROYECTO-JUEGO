## Archer3D — Unidad Especializada de Rango / Arquero / Fondero 3D (GDScript 2.0 / Godot 4).
##
## Extiende UnitBase3D para unidades de combate a distancia. En lugar de aplicar daño instantáneo,
## instancía físicamente proyectiles 3D (Projectile3D) que viajan hacia el objetivo.

class_name Archer3D
extends "res://scripts/units/unit_base_3d.gd"

# ─── Configuración de Unidad de Rango ──────────────────────────────────────────
@export_group("Equipamiento de Rango")
@export var unit_id: String = "arquero"
@export var projectile_type: String = "arrow" # "stone", "arrow", "bullet", "plasma"
@export var weapon_type: String = "bow" # "sling", "bow", "rifle", "laser_rifle"

var _daño_base: float = 16.0
var _rango_base: float = 22.0
var _attack_cooldown_timer: float = 0.0
var target_enemy: Node3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _setup_stats() -> void:
	unit_name        = "Arquero de Rango"
	_daño_base       = 16.0
	_rango_base      = 22.0
	salud_maxima     = 95.0
	salud_actual     = salud_maxima
	daño             = _daño_base
	rango_ataque     = _rango_base
	velocidad_ataque = 1.2 # 1 disparo cada 1.2s
	speed            = 4.8
	radio_vision     = 30.0

	_update_weapon_prop()

func _ready() -> void:
	super._ready()
	add_to_group("military_units")
	add_to_group("archers_3d")
	add_to_group("ranged_units")

	# Conectar al sistema global de Eras
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _process(delta: float) -> void:
	if is_dead:
		return

	# Control del temporizador de disparo a distancia
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	# Si la FSM está en estado de ataque y el cooldown terminó
	if state_machine and state_machine.current_state and state_machine.current_state.state_name == &"Attacking":
		if _attack_cooldown_timer <= 0.0 and is_instance_valid(target_enemy):
			disparar_proyectil(target_enemy)

# ─── Comandos de Combate y Disparo Físico ─────────────────────────────────────

func command_attack(target: Node) -> void:
	if is_dead or not is_instance_valid(target) or target == self:
		return

	# Bloqueo estricto de fuego amigo
	if "bando" in target and int(target.bando) == int(bando):
		return
	if bando == Bando.PLAYER and (target.is_in_group("player_units") or target.is_in_group("player_buildings") or target.is_in_group("allies")):
		return
	if bando == Bando.ENEMY and (target.is_in_group("enemy_units") or target.is_in_group("enemy_buildings")):
		return

	target_enemy = target as Node3D
	if state_machine:
		state_machine.change_state(&"Attacking", {"target": target})

## Instancia y dispara físicamente un Projectile3D hacia la unidad objetivo.
func disparar_proyectil(target: Node3D) -> void:
	if is_dead or not is_instance_valid(target):
		return

	_attack_cooldown_timer = velocidad_ataque

	# Orientar hacia el enemigo antes de disparar
	var look_target := Vector3(target.global_position.x, global_position.y, target.global_position.z)
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)

	# 1. Búsqueda obligatoria del socket 'ProjectileMuzzle' ANTES de instanciar Projectile3D
	var muzzle: Node3D = find_child("ProjectileMuzzle", true, false) as Node3D
	var spawn_pos: Vector3
	if is_instance_valid(muzzle):
		spawn_pos = muzzle.global_position
	else:
		# Fallback con elevación natural para mallas sin socket de Blender
		spawn_pos = global_position + Vector3(0.0, 1.2, 0.0)

	# 2. Instanciación del proyectil físico 3D con spawn exacto en el espacio 3D
	var proj := Projectile3D.new()
	proj.projectile_type = projectile_type
	proj.damage = daño
	proj.bando = bando
	proj.source_unit = self
	proj.target_node = target
	proj.target_position = target.global_position + Vector3(0.0, 1.2, 0.0)

	var parent: Node = get_tree().current_scene.get_node_or_null("World/Projectiles") if get_tree() and get_tree().current_scene else null
	if not is_instance_valid(parent) and get_tree():
		parent = get_tree().current_scene
	if is_instance_valid(parent):
		parent.add_child(proj)
		proj.global_position = spawn_pos

	# Efecto de audio al disparar
	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("play_attack_alert"):
		sm.play_attack_alert()

	print("Archer3D '%s': Disparado proyectil '%s' (Daño: %.1f) desde Muzzle en %s hacia '%s'" % [
		name, projectile_type, daño, spawn_pos, target.name
	])

# ─── Evolución Estética y de Balística por Era (Eras 0 a 9) ───────────────────

func _update_weapon_prop() -> void:
	if has_method("set_hand_prop"):
		call("set_hand_prop", weapon_type)

func _on_era_evolucionada(player_id: Variant = 1, _nueva_era: Variant = null, _extra: Variant = null) -> void:
	if is_dead:
		return
	var p_id: int = int(player_id) if (player_id is int or player_id is float) else 1
	if self.owner_peer_id != p_id:
		return
	var e_entrenada: int = int(get("era_entrenada")) if get("era_entrenada") != null else 0
	print("Archer3D '%s': Veterano militar arquero (Era %d) preservado intacto en combate." % [name, e_entrenada])
	return
