## UnitAnimationController3D — Controlador de Animación Genérico 3D (GDScript 2.0 / Godot 4).
##
## Se adjunta como hijo de cualquier UnitBase3D (CharacterBody3D) y gestiona:
##   1. BlendSpace 1D dinámico — Idle / Walk / Run según velocity.xz.length().
##   2. Disparo OneShot de ataque sincronizado por RPC al tener autoridad de red.
##   3. LOD de animación por distancia a la cámara — reduce el proceso a 15 FPS
##      cuando la unidad está más lejos de ANIM_LOD_DISTANCE metros.
##
## USO: Añadir como hijo directo de la unidad. El script auto-descubre el
## AnimationTree y el MultiplayerSynchronizer de la misma unidad padre.
##
## CONVENCIÓN DE PARÁMETROS DEL AnimationTree:
##   - "parameters/move_blend/blend_position"  → float  (0.0=Idle, 4.2=Walk, 8.4=Run)
##   - "parameters/attack_oneshot/request"     → int    (AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

class_name UnitAnimationController3D
extends Node

# ─── Constantes de LOD y Velocidad ────────────────────────────────────────────
## Distancia en metros a partir de la cual se activa el LOD de animación.
const ANIM_LOD_DISTANCE: float = 55.0

## Velocidad de umbral para transicionar Walk → Run en el BlendSpace 1D.
## Coincide con la velocidad de la Era 8-9 (Futurista) de las unidades.
const RUN_SPEED_THRESHOLD: float = 7.0

## FPS reducidos cuando la unidad está fuera del radio de LOD.
const LOD_PROCESS_FPS: float = 15.0
const LOD_PROCESS_INTERVAL: float = 1.0 / LOD_PROCESS_FPS

## FPS completos en primer plano (60 FPS).
const FULL_PROCESS_FPS: float = 60.0

## Parámetros del AnimationTree (nombres de los parámetros internos).
const PARAM_BLEND  := "parameters/move_blend/blend_position"
const PARAM_ATTACK := "parameters/attack_oneshot/request"

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _unit: CharacterBody3D              = null   # Referencia al CharacterBody3D padre
var _anim_tree: AnimationTree           = null   # AnimationTree de la unidad
var _mp_sync: MultiplayerSynchronizer   = null   # Para sincronizar la animación de ataque

## Velocidad de blend suavizada (evita saltos visuales entre frames).
var _current_blend: float = 0.0

## Acumulador de tiempo para el LOD de animación.
var _lod_timer: float = 0.0
var _is_in_lod: bool  = false

## Referencia a la cámara RTS principal (buscada una vez en _ready).
var _rts_camera: Camera3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Validar que el padre es un CharacterBody3D (UnitBase3D)
	var parent := get_parent()
	if not (parent is CharacterBody3D):
		push_warning("UnitAnimationController3D: El padre '%s' no es un CharacterBody3D. Desactivado." % parent.name)
		set_process(false)
		return

	_unit = parent as CharacterBody3D

	# Auto-descubrir AnimationTree
	_anim_tree = _unit.get_node_or_null("AnimationTree") as AnimationTree
	if not is_instance_valid(_anim_tree):
		# Buscar recursivamente en hijos
		_anim_tree = _unit.find_child("AnimationTree", true, false) as AnimationTree
	if is_instance_valid(_anim_tree):
		_anim_tree.active = true
	else:
		push_warning("UnitAnimationController3D '%s': No se encontró AnimationTree. El controlador de blend está inactivo." % _unit.name)

	# Auto-descubrir MultiplayerSynchronizer
	_mp_sync = _unit.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if not is_instance_valid(_mp_sync):
		_mp_sync = _unit.find_child("MultiplayerSynchronizer", true, false) as MultiplayerSynchronizer

	# Buscar cámara RTS principal (grupo "rts_camera" o primer Camera3D activo)
	_rts_camera = _get_rts_camera()

	print("UnitAnimationController3D: Iniciado para '%s'. AnimTree=%s | Sync=%s" % [
		_unit.name,
		"OK" if is_instance_valid(_anim_tree) else "AUSENTE",
		"OK" if is_instance_valid(_mp_sync) else "SIN SYNC"
	])

func _get_rts_camera() -> Camera3D:
	var cam_group := get_tree().get_nodes_in_group("rts_camera") if get_tree() else []
	for node in cam_group:
		if node is Camera3D and (node as Camera3D).current:
			return node as Camera3D
		elif node is Camera3D:
			return node as Camera3D
	# Fallback: cámara activa actual del viewport
	return get_viewport().get_camera_3d() if get_viewport() else null

