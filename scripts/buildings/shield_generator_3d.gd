## ShieldGenerator3D — Generador de Escudos Hexagonales (Edad Nano-Futurista / Era 11).
##
## Estructura defensiva que hereda de Tower3D. No dispara proyectiles; al estar construida al 100%,
## proyecta una cúpula holográfica Area3D de 15 metros de radio.
## Aplica una mitigación y escudo impenetrable del -70% a todo daño físico, balístico o explosivo
## que reciban las estructuras o unidades aliadas guarecidas en su interior.
class_name ShieldGenerator3D
extends "res://scripts/buildings/tower_3d.gd"

signal cupula_activada(radio: float)

@export var radio_cupula: float = 15.0
@export var factor_mitigacion: float = 0.30 # -70% de daño recibido

var area_cupula: Area3D = null
var cúpula_activa: bool = false
var unidades_protegidas: Array[Node3D] = []

func _init() -> void:
	super._init()
	building_name = "Generador de Escudos Hexagonales"
	salud_maxima = 2500.0
	salud_actual = 2500.0
	_salud_maxima_base = 2500.0
	radio_vision = 35.0

func _ready() -> void:
	super._ready()
	building_name = "Generador de Escudos Hexagonales"
	add_to_group("shield_generators")
	add_to_group("defense_structures")
	_setup_generator_visuals()
	_crear_area_cupula()
	actualizar_estado_cupula()

func _setup_generator_visuals() -> void:
	if not has_node("PylonCore"):
		var pylon := MeshInstance3D.new()
		pylon.name = "PylonCore"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.8
		cyl.bottom_radius = 1.3
		cyl.height = 4.8
		pylon.mesh = cyl
		pylon.position = Vector3(0.0, 2.4, 0.0)
		var mat_p := StandardMaterial3D.new()
		mat_p.albedo_color = Color(0.15, 0.22, 0.3)
		mat_p.metallic = 0.9
		mat_p.roughness = 0.2
		pylon.material_override = mat_p
		add_child(pylon)

	if not has_node("HoloDomeVisual"):
		var dome := MeshInstance3D.new()
		dome.name = "HoloDomeVisual"
		var sph := SphereMesh.new()
		sph.radius = radio_cupula
		sph.height = radio_cupula * 1.5
		dome.mesh = sph
		dome.position = Vector3(0.0, 1.0, 0.0)
		var mat_d := StandardMaterial3D.new()
		mat_d.albedo_color = Color(0.0, 0.8, 1.0, 0.25)
		mat_d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_d.emission_enabled = true
		mat_d.emission = Color(0.0, 0.6, 1.0)
		mat_d.emission_energy_multiplier = 1.8
		dome.material_override = mat_d
		add_child(dome)

func _crear_area_cupula() -> void:
	if has_node("ShieldArea3D"):
		area_cupula = get_node("ShieldArea3D") as Area3D
		return

	area_cupula = Area3D.new()
	area_cupula.name = "ShieldArea3D"
	var col := CollisionShape3D.new()
	col.name = "DomeCollision"
	var sph := SphereShape3D.new()
	sph.radius = radio_cupula
	col.shape = sph
	area_cupula.add_child(col)
	add_child(area_cupula)

	area_cupula.body_entered.connect(_on_dome_body_entered)
	area_cupula.body_exited.connect(_on_dome_body_exited)

## No dispara proyectiles ofensivos (estructura puramente de protección cuántica)
func _execute_defensive_attack() -> void:
	pass

func _process(delta: float) -> void:
	super._process(delta)
	actualizar_estado_cupula()

func actualizar_estado_cupula() -> void:
	var activo: bool = esta_construido and not is_dead
	cúpula_activa = activo
	if is_instance_valid(area_cupula):
		area_cupula.monitoring = activo

	var dome_vis := get_node_or_null("HoloDomeVisual") as MeshInstance3D
	if is_instance_valid(dome_vis):
		dome_vis.visible = activo

	if activo:
		proteger_aliados_en_radio()
		cupula_activada.emit(radio_cupula)

## Aplica la mitigación del -70%
func mitigar_dano(dano_entrante: float) -> float:
	return dano_entrante * factor_mitigacion

## Comprueba si un nodo se encuentra dentro de los 15 metros del escudo
func esta_en_rango_escudo(nodo: Node3D) -> bool:
	if not is_instance_valid(nodo):
		return false
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := nodo.global_position if nodo.is_inside_tree() else nodo.position
	return my_pos.distance_to(tgt_pos) <= radio_cupula

## Aplica flags de escudo a un nodo aliado
func proteger_nodo(nodo: Node3D) -> void:
	if not is_instance_valid(nodo):
		return
	if "shield_generator_protected" in nodo:
		nodo.set("shield_generator_protected", true)
	nodo.add_to_group("shield_protected")
	if not unidades_protegidas.has(nodo):
		unidades_protegidas.append(nodo)

func desproteger_nodo(nodo: Node3D) -> void:
	if not is_instance_valid(nodo):
		return
	if "shield_generator_protected" in nodo:
		nodo.set("shield_generator_protected", false)
	nodo.remove_from_group("shield_protected")
	unidades_protegidas.erase(nodo)

## Barre aliados cercanos en radio de 15m y los protege
func proteger_aliados_en_radio() -> void:
	var my_bando: int = int(bando)
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if not is_instance_valid(tree):
		return

	var grupo_aliado := "player_units" if my_bando == 0 else "enemy_units"
	var aliados := tree.get_nodes_in_group(grupo_aliado)
	for a in aliados:
		if is_instance_valid(a) and a is Node3D:
			if esta_en_rango_escudo(a as Node3D):
				proteger_nodo(a as Node3D)

func _on_dome_body_entered(body: Node) -> void:
	if not cúpula_activa or not (body is Node3D):
		return
	if "bando" in body and int(body.get("bando")) == int(bando):
		proteger_nodo(body as Node3D)

func _on_dome_body_exited(body: Node) -> void:
	if body is Node3D:
		desproteger_nodo(body as Node3D)
