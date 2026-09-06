## Camion_Industrial — Transporte de Personal Mecanizado a Vapor (Edad Industrial / Era 6).
##
## Vehículo terrestre a vapor con capacidad de guarecer hasta 6 unidades de infantería.
## Duplica su velocidad al transitar por caminos (5.0 m/s -> 10.0 m/s).
## Desembarca síncronamente a los ocupantes en abanico perimetral vía RPC.
class_name Camion_Industrial
extends "res://scripts/units/soldier_3d.gd"

signal unidades_guarecidas_cambiadas(count: int, max_cap: int)
signal desembarque_ejecutado(unidades: Array[Node3D])

var garrison_array: Array[Node3D] = []
var max_garrison: int = 6
var speed_base: float = 5.0
var en_camino: bool = false
var is_vehicle: bool = true

func _init() -> void:
	unit_id = "camion_industrial"
	unit_name = "Camión Industrial"
	attack_type = "melee"
	weapon_type = "none"
	impact_type = "NONE"
	is_cavalry = true
	_salud_base = 320.0
	salud_maxima = 320.0
	salud_actual = 320.0
	_daño_base = 0.0
	daño = 0.0
	rango_ataque = 0.0
	velocidad_ataque = 1.0
	speed_base = 5.0
	speed = speed_base
	era_entrenada = 6

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("transports")
	add_to_group("transports_3d")
	add_to_group("vehicles")
	add_to_group("vehicles_3d")
	add_to_group("units_3d")
	_setup_camion_visuals()

func _setup_camion_visuals() -> void:
	if not has_node("TruckCabin"):
		var cabin := MeshInstance3D.new()
		cabin.name = "TruckCabin"
		var box := BoxMesh.new()
		box.size = Vector3(2.0, 1.8, 1.6)
		cabin.mesh = box
		cabin.position = Vector3(0.0, 1.2, -1.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.24, 0.28, 0.32) # Gris vapor industrial
		mat.metallic = 0.6
		cabin.material_override = mat
		add_child(cabin)

	if not has_node("TruckBed"):
		var bed := MeshInstance3D.new()
		bed.name = "TruckBed"
		var box_b := BoxMesh.new()
		box_b.size = Vector3(2.2, 1.4, 2.8)
		bed.mesh = box_b
		bed.position = Vector3(0.0, 1.0, 0.9)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.38, 0.26, 0.16) # Bancos de madera y lona
		bed.material_override = mat_b
		add_child(bed)

## Guarece una unidad de infantería dentro del vehículo (máximo 6)
func guarecer_unidad(unit: Node3D) -> bool:
	if not is_instance_valid(unit) or is_dead:
		return false
	if garrison_array.size() >= max_garrison:
		return false

	var es_infante: bool = unit.is_in_group("infantry_3d") or unit is Soldier3D or unit.is_in_group("military_units")
	if not es_infante:
		return false

	garrison_array.append(unit)
	unit.visible = false
	unit.set_process(false)
	unit.set_physics_process(false)
	unidades_guarecidas_cambiadas.emit(garrison_array.size(), max_garrison)
	return true

## Desembarque de unidades en abanico perimetral síncrono
func desembarcar_unidades() -> Array[Node3D]:
	var desembarcadas: Array[Node3D] = []
	var count: int = garrison_array.size()
	if count == 0:
		return desembarcadas

	var truck_pos: Vector3 = global_position if is_inside_tree() else position
	for i in range(count):
		var unit: Node3D = garrison_array[i]
		if is_instance_valid(unit):
			# Protocolo radial en abanico a 2.5m del camión
			var angle: float = (float(i) / float(max(1, count))) * TAU
			var offset := Vector3(cos(angle) * 2.5, 0.0, sin(angle) * 2.5)
			if unit.is_inside_tree():
				unit.global_position = truck_pos + offset
			else:
				unit.position = truck_pos + offset
			unit.visible = true
			unit.set_process(true)
			unit.set_physics_process(true)
			desembarcadas.append(unit)

	garrison_array.clear()
	unidades_guarecidas_cambiadas.emit(0, max_garrison)
	desembarque_ejecutado.emit(desembarcadas)
	return desembarcadas

## RPC de desembarque síncrono para red
@rpc("any_peer", "call_local")
func desembarcar_rpc() -> void:
	desembarcar_unidades()

## Aplica bonificación de velocidad al transitar sobre caminos (duplica velocidad)
func aplicar_bonus_camino(sobre_camino: bool) -> void:
	en_camino = sobre_camino
	if en_camino:
		speed = speed_base * 2.0
	else:
		speed = speed_base
