## Villager3D — Unidad recolectora y constructora 3D (GDScript 2.0 / Godot 4).
##
## Extiende UnitBase3D con mecánicas de inventario de recursos (MAX_CARGA = 15),
## actualización visual de herramientas en mano ("RightHandAttachment") y
## fardos/cestas en la espalda ("BackAttachment").

class_name Villager3D
extends "res://scripts/units/unit_base_3d.gd"


# ─── Constantes y Stats de Trabajo ─────────────────────────────────────────────
@export_group("Gathering")
## Capacidad máxima de carga de recursos por viaje (Requerido: 15 unidades).
@export var MAX_CARGA: int = 15
## Cantidad de recursos extraídos por segundo (valor base para Era PREHISTORICA).
@export var gather_rate: float = 1.0

@export_group("Construction")
## HP de edificio construido o reparado por segundo.
@export var build_speed: float = 10.0

# ─── Valores Base (para calcular multiplicadores de era sobre el original) ─────
## Valor base de gather_rate antes de aplicar cualquier multiplicador de era.
var _gather_rate_base: float = 1.0
## Valor base de build_speed antes de aplicar cualquier multiplicador de era.
var _build_speed_base: float = 10.0

# ─── Estado de Inventario de Carga ─────────────────────────────────────────────
var carried_amount: int = 0
var carried_resource_type: String = ""

# ─── Inicialización ────────────────────────────────────────────────────────────

func _setup_stats() -> void:
	unit_name       = "Villager3D"
	max_hp          = 60
	hp              = max_hp
	speed           = 4.2
	attack_damage   = 3
	attack_range    = 1.8
	attack_cooldown = 1.5

	# Registrar valores base para que los multiplicadores de era puedan escalar correctamente
	_gather_rate_base = gather_rate
	_build_speed_base = build_speed

	var gs: Node = get_node_or_null("/root/GameSettings")
	var rm: Node = get_node_or_null("/root/ResourceManager")
	var era_val: int = 0
	if is_instance_valid(gs) and "starting_era" in gs:
		era_val = int(gs.get("starting_era"))
	elif is_instance_valid(rm) and "era_actual" in rm:
		era_val = int(rm.era_actual)

	if era_val > 0:
		salud_maxima = 60.0 + (era_val * 5.0)
		salud_actual = salud_maxima
		speed = 4.2 * pow(1.05, era_val)
		MAX_CARGA = 15 + (era_val * 5)
		if is_instance_valid(rm) and "multiplicador_recoleccion" in rm:
			gather_rate = _gather_rate_base * float(rm.multiplicador_recoleccion)

	# Conectar la señal global de cambio de era
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

@onready var status_label: Label3D = get_node_or_null("StatusLabel") as Label3D
@onready var visual_model: Node3D = null

func _ready() -> void:
	super._ready()
	
	# Attempt to load custom GLB for era 0
	var gltf_path := "res://assets/models/era0/guerrero.glb"
	var loaded_custom := false
	if ResourceLoader.exists(gltf_path):
		var pscene := load(gltf_path) as PackedScene
		if pscene:
			var inst := pscene.instantiate() as Node3D
			if is_instance_valid(inst):
				inst.name = "CavemanModel"
				add_child(inst)
				
				# Free old generic one if present
				var old_model = get_node_or_null("CavemanModel")
				if is_instance_valid(old_model) and old_model != inst:
					old_model.name = "OldCaveman"
					old_model.queue_free()
				
				visual_model = inst
				loaded_custom = true
				
	if not loaded_custom:
		visual_model = get_node_or_null("CavemanModel") as Node3D

	# Sincronización Inmediata con la Era Inicial configurada (Runtime Mesh Swap)
	var gs_node: Node = get_node_or_null("/root/GameSettings")
	var rm_node: Node = get_node_or_null("/root/ResourceManager")
	var cur_era: int = 0
	if is_instance_valid(gs_node) and "starting_era" in gs_node:
		cur_era = int(gs_node.get("starting_era"))
	elif is_instance_valid(rm_node) and "era_actual" in rm_node:
		cur_era = int(rm_node.era_actual)

	_actualizar_modelo_visual_era(cur_era)

