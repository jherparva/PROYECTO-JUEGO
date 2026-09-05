## DropOffDepot3D — Almacén / Granero Depósito Periférico y Laboratorio Económico (Godot 4).
##
## Edificio de recolección secundaria que permite a los aldeanos depositar madera, comida,
## piedra, oro e hierro cerca de las minas/bosques y realizar investigaciones tecnológicas.

class_name DropOffDepot3D
extends "res://scripts/buildings/building_base_3d.gd"

signal resources_deposited(resource_type: String, amount: int)
signal tech_researched(tech_id: String, tech_name: String)

# ─── Catálogo de Tecnologías Económicas por Rama ──────────────────────────────
const TECH_DATABASE: Dictionary = {
	# ── RAMA DE LOGÍSTICA (Capacidad de carga aditiva: MAX_CARGA) ─────────────
	"carretilla": {
		"name": "Carretilla de Madera",
		"branch": "logistics",
		"cost": {"food": 100, "wood": 50},
		"capacity_bonus": 5,
		"gather_bonus": 0.0,
		"build_bonus": 0.0,
		"era_req": 1
	},
	"traccion_animal": {
		"name": "Tracción Animal & Carros",
		"branch": "logistics",
		"cost": {"food": 250, "wood": 150},
		"capacity_bonus": 10,
		"gather_bonus": 0.0,
		"build_bonus": 0.0,
		"era_req": 3
	},
	"contenedores_auto": {
		"name": "Contenedores Automatizados",
		"branch": "logistics",
		"cost": {"food": 500, "iron": 300},
		"capacity_bonus": 15,
		"gather_bonus": 0.0,
		"build_bonus": 0.0,
		"era_req": 6
	},

	# ── RAMA DE HERRAMIENTAS (Velocidad de recolección aditiva: gather_rate) ──
	"picos_pulidos": {
		"name": "Picos de Piedra Pulida",
		"branch": "tools",
		"cost": {"food": 75, "stone": 50},
		"capacity_bonus": 0,
		"gather_bonus": 0.10, # +10%
		"build_bonus": 0.0,
		"era_req": 1
	},
	"herramientas_bronce": {
		"name": "Herramientas de Bronce",
		"branch": "tools",
		"cost": {"food": 150, "iron": 100},
		"capacity_bonus": 0,
		"gather_bonus": 0.15, # +15%
		"build_bonus": 0.0,
		"era_req": 2
	},
	"taladros_neumaticos": {
		"name": "Taladros Hidráulicos",
		"branch": "tools",
		"cost": {"food": 400, "iron": 250, "gold": 150},
		"capacity_bonus": 0,
		"gather_bonus": 0.20, # +20%
		"build_bonus": 0.0,
		"era_req": 6
	},

	# ── RAMA DE CONSTRUCCIÓN (Velocidad de obra: build_speed) ─────────────────
	"andamios_madera": {
		"name": "Andamios y Poleas",
		"branch": "construction",
		"cost": {"wood": 120, "stone": 60},
		"capacity_bonus": 0,
		"gather_bonus": 0.0,
		"build_bonus": 0.15, # +15% build_speed
		"era_req": 2
	},
	"gruas_vapor": {
		"name": "Grúas de Vapor",
		"branch": "construction",
		"cost": {"wood": 300, "iron": 200},
		"capacity_bonus": 0,
		"gather_bonus": 0.0,
		"build_bonus": 0.30, # +30% build_speed
		"era_req": 6
	}
}

var researched_techs: Array[String] = []

func _init() -> void:
	building_name = "Almacén de Depósito"
	salud_maxima = 450.0
	salud_actual = 450.0

func _ready() -> void:
	super._ready()
	add_to_group("town_centers")
	add_to_group("settlements")
	add_to_group("drop_off_buildings")
	add_to_group("drop_off_depots")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	# Conectar a la señal global de cambio de era para swap visual
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

# ─── API de Depósito de Recursos ───────────────────────────────────────────────

func deposit_resources(resource_type: String, amount: int, depositor: Node = null) -> void:
	if is_dead or is_under_construction:
		return

	if bando == Bando.PLAYER:
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and rm.has_method("add_resources"):
			rm.add_resources(resource_type, amount)
	else:
		var enemy_ais := get_tree().get_nodes_in_group("enemy_ai")
		for ai in enemy_ais:
			if is_instance_valid(ai) and ai.has_method("agregar_recursos_ia"):
				ai.agregar_recursos_ia(resource_type, amount)

	resources_deposited.emit(resource_type, amount)
	_mostrar_feedback_deposito(resource_type, amount)

func _mostrar_feedback_deposito(res_type: String, amount: int) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 26
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.modulate = Color(0.2, 1.0, 0.5)
	label.position = Vector3(0.0, 2.5, 0.0)
	label.text = "+%d %s" % [amount, res_type.capitalize()]
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", 4.0, 1.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.4)
	tween.tween_callback(label.queue_free)

# ─── Laboratorio de Investigaciones Económicas ────────────────────────────────

func investigar_tecnologia(id_tech: String) -> bool:
	if not TECH_DATABASE.has(id_tech) or researched_techs.has(id_tech):
		return false

	var tech_info: Dictionary = TECH_DATABASE[id_tech]
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		return false

	# Verificar costo
	var cost: Dictionary = tech_info.get("cost", {})
	if rm.has_method("gastar_recursos") and not rm.gastar_recursos(cost):
		print("DropOffDepot3D: Fondos insuficientes para '%s'" % tech_info["name"])
		return false

	researched_techs.append(id_tech)

	# Aplicar el bono a todos los aldeanos del jugador en el mapa
	var g_bonus: float = float(tech_info.get("gather_bonus", 0.0))
	var c_bonus: int   = int(tech_info.get("capacity_bonus", 0))

	for u in get_tree().get_nodes_in_group("player_units"):
		if is_instance_valid(u) and u.has_method("apply_tech_upgrade"):
			u.call("apply_tech_upgrade", id_tech, g_bonus, c_bonus)

	tech_researched.emit(id_tech, tech_info["name"])
	print("DropOffDepot3D: ¡Investigación '%s' completada!" % tech_info["name"])
	return true

# ─── Evolución Estética por Era (Visual Mesh Swap Eras 0 a 9) ─────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return
	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	# Ocultar todos los nodos de malla hijos específicos de era si existen
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	# Activar la malla correspondiente a la Era actual usando Match
	match era_val:
		0, 1: # Prehistórica y Piedra
			_activar_mesh_por_nombre("EraMesh_PrimitiveHut")
			building_name = "Campamento de Depósito Primitivo"
		2, 3: # Bronce y Hierro
			_activar_mesh_por_nombre("EraMesh_WoodenDepot")
			building_name = "Almacén de Madera y Piedra"
		4, 5: # Medieval y Renacimiento
			_activar_mesh_por_nombre("EraMesh_BrickWarehouse")
			building_name = "Granero & Almacén de Ladrillo"
		6, 7: # Industrial y Atómica
			_activar_mesh_por_nombre("EraMesh_ConcreteFactory")
			building_name = "Depósito Industrial de Hormigón"
		8, 9: # Digital y Nano-Futurista
			_activar_mesh_por_nombre("EraMesh_ModularNanoDepot")
			building_name = "Depósito Modular Nanotécnico"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true
