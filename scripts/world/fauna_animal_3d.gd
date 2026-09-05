## FaunaAnimal3D — Fauna Salvaje Evolutiva 3D (GDScript 2.0 / Godot 4).
##
## Animales de cacería y fauna agresiva que mutan visual y estadísticamente según la Era:
## - Eras 0-2 (Primitiva): Ciervo Pasivo / Dientes de Sable Agresivo (40 HP).
## - Eras 3-6 (Histórica): Jabalí Pasivo / Oso Pardo Agresivo (80 HP).
## - Eras 7-9 (Futurista): Ciber-Lobo Mutante Agresivo (150 HP).

class_name FaunaAnimal3D
extends ResourceNode3D

signal animal_attacked(target: Node3D, damage: float)
signal animal_died()

@export var is_aggressive: bool = false
@export var era_bloque: int = 0
@export var animal_health: float = 40.0
@export var attack_damage: float = 6.0
@export var attack_range: float = 2.0
@export var scan_radius: float = 6.0

var is_animal_dead: bool = false
var is_dead: bool:
	get: return is_animal_dead
	set(v): is_animal_dead = v

var salud_actual: float:
	get: return animal_health
	set(v): animal_health = v

var resource_value: int:
	get: return max_amount
	set(v):
		max_amount = v
		current_amount = v

var is_fleeing: bool = false
var flee_speed: float = 8.0

var target_villager: Node3D = null
var _scan_timer: float = 0.0

func _ready() -> void:
	resource_type = "food"
	max_amount = 400
	current_amount = 400
	add_to_group("fauna")
	add_to_group("animals_3d")
	add_to_group("fauna_3d")
	add_to_group("wild_creatures")

	_ensure_fauna_mesh()

	super._ready() if super.has_method("_ready") else null

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
		_aplicar_mutacion_era(int(rm.get("era_actual")))

func _ensure_fauna_mesh() -> void:
	var has_mesh: bool = false
	for child in get_children():
		if child is MeshInstance3D:
			has_mesh = true
			break

	if not has_mesh:
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Primitive_Mesh"
		var box := BoxMesh.new()
		box.size = Vector3(1.4, 1.2, 2.2) if is_aggressive else Vector3(1.0, 1.0, 1.6)
		mesh_inst.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.60, 0.25, 0.15) if is_aggressive else Color(0.55, 0.40, 0.25)
		mesh_inst.material_override = mat
		add_child(mesh_inst)

func _process(delta: float) -> void:
	if is_animal_dead:
		return

	# Comportamiento de Gacela: Huye velozmente a 8.0 m/s ante la presencia de cualquier unidad
	if especie_id == "gacela":
		_procesar_huida_gacela(delta)
		return

	if is_aggressive:
		_scan_timer += delta
		if _scan_timer >= 0.5:
			_scan_timer = 0.0
			_scan_for_nearby_villagers()

		if is_instance_valid(target_villager):
			_atacar_objetivo(delta)

func _procesar_huida_gacela(delta: float) -> void:
	var threat_found: Node3D = null
	var min_dist: float = 12.0

	var potential_threats: Array = []
	if is_inside_tree() and get_tree():
		potential_threats = get_tree().get_nodes_in_group("units_3d") + get_tree().get_nodes_in_group("villagers") + get_tree().get_nodes_in_group("military_units") + get_tree().get_nodes_in_group("player_units")
	if get_parent():
		for child in get_parent().get_children():
			if child not in potential_threats:
				potential_threats.append(child)

	var my_pos: Vector3 = global_position if is_inside_tree() else position

	for u in potential_threats:
		if is_instance_valid(u) and u is Node3D and u != self:
			var u3d := u as Node3D
			# Filtrar solo unidades o aldeanos (ignorar otros animales o edificios)
			if u3d.is_in_group("fauna") or u3d is FaunaAnimal3D or u3d.is_in_group("buildings") or u3d.is_in_group("walls_3d"):
				continue
			var u_pos: Vector3 = u3d.global_position if u3d.is_inside_tree() else u3d.position
			var d := my_pos.distance_to(u_pos)
			if d < min_dist:
				min_dist = d
				threat_found = u3d

	if is_instance_valid(threat_found):
		is_fleeing = true
		var t_pos: Vector3 = threat_found.global_position if threat_found.is_inside_tree() else threat_found.position
		var flee_dir := (my_pos - t_pos)
		flee_dir.y = 0.0
		if flee_dir.length_squared() < 0.001:
			flee_dir = Vector3(-1.0, 0.0, 0.0)
		else:
			flee_dir = flee_dir.normalized()

		position += flee_dir * flee_speed * delta
		if is_inside_tree():
			global_position = position
			if flee_dir.length_squared() > 0.001:
				look_at(global_position + flee_dir, Vector3.UP)
	else:
		is_fleeing = false

