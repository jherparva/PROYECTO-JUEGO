## Windmill_Era4 — Molino de Viento Agrícola (Edad Medieval / Era 4).
##
## Estructura económica agrícola que hereda de BuildingBase3D.
## Al ser colocado junto a granjas ('Farm3D') aliadas en un radio de 14.0 metros,
## inyecta un modificador pasivo de +15% de velocidad de recolección de comida
## ('gathering_speed_modifier = 1.15') a todos los aldeanos asignados a esas granjas.
class_name Windmill_Era4
extends "res://scripts/buildings/building_base_3d.gd"

signal bufo_agricola_aplicado(granjas_afectadas: int)

@export var radio_bufo: float = 14.0
@export var gathering_speed_modifier: float = 1.15

var _timer_escaneo: float = 0.0
const INTERVALO_ESCANEO: float = 2.0

func _init() -> void:
	building_name = "Molino de Viento"
	salud_maxima = 600.0
	salud_actual = 600.0
	radio_vision = 22.0

func _ready() -> void:
	super._ready()
	add_to_group("windmills")
	add_to_group("economic_buildings")
	_setup_windmill_visuals()
	aplicar_bufo_agricola()

func _process(delta: float) -> void:
	_timer_escaneo += delta
	if _timer_escaneo >= INTERVALO_ESCANEO:
		_timer_escaneo = 0.0
		aplicar_bufo_agricola()

## Aplica el bufo de +15% de velocidad a las granjas aliadas y sus aldeanos dentro del radio de 14.0m
func aplicar_bufo_agricola() -> Array[Node3D]:
	var granjas_beneficiadas: Array[Node3D] = []
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if not is_instance_valid(tree):
		var ml = Engine.get_main_loop()
		if ml is SceneTree:
			tree = ml

	var candidatos: Array[Node] = []
	if is_instance_valid(tree):
		candidatos.append_array(tree.get_nodes_in_group("farms"))
		candidatos.append_array(tree.get_nodes_in_group("farms_3d"))
		if is_instance_valid(tree.root):
			for child in tree.root.get_children():
				if is_instance_valid(child) and child is Node3D and not candidatos.has(child):
					if child.is_in_group("farms") or "farm" in child.name.to_lower() or child.has_method("request_gather_slot"):
						candidatos.append(child)
	elif is_instance_valid(get_parent()):
		for child in get_parent().get_children():
			if is_instance_valid(child) and child is Node3D and not candidatos.has(child):
				if child.is_in_group("farms") or "farm" in child.name.to_lower() or child.has_method("request_gather_slot"):
					candidatos.append(child)

	var mi_pos: Vector3 = position if position != Vector3.ZERO else global_position

	for farm in candidatos:
		if not is_instance_valid(farm) or farm == self:
			continue
		if not (farm is Node3D):
			continue
		var farm_3d := farm as Node3D
		var f_pos: Vector3 = farm_3d.position if farm_3d.position != Vector3.ZERO else farm_3d.global_position
		var dist: float = mi_pos.distance_to(f_pos)

		if dist <= radio_bufo:
			granjas_beneficiadas.append(farm_3d)
			farm_3d.set("gathering_speed_modifier", gathering_speed_modifier)

			# Inyectar al aldeano asignado actualmente a la granja
			var vil = farm_3d.get("assigned_villager")
			if is_instance_valid(vil):
				vil.set("gathering_speed_modifier", gathering_speed_modifier)
				if "gather_rate" in vil and not vil.has_meta("original_gather_rate"):
					vil.set_meta("original_gather_rate", vil.get("gather_rate"))
					vil.set("gather_rate", float(vil.get("gather_rate")) * gathering_speed_modifier)

	if not granjas_beneficiadas.is_empty():
		bufo_agricola_aplicado.emit(granjas_beneficiadas.size())
		print("Windmill_Era4 '%s': Bufo macroeconómico (+15%% comida) inyectado a %d granjas a <= 14m." % [name, granjas_beneficiadas.size()])

	return granjas_beneficiadas

func _setup_windmill_visuals() -> void:
	if not has_node("WindmillBody"):
		var body := MeshInstance3D.new()
		body.name = "WindmillBody"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.2
		cyl.bottom_radius = 1.8
		cyl.height = 5.0
		body.mesh = cyl
		body.position = Vector3(0.0, 2.5, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.70, 0.65, 0.55) # Mampostería y madera
		body.material_override = mat
		add_child(body)

	if not has_node("WindmillBlades"):
		var blades := MeshInstance3D.new()
		blades.name = "WindmillBlades"
		var box_b := BoxMesh.new()
		box_b.size = Vector3(4.8, 0.3, 0.1)
		blades.mesh = box_b
		blades.position = Vector3(0.0, 4.2, -1.3)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.9, 0.9, 0.85) # Aspas de lona blanca
		blades.material_override = mat_b
		add_child(blades)
