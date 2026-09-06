## OrbitalCannonPlatform3D — Plataforma de Inducción Magnética Espacial (Edad Nano-Futurista / Era 11).
##
## Súper-estructura monumental de Era 11 que hereda directamente de Barracks3D.
## Permite fabricar a un costo masivo el proyectil de Cañón Orbital de Plasma.
## Al activarse por RPC fiable desde el Servidor, dispara un haz de partículas vertical
## desde el espacio que detona en la coordenada elegida, generando un radio de explosión
## esférico de 22.0 metros con daño letal fulminante (9999 HP) a toda unidad militar o civil.
class_name OrbitalCannonPlatform3D
extends "res://scripts/buildings/barracks_3d.gd"

signal haz_orbital_disparado(coordenada: Vector3, objetivos_desintegrados: int)

@export var building_type: String = "orbital_platform"
@export var radio_detonacion: float = 22.0
@export var dano_desintegracion: float = 9999.0

func _init() -> void:
	super._init()
	building_name = "Plataforma de Inducción Magnética Espacial"
	salud_maxima = 4000.0
	salud_actual = 4000.0
	_salud_maxima_base = 4000.0
	radio_vision = 50.0

func _ready() -> void:
	super._ready()
	building_name = "Plataforma de Inducción Magnética Espacial"
	add_to_group("orbital_platforms")
	add_to_group("military_buildings")
	_setup_orbital_platform_visuals()

func _setup_orbital_platform_visuals() -> void:
	if not has_node("MagneticRing"):
		var ring := MeshInstance3D.new()
		ring.name = "MagneticRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 2.8
		torus.outer_radius = 3.6
		ring.mesh = torus
		ring.position = Vector3(0.0, 3.2, 0.0)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.1, 0.5, 0.9)
		mat_r.emission_enabled = true
		mat_r.emission = Color(0.0, 0.8, 1.0)
		mat_r.emission_energy_multiplier = 4.0
		ring.material_override = mat_r
		add_child(ring)

	if not has_node("CentralEmitter"):
		var emitter := MeshInstance3D.new()
		emitter.name = "CentralEmitter"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.6
		cyl.bottom_radius = 1.0
		cyl.height = 4.0
		emitter.mesh = cyl
		emitter.position = Vector3(0.0, 2.0, 0.0)
		var mat_e := StandardMaterial3D.new()
		mat_e.albedo_color = Color(0.12, 0.15, 0.2)
		mat_e.metallic = 0.95
		mat_e.roughness = 0.15
		emitter.material_override = mat_e
		add_child(emitter)

## Disparo espacial de rayo de partículas de muerte instantánea (22m, 9999 HP)
@rpc("any_peer", "call_local", "reliable")
func disparar_canon_orbital(coordenada_destino: Vector3) -> Array[Node3D]:
	var impactados: Array[Node3D] = []
	var posibles: Array = []
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if not is_instance_valid(tree):
		var ml = Engine.get_main_loop()
		if ml is SceneTree:
			tree = ml

	var grupo_enemigo := "enemy_units" if bando == Bando.PLAYER else "player_units"
	if is_instance_valid(tree):
		posibles.append_array(tree.get_nodes_in_group(grupo_enemigo))
		posibles.append_array(tree.get_nodes_in_group("units_3d"))
		posibles.append_array(tree.get_nodes_in_group("villagers"))
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if is_instance_valid(child) and child is Node3D and not posibles.has(child):
					posibles.append(child)
	if is_instance_valid(get_parent()):
		for child in get_parent().get_children():
			if is_instance_valid(child) and child is Node3D and not posibles.has(child):
				posibles.append(child)

	var procesados: Dictionary = {}
	for u in posibles:
		if not is_instance_valid(u) or not (u is Node3D) or u == self:
			continue
		if procesados.has(u):
			continue
		procesados[u] = true

		var u_3d := u as Node3D
		var u_pos: Vector3 = u_3d.position if u_3d.position != Vector3.ZERO else (u_3d.global_position if u_3d.is_inside_tree() else u_3d.position)
		if coordenada_destino.distance_to(u_pos) <= radio_detonacion:
			impactados.append(u_3d)
			if u.has_method("recibir_dano"):
				u.call("recibir_dano", dano_desintegracion)
			elif u.has_method("recibir_daño"):
				u.call("recibir_daño", dano_desintegracion)
			elif "salud_actual" in u:
				u.set("salud_actual", maxf(0.0, float(u.get("salud_actual")) - dano_desintegracion))
			if u.has_method("morir") and ("salud_actual" in u and float(u.get("salud_actual")) <= 0.0):
				u.call("morir")

	haz_orbital_disparado.emit(coordenada_destino, impactados.size())
	return impactados