# ─── Proceso Principal — BlendSpace 1D y LOD ─────────────────────────────────

func _process(delta: float) -> void:
	if not is_instance_valid(_unit) or not is_instance_valid(_anim_tree):
		return

	# ── Evaluación de LOD por Distancia a la Cámara RTS Principal (55.0m) ────
	_update_lod_state()
	
	if _is_in_lod:
		# Modo manual para estrangular la actualización a 15 FPS estrictos
		_set_anim_process_mode(true)
		
		_lod_timer += delta
		if _lod_timer >= LOD_PROCESS_INTERVAL:
			_anim_tree.advance(_lod_timer)
			_lod_timer = 0.0
		else:
			return # Omitir el procesamiento de frames en el _process para liberar ciclos críticos de la CPU en móviles
	else:
		# Restaurar procesamiento a frame rate completo (60 FPS / Idle)
		_set_anim_process_mode(false)
		_lod_timer = 0.0

	# ── BlendSpace 1D — Velocidad XZ → Blend Position ────────────────────────
	_update_move_blend(delta)

func _set_anim_process_mode(manual: bool) -> void:
	var target_mode: int = 2 if manual else 1 # 2: MANUAL, 1: IDLE / NORMAL
	if "callback_mode_process" in _anim_tree:
		if int(_anim_tree.callback_mode_process) != target_mode:
			_anim_tree.callback_mode_process = target_mode
	elif "process_callback" in _anim_tree:
		if int(_anim_tree.get("process_callback")) != target_mode:
			_anim_tree.set("process_callback", target_mode)

func _update_lod_state() -> bool:
	# Refrescar referencia a cámara si se invalidó (cambio de escena o runtime)
	if not is_instance_valid(_rts_camera):
		_rts_camera = _get_rts_camera()

	if not is_instance_valid(_rts_camera):
		_is_in_lod = false
		return false

	var dist := _unit.global_position.distance_to(_rts_camera.global_position)
	_is_in_lod = dist > ANIM_LOD_DISTANCE # 55.0m
	return true

func _update_move_blend(delta: float) -> void:
	# Velocidad real en el plano XZ (ignora la componente Y de gravedad)
	var xz_velocity := Vector3(_unit.velocity.x, 0.0, _unit.velocity.z)
	var target_speed := xz_velocity.length()

	# Suavizar la transición del blend (evita pop visual entre frames)
	_current_blend = lerp(_current_blend, target_speed, minf(delta * 8.0, 1.0))

	# Inyectar en el parámetro del AnimationTree
	if _anim_tree.has_parameter(PARAM_BLEND):
		_anim_tree.set(PARAM_BLEND, _current_blend)

# ─── Disparo de Animación de Ataque (OneShot RPC Synchronization) ─────────────

## Invocado por la FSM (StateAttacking3D) cuando la unidad asesta un golpe.
## Si la unidad es la autoridad de red, dispara el OneShot y lo sincroniza en clientes.
func reproducir_ataque_visual(tipo_arma: String = "melee") -> void:
	_fire_attack_oneshot_local()

	# Sincronizar en clientes vía RPC si la unidad tiene autoridad de red
	var has_peer := multiplayer.has_multiplayer_peer()
	var is_authority := (not has_peer) or _unit.is_multiplayer_authority()
	if has_peer and is_authority:
		rpc("_rpc_sync_attack_visual", tipo_arma)

func _fire_attack_oneshot_local() -> void:
	if not is_instance_valid(_anim_tree):
		return
	if _anim_tree.has_parameter(PARAM_ATTACK):
		_anim_tree.set(PARAM_ATTACK, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

## RPC recibido por los clientes para reproducir la animación de ataque de forma sincronizada.
@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_attack_visual(_tipo_arma: String) -> void:
	_fire_attack_oneshot_local()

# ─── API Pública — Control Manual ─────────────────────────────────────────────

## Fuerza la reproducción de una animación directamente via AnimationPlayer (fallback).
func play_direct(anim_name: String) -> void:
	var anim_player := _unit.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if is_instance_valid(anim_player) and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

## Activa o desactiva el AnimationTree completo (ej. para unidades muertas).
func set_anim_tree_active(active: bool) -> void:
	if is_instance_valid(_anim_tree):
		_anim_tree.active = active

## Establece manualmente el nivel de LOD para pruebas (sin depender de la cámara).
func force_lod(active: bool) -> void:
	_is_in_lod = active