func _scan_for_nearby_villagers() -> void:
	if is_instance_valid(target_villager) and global_position.distance_to(target_villager.global_position) <= scan_radius * 1.5:
		return # Mantener presa actual

	target_villager = null
	var min_dist := scan_radius

	for v in get_tree().get_nodes_in_group("villagers") + get_tree().get_nodes_in_group("player_units"):
		if is_instance_valid(v) and v is Node3D and not (v.has_method("is_dead") and v.call("is_dead")):
			var dist := global_position.distance_to((v as Node3D).global_position)
			if dist <= min_dist:
				min_dist = dist
				target_villager = v as Node3D

func _atacar_objetivo(delta: float) -> void:
	if not is_instance_valid(target_villager):
		return

	var dist := global_position.distance_to(target_villager.global_position)
	var move_spd: float = 4.8 if especie_id == "bisonte" else 3.5
	if dist > attack_range:
		global_position = global_position.move_toward(target_villager.global_position, move_spd * delta)
		look_at(Vector3(target_villager.global_position.x, global_position.y, target_villager.global_position.z), Vector3.UP)
	else:
		if target_villager.has_method("recibir_daño"):
			target_villager.call("recibir_daño", attack_damage * delta, self)
			animal_attacked.emit(target_villager, attack_damage * delta)

func recibir_daño_caceria(damage_amount: float, attacker: Node = null) -> void:
	if is_animal_dead:
		return

	# Comportamiento reactivo de Bisonte / Jabalí: Embestida de contraataque si es atacado
	if (especie_id == "bisonte" or especie_id == "jabali") and is_instance_valid(attacker) and attacker is Node3D:
		target_villager = attacker as Node3D
		is_aggressive = true
		print("FaunaAnimal3D (Bisonte): ¡Embestida defensiva activada contra %s!" % attacker.name)

	# Multiplicador x3.0 si el atacante usa lanza de cacería (Aldeano)
	var final_dmg := damage_amount
	if is_instance_valid(attacker) and (attacker.is_in_group("villagers") or (attacker.has_method("command_gather") and not attacker.is_in_group("military_units") and not ("unit_id" in attacker))):
		final_dmg *= 3.0

	animal_health -= final_dmg
	if animal_health <= 0.0:
		_morir_fauna()

func recibir_daño(cantidad: float, atacante: Node = null) -> void:
	recibir_daño_caceria(cantidad, atacante)

func take_damage(amount: int, source: Node = null) -> void:
	recibir_daño_caceria(float(amount), source)

func _morir_fauna() -> void:
	is_animal_dead = true
	animal_health = 0.0
	is_aggressive = false
	print("FaunaAnimal3D '%s': Animal cazado. Carcasa lista para extracción de carne." % name)
	animal_died.emit()

## Extinción biológica natural disparada por el avance tecnológico de la civilización cercana
func morir_por_extincion() -> void:
	if is_animal_dead:
		return
	is_animal_dead = true
	is_aggressive = false
	target_villager = null

	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true

	# Efecto de partículas de polvo / fósil
	var dust := CPUParticles3D.new()
	dust.name = "DustExtinctionParticles"
	dust.emitting = true
	dust.one_shot = true
	dust.amount = 24
	dust.lifetime = 1.2
	dust.explosiveness = 0.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 1.2
	dust.gravity = Vector3(0.0, 0.4, 0.0)
	dust.color = Color(0.72, 0.65, 0.52, 0.85)
	add_child(dust)

	# Animación de disolución
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.9)
	tw.chain().tween_callback(func() -> void:
		queue_free()
	)