func _ensure_state_machine() -> void:
	if is_instance_valid(_state_machine):
		return
	var sm_node := get_node_or_null("StateMachine3D")
	if is_instance_valid(sm_node):
		_state_machine = sm_node
		return
	var sm_class := load("res://scripts/units/fsm/state_machine_3d.gd")
	if not sm_class:
		return
	var sm = sm_class.new()
	sm.name = "StateMachine3D"
	add_child(sm)
	_state_machine = sm

	var states := {
		"Idle": load("res://scripts/units/fsm/state_idle_3d.gd"),
		"Move": load("res://scripts/units/fsm/state_move_3d.gd"),
		"Gathering": load("res://scripts/units/fsm/state_gathering_3d.gd"),
		"Attacking": load("res://scripts/units/fsm/state_attacking_3d.gd"),
		"Building": load("res://scripts/units/fsm/state_building_3d.gd"),
	}
	for sname in states:
		var s_class = states[sname]
		if s_class:
			var s_inst = s_class.new()
			s_inst.name = sname
			sm.add_child(s_inst)
	if sm.has_method("_ready"):
		sm._ready()

var _walk_anim_timer: float = 0.0
var _gather_anim_timer: float = 0.0
var _is_gathering_anim: bool = false

func set_status_text(text: String, duration: float = 0.0) -> void:
	if is_instance_valid(status_label):
		status_label.text = text
		if duration > 0.0:
			var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if is_instance_valid(tree):
				tree.create_timer(duration).timeout.connect(func() -> void:
					if is_instance_valid(status_label) and status_label.text == text:
						status_label.text = ""
				)

func set_gathering_animation(active: bool) -> void:
	_is_gathering_anim = active

func _physics_process(delta: float) -> void:
	if not is_instance_valid(visual_model):
		return

	var is_moving: bool = velocity.length_squared() > 0.08

	if is_moving:
		_walk_anim_timer += delta * 14.0
		visual_model.position.y = abs(sin(_walk_anim_timer)) * 0.12
		visual_model.rotation.z = sin(_walk_anim_timer) * 0.09
		visual_model.rotation.x = 0.12
	elif _is_gathering_anim:
		_gather_anim_timer += delta * 7.0
		visual_model.rotation.x = -sin(_gather_anim_timer) * 0.35
		visual_model.position.y = maxf(0.0, sin(_gather_anim_timer) * 0.08)
		visual_model.rotation.z = lerpf(visual_model.rotation.z, 0.0, delta * 8.0)
	else:
		visual_model.position.y = lerpf(visual_model.position.y, 0.0, delta * 8.0)
		visual_model.rotation.x = lerpf(visual_model.rotation.x, 0.0, delta * 8.0)
		visual_model.rotation.z = lerpf(visual_model.rotation.z, 0.0, delta * 8.0)

# ─── Lógica de Inventario ──────────────────────────────────────────────────────

## Retorna true si la carga del aldeano ha alcanzado o superado la capacidad máxima.
func is_inventory_full() -> bool:
	return carried_amount >= MAX_CARGA

var inventory_full: bool:
	get:
		return is_inventory_full()

## Añade `amount` de un recurso determinado al inventario del aldeano.
## Retorna cuántas unidades realmente cupieron.
func add_carried_resource(res_type: String, amount: int) -> int:
	# Si cambia de tipo de recurso (e.g. de madera a comida), reinicia el inventario para el nuevo recurso
	if carried_resource_type != res_type:
		carried_amount = 0
		carried_resource_type = res_type

	var space_left: int = MAX_CARGA - carried_amount
	var added: int = mini(amount, space_left)
	carried_amount += added
	
	# Actualizar la representación visual en la espalda si lleva recursos
	if carried_amount > 0:
		update_back_prop_visual()
		
	return added

## Vacía el inventario al depositar en el Town Center.
## Retorna un diccionario con {"type": String, "amount": int}.
func clear_inventory() -> Dictionary:
	var deposited := {
		"type": carried_resource_type,
		"amount": carried_amount
	}
	carried_amount = 0
	carried_resource_type = ""
	set_back_prop("") # Ocultar prop de la espalda
	return deposited

# ─── Control Visual de Props (Mano y Espalda) ──────────────────────────────────

func get_right_hand_attachment() -> Node3D:
	var hand := super.get_right_hand_attachment()
	if not is_instance_valid(hand):
		hand = Node3D.new()
		hand.name = "RightHandAttachment"
		hand.position = Vector3(0.35, 0.7, 0.25)
		add_child(hand)
	return hand

