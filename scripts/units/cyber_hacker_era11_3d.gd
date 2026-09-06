## Cyber_Hacker — Exosoldado Hacker de Red (Edad Nano-Futurista / Era 11).
##
## Unidad de infantería táctica pesada con implantes cibernéticos.
## Su habilidad activa 'aplicar_hackeo_red()' por RPC síncrono fiable fija una unidad militar o vehículo
## enemigo a <= 18m, ejecuta un protocolo de intrusión y al culminar cambia permanentemente su bando
## y 'owner_peer_id', convirtiéndola en una unidad aliada en red.
class_name Cyber_Hacker
extends "res://scripts/units/soldier_3d.gd"

signal hackeo_iniciado(objetivo: Node3D)
signal hackeo_completado(objetivo: Node3D, exito: bool)

@export var rango_hackeo: float = 18.0
@export var tiempo_hackeo: float = 3.0
var esta_hackeando: bool = false

func _init() -> void:
	unit_id = "cyber_hacker_era11"
	unit_name = "Exosoldado Hacker de Red"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "ENERGY"
	projectile_type = "bullet"
	_salud_base = 320.0
	salud_maxima = 320.0
	salud_actual = 320.0
	_daño_base = 34.0
	daño = 34.0
	rango_ataque = 18.0
	velocidad_ataque = 1.1
	speed = 4.8
	era_entrenada = 11

func _ready() -> void:
	super._ready()
	add_to_group("hackers")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_hacker_visuals()

func _setup_hacker_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.8)
		add_child(muzzle)

	if not has_node("CyberDeck"):
		var deck := MeshInstance3D.new()
		deck.name = "CyberDeck"
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.25, 0.5)
		deck.mesh = box
		deck.position = Vector3(0.35, 1.0, -0.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.05, 0.8, 0.7) # Cian cibernético
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 0.85)
		mat.emission_energy_multiplier = 2.0
		deck.material_override = mat
		add_child(deck)

## Habilidad activa por RPC fiable para vulnerar y convertir unidades rivales
@rpc("any_peer", "call_local", "reliable")
func aplicar_hackeo_red(param: Variant = null) -> bool:
	if is_dead:
		return false

	var objetivo: Node3D = param as Node3D if param is Node3D else null
	if not is_instance_valid(objetivo):
		objetivo = _buscar_objetivo_hackeo()

	if not is_instance_valid(objetivo):
		return false

	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := objetivo.global_position if objetivo.is_inside_tree() else objetivo.position
	if my_pos.distance_to(tgt_pos) > rango_hackeo:
		return false

	if objetivo.get("is_hack_immune") == true:
		return false

	# Si es de nuestro propio bando, no hace falta hackear
	if "bando" in objetivo and objetivo.get("bando") == bando:
		return false

	esta_hackeando = true
	hackeo_iniciado.emit(objetivo)

	var exito: bool = false
	if objetivo.has_method("aplicar_hackeo"):
		exito = objetivo.call("aplicar_hackeo", int(bando), int(owner_peer_id))
	else:
		if "bando" in objetivo:
			objetivo.set("bando", bando)
		if "owner_peer_id" in objetivo:
			objetivo.set("owner_peer_id", owner_peer_id)
		if bando == Bando.PLAYER:
			if objetivo.is_in_group("enemy_units"):
				objetivo.remove_from_group("enemy_units")
			objetivo.add_to_group("player_units")
		else:
			if objetivo.is_in_group("player_units"):
				objetivo.remove_from_group("player_units")
			objetivo.add_to_group("enemy_units")
		exito = true

	esta_hackeando = false
	hackeo_completado.emit(objetivo, exito)
	return exito

func _buscar_objetivo_hackeo() -> Node3D:
	var grupo_enemigo := "enemy_units" if bando == Bando.PLAYER else "player_units"
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if not is_instance_valid(tree):
		return null
	var enemigos := tree.get_nodes_in_group(grupo_enemigo)
	var mejor: Node3D = null
	var mejor_dist: float = rango_hackeo
	var my_pos := global_position if is_inside_tree() else position

	for e in enemigos:
		if is_instance_valid(e) and e is Node3D and e != self and not e.get("is_dead"):
			if e.get("is_hack_immune") == true:
				continue
			var pos := (e as Node3D).global_position if (e as Node3D).is_inside_tree() else (e as Node3D).position
			var d := my_pos.distance_to(pos)
			if d <= mejor_dist:
				mejor_dist = d
				mejor = e as Node3D
	return mejor