# ─── Catálogo Oficial Empire Earth (dbanimals.dat) ───────────────────────────
const CATALOGO_ANIMALES_EE: Dictionary = {
	"ciervo":    { "name": "Ciervo Salvaje", "food": 100, "hp": 30.0, "aggro": false, "era_min": 0, "era_max": 3, "dmg": 0.0, "size": Vector3(1.0, 1.1, 1.4), "color": Color(0.55, 0.40, 0.22) },
	"caballo":   { "name": "Caballo Salvaje", "food": 120, "hp": 45.0, "aggro": false, "era_min": 1, "era_max": 5, "dmg": 0.0, "size": Vector3(1.2, 1.3, 1.8), "color": Color(0.48, 0.32, 0.16) },
	"cabra":     { "name": "Cabra Montés", "food": 120, "hp": 35.0, "aggro": false, "era_min": 0, "era_max": 4, "dmg": 0.0, "size": Vector3(0.9, 0.9, 1.2), "color": Color(0.65, 0.60, 0.50) },
	"pollo":     { "name": "Ave Silvestre", "food": 90, "hp": 15.0, "aggro": false, "era_min": 0, "era_max": 9, "dmg": 0.0, "size": Vector3(0.5, 0.5, 0.6), "color": Color(0.80, 0.45, 0.20) },
	"mamut":     { "name": "Mamut Lanudo Ancestral", "food": 600, "hp": 240.0, "aggro": false, "era_min": 0, "era_max": 2, "dmg": 15.0, "size": Vector3(2.4, 2.2, 3.2), "color": Color(0.38, 0.28, 0.20) },
	"bisonte":   { "name": "Bisonte Salvaje", "food": 450, "hp": 180.0, "aggro": false, "era_min": 1, "era_max": 4, "dmg": 14.0, "size": Vector3(1.7, 1.4, 2.3), "color": Color(0.36, 0.22, 0.12) },
	"gacela":    { "name": "Gacela", "food": 100, "hp": 25.0, "aggro": false, "era_min": 1, "era_max": 4, "dmg": 0.0, "size": Vector3(0.8, 1.0, 1.2), "color": Color(0.72, 0.52, 0.32) },
	"tigre":     { "name": "Tigre Dientes de Sable", "food": 300, "hp": 120.0, "aggro": true, "era_min": 0, "era_max": 2, "dmg": 16.0, "size": Vector3(1.4, 1.2, 2.0), "color": Color(0.75, 0.42, 0.12) },
	"lobo":      { "name": "Lobo Feroz", "food": 120, "hp": 60.0, "aggro": true, "era_min": 0, "era_max": 5, "dmg": 8.0, "size": Vector3(1.1, 1.0, 1.5), "color": Color(0.35, 0.35, 0.35) },
	"jabali":    { "name": "Jabalí Salvaje", "food": 250, "hp": 80.0, "aggro": false, "era_min": 2, "era_max": 6, "dmg": 10.0, "size": Vector3(1.3, 1.0, 1.7), "color": Color(0.32, 0.24, 0.18) },
	"oso":       { "name": "Oso Pardo de Bosque", "food": 400, "hp": 150.0, "aggro": true, "era_min": 3, "era_max": 6, "dmg": 18.0, "size": Vector3(1.8, 1.6, 2.4), "color": Color(0.40, 0.25, 0.15) },
	"ciber_lobo":{ "name": "Ciber-Lobo Mutante", "food": 500, "hp": 200.0, "aggro": true, "era_min": 7, "era_max": 9, "dmg": 24.0, "size": Vector3(1.5, 1.4, 2.2), "color": Color(0.20, 0.65, 0.85) }
}

@export var especie_id: String = "ciervo"

func configurar_especie(id_esp: String) -> void:
	if not CATALOGO_ANIMALES_EE.has(id_esp):
		id_esp = "ciervo"
	especie_id = id_esp
	var data: Dictionary = CATALOGO_ANIMALES_EE[id_esp]

	max_amount = int(data.get("food", 100))
	current_amount = max_amount
	animal_health = float(data.get("hp", 40.0))
	is_aggressive = bool(data.get("aggro", false))
	attack_damage = float(data.get("dmg", 6.0))
	name = str(data.get("name", "AnimalSalvaje")).replace(" ", "_")

	# Ajustar tamaño y color visual
	var mesh_node: MeshInstance3D = get_node_or_null("Primitive_Mesh") as MeshInstance3D
	if not is_instance_valid(mesh_node):
		_ensure_fauna_mesh()
		mesh_node = get_node_or_null("Primitive_Mesh") as MeshInstance3D

	if is_instance_valid(mesh_node):
		var sz: Vector3 = data.get("size", Vector3(1.0, 1.0, 1.5))
		if mesh_node.mesh is BoxMesh:
			(mesh_node.mesh as BoxMesh).size = sz
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.get("color", Color(0.5, 0.4, 0.3))
		mesh_node.material_override = mat

# ─── Mutaciones Biológicas y Mallas 3D por Eras ─────────────────────────────

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var era_val: int = 0
	if nueva_era != null and nueva_era is int:
		era_val = int(nueva_era)
	elif player_id_or_era != null:
		era_val = int(player_id_or_era)
	_aplicar_mutacion_era(era_val)