func get_back_attachment() -> Node3D:
	var back := super.get_back_attachment()
	if not is_instance_valid(back):
		back = Node3D.new()
		back.name = "BackAttachment"
		back.position = Vector3(0.0, 0.85, -0.25)
		add_child(back)
	return back

func set_hand_prop(prop_name: String) -> void:
	_ensure_procedural_hand_props()
	super.set_hand_prop(prop_name)

func set_back_prop(prop_name: String) -> void:
	_ensure_procedural_back_props()
	super.set_back_prop(prop_name)

func _ensure_procedural_hand_props() -> void:
	var hand := get_right_hand_attachment()
	if not is_instance_valid(hand):
		return

	# 1. Hacha ("axe")
	if not hand.has_node("axe"):
		var axe := Node3D.new()
		axe.name = "axe"
		var handle := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.height = 0.6
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.025
		handle.mesh = cyl
		var mat_wood := StandardMaterial3D.new()
		mat_wood.albedo_color = Color(0.45, 0.28, 0.15)
		handle.material_override = mat_wood

		var head := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.18, 0.14)
		head.mesh = box
		head.position = Vector3(0.0, 0.22, 0.06)
		var mat_stone := StandardMaterial3D.new()
		mat_stone.albedo_color = Color(0.52, 0.52, 0.55)
		head.material_override = mat_stone

		axe.add_child(handle)
		axe.add_child(head)
		axe.visible = false
		hand.add_child(axe)

	# 2. Pico ("pickaxe")
	if not hand.has_node("pickaxe"):
		var pick := Node3D.new()
		pick.name = "pickaxe"
		var handle := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.height = 0.65
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.025
		handle.mesh = cyl
		var mat_wood := StandardMaterial3D.new()
		mat_wood.albedo_color = Color(0.45, 0.28, 0.15)
		handle.material_override = mat_wood

		var head := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.04, 0.07, 0.38)
		head.mesh = box
		head.position = Vector3(0.0, 0.26, 0.0)
		var mat_iron := StandardMaterial3D.new()
		mat_iron.albedo_color = Color(0.35, 0.38, 0.42)
		mat_iron.metallic = 0.7
		head.material_override = mat_iron

		pick.add_child(handle)
		pick.add_child(head)
		pick.visible = false
		hand.add_child(pick)

	# 3. Maza / Martillo de Construcción ("Maza_Piedra" / "hammer")
	if not hand.has_node("Maza_Piedra"):
		var hammer := Node3D.new()
		hammer.name = "Maza_Piedra"
		var handle := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.height = 0.55
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.03
		handle.mesh = cyl
		var mat_wood := StandardMaterial3D.new()
		mat_wood.albedo_color = Color(0.42, 0.26, 0.14)
		handle.material_override = mat_wood

		var head := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.14, 0.22)
		head.mesh = box
		head.position = Vector3(0.0, 0.22, 0.0)
		var mat_rock := StandardMaterial3D.new()
		mat_rock.albedo_color = Color(0.40, 0.40, 0.42)
		mat_rock.roughness = 0.9
		head.material_override = mat_rock

		hammer.add_child(handle)
		hammer.add_child(head)
		hammer.visible = false
		hand.add_child(hammer)

	# 4. Lanza de Caza ("spear")
	if not hand.has_node("spear"):
		var spear := Node3D.new()
		spear.name = "spear"
		var shaft := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.height = 1.6
		cyl.top_radius = 0.022
		cyl.bottom_radius = 0.022
		shaft.mesh = cyl
		var mat_wood := StandardMaterial3D.new()
		mat_wood.albedo_color = Color(0.55, 0.40, 0.22)
		shaft.material_override = mat_wood

		var tip := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.08, 0.28, 0.03)
		tip.mesh = prism
		tip.position = Vector3(0.0, 0.85, 0.0)
		var mat_flint := StandardMaterial3D.new()
		mat_flint.albedo_color = Color(0.65, 0.68, 0.72)
		mat_flint.metallic = 0.5
		tip.material_override = mat_flint

		spear.add_child(shaft)
		spear.add_child(tip)
		spear.visible = false
		hand.add_child(spear)

