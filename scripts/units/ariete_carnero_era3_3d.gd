## Ariete_Carnero_Era3 — Ariete de Choque Pesado (Edad de Hierro / Era 3).
##
## Vehículo pesado de asedio con viga suspendida y cabeza de carnero en hierro fundido.
## Tipo de impacto: Bludgeoning.
## Aplica un multiplicador de daño estricto de x3.0 contra estructuras y murallas del grupo 'buildings'.
class_name Ariete_Carnero_Era3
extends "res://scripts/units/soldier_3d.gd"

var is_siege_engine: bool = true
var siege_structure_multiplier: float = 3.0

func _init() -> void:
	unit_id = "ariete_carnero_era3"
	unit_name = "Ariete de Carnero"
	attack_type = "melee"
	weapon_type = "bludgeoning"
	impact_type = "Bludgeoning"
	_salud_base = 380.0
	salud_maxima = 380.0
	salud_actual = 380.0
	_daño_base = 40.0
	daño = 40.0
	rango_ataque = 3.8
	velocidad_ataque = 1.6 # 1 golpe potente cada 1.6s
	speed = 3.2 # Vehículo pesado lento
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("siege_units")
	add_to_group("rams")
	add_to_group("vehicles_3d")
	add_to_group("units_3d")
	_setup_ram_mesh()

func _setup_ram_mesh() -> void:
	if not has_node("RamBody"):
		var body := MeshInstance3D.new()
		body.name = "RamBody"
		var box := BoxMesh.new()
		box.size = Vector3(1.6, 1.4, 3.2)
		body.mesh = box
		body.position = Vector3(0.0, 0.8, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.32, 0.22, 0.14) # Madera pesada tratada
		body.material_override = mat
		add_child(body)

	if not has_node("IronHead"):
		var head := MeshInstance3D.new()
		head.name = "IronHead"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(0.8, 0.8, 0.8)
		head.mesh = box_h
		head.position = Vector3(0.0, 0.7, -1.8)
		var mat_iron := StandardMaterial3D.new()
		mat_iron.albedo_color = Color(0.25, 0.28, 0.32) # Hierro forjado
		mat_iron.metallic = 0.9
		head.material_override = mat_iron
		add_child(head)

## Retorna el daño calculado aplicando el multiplicador oficial x3.0 contra edificios
func calcular_dano_contra(target: Node) -> float:
	var base_dano: float = daño
	if not is_instance_valid(target):
		return base_dano
	if target.is_in_group("buildings") or target.is_in_group("buildings_3d") or target.is_in_group("walls"):
		return base_dano * siege_structure_multiplier
	return base_dano