func _aplicar_mutacion_era(era: int) -> void:
	match era:
		0: # Era 0 (Prehistoria): Mamuts ancestrales, Tigres Dientes de Sable, Ciervos
			if is_aggressive:
				configurar_especie("tigre")
			else:
				if especie_id == "mamut" or randf() < 0.4:
					configurar_especie("mamut")
				else:
					configurar_especie("ciervo")
		1: # Era 1 (Edad de Piedra): Bisontes Salvajes, Gacelas veloces, Lobos
			if is_aggressive:
				configurar_especie("lobo")
			else:
				if randf() < 0.6:
					configurar_especie("bisonte")
				else:
					configurar_especie("gacela")
		2: # Era 2 (Cobre)
			if is_aggressive:
				configurar_especie("lobo")
			else:
				configurar_especie("ciervo")
		3, 4, 5, 6: # Eras Históricas: Osos Pardos, Jabalíes, Caballos
			if is_aggressive:
				configurar_especie("oso")
			else:
				if randf() < 0.5:
					configurar_especie("jabali")
				else:
					configurar_especie("caballo")
		7, 8, 9: # Eras Futuristas: Ciber-Lobos Mutantes
			configurar_especie("ciber_lobo")

# ─── Extinción y Reemplazo de Fauna por RPC ──────────────────────────────────

## Extinción esférica de 80m que purga los Mamuts locales y los reemplaza por fauna de Era 1 (Bisontes y Gacelas)
@rpc("any_peer", "call_local", "reliable")
func rpc_reemplazar_fauna_extinta(center: Vector3, radius: float = 80.0) -> Array[Node3D]:
	return reemplazar_fauna_extinta(center, radius)

func reemplazar_fauna_extinta(center: Vector3, radius: float = 80.0) -> Array[Node3D]:
	var nuevas_unidades: Array[Node3D] = []

	var parent: Node = get_parent()
	if not is_instance_valid(parent):
		if is_inside_tree() and get_tree() and get_tree().current_scene:
			parent = get_tree().current_scene
		else:
			parent = self

	var candidates: Array = []
	if is_inside_tree() and get_tree():
		candidates = get_tree().get_nodes_in_group("fauna") + get_tree().get_nodes_in_group("animals_3d")
	if is_instance_valid(parent):
		for child in parent.get_children():
			if child not in candidates:
				candidates.append(child)

	var mamuts_encontrados: Array[Node] = []
	for node in candidates:
		if is_instance_valid(node) and node is Node3D and node != self and node not in mamuts_encontrados:
			var n3d := node as Node3D
			var n_pos: Vector3 = n3d.global_position if n3d.is_inside_tree() else n3d.position
			if n_pos.distance_to(center) <= radius:
				var esp := str(n3d.get("especie_id")).to_lower() if "especie_id" in n3d else ""
				if esp == "mamut" or "mamut" in n3d.name.to_lower():
					mamuts_encontrados.append(n3d)

	var spawn_bison := true
	for m in mamuts_encontrados:
		var m3d := m as Node3D
		var spawn_pos: Vector3 = m3d.global_position if m3d.is_inside_tree() else m3d.position
		if m.has_method("morir_por_extincion"):
			m.call("morir_por_extincion")
		else:
			m.queue_free()

		var nuevo := FaunaAnimal3D.new()
		parent.add_child(nuevo)
		nuevo.position = spawn_pos
		if nuevo.is_inside_tree():
			nuevo.global_position = spawn_pos
		if spawn_bison:
			nuevo.configurar_especie("bisonte")
		else:
			nuevo.configurar_especie("gacela")
		spawn_bison = !spawn_bison
		nuevas_unidades.append(nuevo)

	print("FaunaAnimal3D: Extinción esférica (%.1fm) ejecutada: %d Mamuts reemplazados por fauna de Era 1." % [
		radius, mamuts_encontrados.size()
	])
	return nuevas_unidades

## Invocación estática universal para controladores y tests headless
static func reemplazar_fauna_extinta_global(tree_node: Node, center: Vector3, radius: float = 80.0) -> Array[Node3D]:
	var dummy := FaunaAnimal3D.new()
	if is_instance_valid(tree_node):
		tree_node.add_child(dummy)
		var res: Array[Node3D] = dummy.reemplazar_fauna_extinta(center, radius)
		dummy.queue_free()
		return res
	return []