func _ensure_procedural_back_props() -> void:
	var back := get_back_attachment()
	if not is_instance_valid(back):
		return

	# 1. Madera ("wood"): Fardo de 3 leños
	if not back.has_node("wood"):
		var wood_bundle := Node3D.new()
		wood_bundle.name = "wood"
		for i in range(3):
			var log_mesh := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.height = 0.75
			cyl.top_radius = 0.06
			cyl.bottom_radius = 0.06
			log_mesh.mesh = cyl
			log_mesh.rotation_degrees.x = 90.0
			var angle := float(i) * TAU / 3.0
			log_mesh.position = Vector3(cos(angle) * 0.07, sin(angle) * 0.07, 0.0)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.42, 0.26, 0.14)
			log_mesh.material_override = mat
			wood_bundle.add_child(log_mesh)
		wood_bundle.visible = false
		back.add_child(wood_bundle)

	# 2. Comida ("food"): Cesta de carne / víveres
	if not back.has_node("food"):
		var food_pack := Node3D.new()
		food_pack.name = "food"
		var basket := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.32, 0.28)
		basket.mesh = box
		var mat_basket := StandardMaterial3D.new()
		mat_basket.albedo_color = Color(0.62, 0.48, 0.30)
		basket.material_override = mat_basket
		food_pack.add_child(basket)

		var meat := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.12
		sph.height = 0.20
		meat.mesh = sph
		meat.position = Vector3(0.0, 0.16, 0.0)
		var mat_meat := StandardMaterial3D.new()
		mat_meat.albedo_color = Color(0.75, 0.22, 0.22)
		meat.material_override = mat_meat
		food_pack.add_child(meat)

		food_pack.visible = false
		back.add_child(food_pack)

	# 3. Piedra ("stone"): Saco de rocas
	if not back.has_node("stone"):
		var stone_sack := Node3D.new()
		stone_sack.name = "stone"
		var sack := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.22
		sph.height = 0.40
		sack.mesh = sph
		sack.scale = Vector3(0.9, 1.15, 0.85)
		var mat_stone := StandardMaterial3D.new()
		mat_stone.albedo_color = Color(0.48, 0.50, 0.52)
		sack.material_override = mat_stone
		stone_sack.add_child(sack)
		stone_sack.visible = false
		back.add_child(stone_sack)

	# 4. Oro ("gold"): Saco reluciente de pepitas
	if not back.has_node("gold"):
		var gold_sack := Node3D.new()
		gold_sack.name = "gold"
		var sack := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.20
		sph.height = 0.36
		sack.mesh = sph
		sack.scale = Vector3(0.9, 1.1, 0.85)
		var mat_gold := StandardMaterial3D.new()
		mat_gold.albedo_color = Color(0.95, 0.80, 0.15)
		mat_gold.metallic = 0.8
		mat_gold.roughness = 0.25
		mat_gold.emission_enabled = true
		mat_gold.emission = Color(0.9, 0.7, 0.1)
		mat_gold.emission_energy_multiplier = 0.3
		sack.material_override = mat_gold
		gold_sack.add_child(sack)
		gold_sack.visible = false
		back.add_child(gold_sack)

	# 5. Hierro ("iron"): Carga de lingotes / mineral
	if not back.has_node("iron"):
		var iron_cargo := Node3D.new()
		iron_cargo.name = "iron"
		var ingots := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.32, 0.26, 0.30)
		ingots.mesh = box
		var mat_iron := StandardMaterial3D.new()
		mat_iron.albedo_color = Color(0.32, 0.34, 0.38)
		mat_iron.metallic = 0.85
		mat_iron.roughness = 0.4
		ingots.material_override = mat_iron
		iron_cargo.add_child(ingots)
		iron_cargo.visible = false
		back.add_child(iron_cargo)

## Actualiza la herramienta sostenida en la mano derecha según la actividad o recurso.
func update_hand_tool_visual(tool_type: String) -> void:
	# Mapeo de herramientas según la acción/recurso: "axe", "pickaxe", "hammer", "spear", "Maza_Piedra"
	set_hand_prop(tool_type)

## Actualiza el fardo/cesta visual cargado en la espalda según el recurso recolectado.
func update_back_prop_visual() -> void:
	if carried_amount <= 0 or carried_resource_type.is_empty():
		set_back_prop("")
		return
		
	match carried_resource_type.to_lower():
		"wood":
			set_back_prop("wood")   # Atado de madera
		"food":
			set_back_prop("food")   # Cesta de carne de caza
		"stone":
			set_back_prop("stone")  # Saco de piedra
		"iron":
			set_back_prop("iron")   # Saco de hierro
		"gold":
			set_back_prop("gold")   # Saco de oro
		_:
			set_back_prop(carried_resource_type)

var last_resource_node: Node3D = null
var last_resource_type: String = ""
var last_building_node: Node3D = null

# ─── Comandos de Aldeano ───────────────────────────────────────────────────────

## Ordena recolectar un nodo de recurso 3D o cazar si es fauna viva.
func command_gather(resource_node: Node) -> void:
	if not is_instance_valid(resource_node):
		return
	if resource_node is Node3D:
		last_resource_node = resource_node as Node3D
		if resource_node.has_method("get_resource_type"):
			last_resource_type = resource_node.get_resource_type()

	# Si es fauna viva, ejecutar cacería antes de la extracción de carcasa
	var is_live_fauna: bool = (resource_node is FaunaAnimal3D or resource_node.is_in_group("fauna") or resource_node.is_in_group("animals_3d")) and not (
		("is_animal_dead" in resource_node and resource_node.is_animal_dead) or
		("is_dead" in resource_node and resource_node.is_dead)
	)
	if is_live_fauna:
		command_hunt(resource_node)
		return

	if state_machine:
		state_machine.change_state(&"Gathering", {"target_node": resource_node})

## Ordena cazar un animal salvaje equipando lanza y atacándolo hasta abatirlo.
func command_hunt(animal: Node) -> void:
	if not is_instance_valid(animal):
		return
	if animal is Node3D:
		last_resource_node = animal as Node3D
		last_resource_type = "food"
	update_hand_tool_visual("spear")
	if state_machine:
		state_machine.change_state(&"Attacking", {"target": animal, "is_hunting": true})

## Ordena entregar la carga en un centro de ciudad o asentamiento y luego volver a recolectar.
func command_deposit(town_center: Node) -> void:
	if state_machine:
		state_machine.change_state(&"Move", {
			"target_node": town_center,
			"stopping_distance": 3.0,
			"on_arrival_state": &"Gathering",
			"on_arrival_context": {
				"deposit_target": town_center,
				"target_node": last_resource_node
			}
		})

## Ordena construir/reparar un edificio.
func command_build(building: Node) -> void:
	if is_instance_valid(building) and building is Node3D:
		last_building_node = building as Node3D
	if state_machine:
		state_machine.change_state(&"Building", {"target_node": building})

# ─── Sistema de Stacking de Mejoras Tecnológicas ──────────────────────────────
## Almacena los bonus porcentuales acumulables investigados (ej: "carretilla": 0.15 = +15%).
var tech_gather_bonuses: Dictionary = {}
var tech_capacity_bonuses: Dictionary = {}

## Añade una mejora tecnológica investigada.
func apply_tech_upgrade(tech_id: String, gather_bonus: float = 0.0, capacity_bonus: int = 0) -> void:
	if gather_bonus > 0.0:
		tech_gather_bonuses[tech_id] = gather_bonus
	if capacity_bonus > 0:
		tech_capacity_bonuses[tech_id] = capacity_bonus
	print("Villager3D '%s': Aplicada mejora '%s' (+%.0f%% recolección, +%d capacidad)" % [
		name, tech_id, gather_bonus * 100.0, capacity_bonus
	])

## Calcula la Tasa de Recolección Efectiva Final aplicando la Fórmula de Stacking Híbrida:
## FinalGatherRate = BaseGatherRate * MultiplicadorEra * (1.0 + Suma(BonusTecnologicos))
func get_effective_gather_rate() -> float:
	var sum_tech_bonuses: float = 0.0
	for tech_key in tech_gather_bonuses:
		sum_tech_bonuses += float(tech_gather_bonuses[tech_key])

	var rm: Node = get_node_or_null("/root/ResourceManager")
	var era_mult: float = 1.0
	if is_instance_valid(rm) and "multiplicador_recoleccion" in rm:
		era_mult = float(rm.multiplicador_recoleccion)

	return _gather_rate_base * era_mult * (1.0 + sum_tech_bonuses)

## Retorna la Capacidad Máxima de Carga Efectiva considerando mejoras tecnológicas.
func get_effective_max_capacity() -> int:
	var extra_capacity: int = 0
	for tech_key in tech_capacity_bonuses:
		extra_capacity += int(tech_capacity_bonuses[tech_key])
	return MAX_CARGA + extra_capacity



# ─── Sistema de Protección y Guarecerse (Garrison System & Town Bell) ─────────
var _last_task_context: Dictionary = {}
var _is_garrisoned: bool = false
var _garrison_building: Node3D = null

## Ordena al aldeano guardar su tarea actual e ir a guarecerse al edificio defensivo indicado.
func guarecer_en(edificio: Node3D) -> void:
	if not is_instance_valid(edificio) or is_dead:
		return

	# Guardar el contexto exacto de la tarea actual antes de huir
	_last_task_context = {
		"last_resource_node": last_resource_node,
		"last_resource_type": last_resource_type,
		"last_building_node": last_building_node,
		"carried_amount": carried_amount,
		"carried_resource_type": carried_resource_type,
		"state_name": state_machine.current_state.state_name if (state_machine and state_machine.current_state) else &"Idle"
	}

	_is_garrisoned = false
	_garrison_building = edificio

	set_status_text("🔔 ¡Huyendo a refugio!", 4.0)

	# Navegar hacia el edificio defensivo
	if state_machine:
		state_machine.change_state(&"Move", {
			"target_node": edificio,
			"stopping_distance": 3.0,
			"on_arrival_state": &"Idle",
			"on_arrival_context": {"garrison_target": edificio}
		})

## Ejecuta la entrada física al interior del edificio al llegar.
func entrar_al_refugio() -> void:
	if not is_instance_valid(_garrison_building):
		return
	_is_garrisoned = true
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	if has_node("CollisionShape3D"):
		(get_node("CollisionShape3D") as CollisionShape3D).disabled = true

	# Notificar al edificio para incrementar su guarnición y proyectiles defensivos
	if _garrison_building.has_method("add_garrison_unit"):
		_garrison_building.call("add_garrison_unit", self)

## Restaura automáticamente la última tarea que estaba realizando el aldeano antes de sonar la campana.
func regresar_al_trabajo() -> void:
	if _is_garrisoned:
		_is_garrisoned = false
		visible = true
		process_mode = PROCESS_MODE_INHERIT
		if has_node("CollisionShape3D"):
			(get_node("CollisionShape3D") as CollisionShape3D).disabled = false

		if is_instance_valid(_garrison_building) and _garrison_building.has_method("remove_garrison_unit"):
			_garrison_building.call("remove_garrison_unit", self)
		_garrison_building = null

	set_status_text("🔨 Regresando al trabajo...", 3.0)

	# 1. Si estaba construyendo o reparando un edificio
	var prev_bld: Node3D = _last_task_context.get("last_building_node", null) as Node3D
	var prev_state: StringName = _last_task_context.get("state_name", &"Idle")
	if prev_state == &"Building" and is_instance_valid(prev_bld):
		var dead: bool = bool(prev_bld.get("is_dead")) if "is_dead" in prev_bld else false
		var finished: bool = bool(prev_bld.get("esta_construido")) if "esta_construido" in prev_bld else true
		var hp_cur: float = float(prev_bld.get("salud_actual")) if "salud_actual" in prev_bld else 1.0
		var hp_max: float = float(prev_bld.get("salud_maxima")) if "salud_maxima" in prev_bld else 1.0
		if not dead and (not finished or hp_cur < hp_max):
			command_build(prev_bld)
			return

	# 2. Si tenía inventario lleno, ir a depositar
	if carried_amount > 0 and is_inventory_full():
		if state_machine:
			state_machine.change_state(&"Gathering", {"target_node": last_resource_node})
			return

	# 3. Restaurar recolección previa
	var prev_node: Node3D = _last_task_context.get("last_resource_node", null) as Node3D
	if is_instance_valid(prev_node):
		var is_depleted: bool = prev_node.has_method("is_depleted") and prev_node.is_depleted()
		if not is_depleted:
			command_gather(prev_node)
			return
		else:
			# Si el nodo original se agotó, entrar a Gathering para escanear a 35m
			if state_machine:
				state_machine.change_state(&"Gathering", {"target_node": null, "deposit_target": null})
				return

	if state_machine:
		state_machine.change_state(&"Idle")

# ─── Actualización Visual por Eras y Progresión Pasiva Civil ──────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return

	if self.owner_peer_id != player_id:
		return

	var era_val: int = nueva_era

	# 1. Conmutación de Malla y Atuendo Civil (Mesh Swap)
	_actualizar_modelo_visual_era(era_val)

	# 2. Bufos Incrementales Pasivos Civiles:
	# +5 HP a salud máxima y recuperación inmediata proporcional
	salud_maxima += 5.0
	salud_actual = minf(salud_actual + 5.0, salud_maxima)
	hp_changed.emit(salud_actual, salud_maxima)

	# +5% a velocidad lineal de navegación
	speed *= 1.05

	# +5 unidades a capacidad máxima de recolección en inventario
	MAX_CARGA += 5

	# Actualizar multiplicador de recolección del gestor de recursos
	var mult_rec: float = 1.0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "MULTIPLICADORES_ERA" in rm:
		var mults: Dictionary = rm.get("MULTIPLICADORES_ERA").get(era_val, {})
		mult_rec = float(mults.get("gather_rate", 1.0))
	gather_rate = _gather_rate_base * mult_rec

	set_status_text("✨ Herramientas Mejoradas (Era %d)" % era_val, 3.5)
	print("Villager3D '%s': ✅ Progresión Pasiva aplicada en Era %d → Max HP: %.0f | Vel: %.2f | Carga: %d | Recolección: ×%.1f" % [
		name, era_val, salud_maxima, speed, MAX_CARGA, gather_rate
	])

func _actualizar_modelo_visual_era(era_val: int) -> void:
	var target_key: String = "Primitive_Mesh"
	match era_val:
		0, 1, 2:
			target_key = "Primitive_Mesh"
		3, 4, 5:
			target_key = "Historical_Mesh"
		6, 7:
			target_key = "Industrial_Mesh"
		8, 9:
			target_key = "Futuristic_Mesh"

	var found_specific_mesh := false
	for child in get_children():
		if child is MeshInstance3D and child.name != "UnitPrimitive":
			if child.name.contains(target_key) or child.name.begins_with("EraMesh_%d" % era_val):
				child.visible = true
				found_specific_mesh = true
			elif child.name.ends_with("_Mesh") or child.name.begins_with("EraMesh_"):
				child.visible = false

	# Actualizar la herramienta de mano acorde a la época
	match era_val:
		0: update_hand_tool_visual("axe")
		1: update_hand_tool_visual("stone_axe")
		2: update_hand_tool_visual("bronze_pick")
		3: update_hand_tool_visual("iron_pick")
		4: update_hand_tool_visual("steel_hammer")
		5: update_hand_tool_visual("steel_pick")
		6: update_hand_tool_visual("wrench")
		7: update_hand_tool_visual("welder")
		8: update_hand_tool_visual("laser_tool")
		9: update_hand_tool_visual("nano_tool")

	# Si usa el modelo primitivo o CavemanModel, actualizar material/tinte según la era
	if is_instance_valid(visual_model):
		var mat := StandardMaterial3D.new()
		match era_val:
			0, 1, 2: # Pieles y cuero primitivo
				mat.albedo_color = Color(0.55, 0.40, 0.28)
				mat.roughness = 0.95
			3, 4, 5: # Túnica de lino clásico romano / tela medieval
				mat.albedo_color = Color(0.86, 0.86, 0.82)
				mat.roughness = 0.65
			6, 7: # Ropa de trabajo obrero industrial (azul marino / gris)
				mat.albedo_color = Color(0.25, 0.32, 0.40)
				mat.roughness = 0.50
				mat.metallic = 0.20
			8, 9: # Traje de aleación nanotecnológico / espacial
				mat.albedo_color = Color(0.85, 0.92, 0.98)
				mat.roughness = 0.25
				mat.metallic = 0.85
				mat.emission_enabled = true
				mat.emission = Color(0.2, 0.8, 1.0)
				mat.emission_energy_multiplier = 0.5

		for c in visual_model.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).material_override = mat

	# Si tiene UnitPrimitive, actualizar también
	var prim := get_node_or_null("UnitPrimitive") as MeshInstance3D
	if is_instance_valid(prim) and not found_specific_mesh:
		var prim_mat := StandardMaterial3D.new()
		match era_val:
			0, 1, 2: prim_mat.albedo_color = Color(0.60, 0.45, 0.30)
			3, 4, 5: prim_mat.albedo_color = Color(0.35, 0.50, 0.75)
			6, 7: prim_mat.albedo_color = Color(0.30, 0.38, 0.45)
			8, 9:
				prim_mat.albedo_color = Color(0.85, 0.95, 1.0)
				prim_mat.emission_enabled = true
				prim_mat.emission = Color(0.0, 0.7, 1.0)
				prim_mat.emission_energy_multiplier = 0.6
		prim.material_override = prim_mat
