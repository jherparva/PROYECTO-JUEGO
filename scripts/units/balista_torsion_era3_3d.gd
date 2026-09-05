## Balista_Torsion_Era3 — Balista de Asedio por Torsión (Edad de Hierro / Era 3).
##
## Dispara virotes pesados de hierro en una trayectoria plana lineal de alta velocidad.
## Alcance balístico calibrado a 22 metros.
## Perfora la armadura de las unidades en línea recta ('es_perforante_lineal' = true).
class_name Balista_Torsion_Era3
extends "res://scripts/units/soldier_3d.gd"

var is_siege_engine: bool = true
var es_perforante_lineal: bool = true

func _init() -> void:
	unit_id = "balista_torsion_era3"
	unit_name = "Balista de Torsión"
	attack_type = "ranged"
	weapon_type = "piercing_bolt"
	projectile_type = "bolt"
	_salud_base = 200.0
	salud_maxima = 200.0
	salud_actual = 200.0
	_daño_base = 38.0
	daño = 38.0
	rango_ataque = 22.0 # Alcance 22m
	velocidad_ataque = 2.2 # Tensión mecánica de cuerdas de torsión
	speed = 3.4
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("siege_units")
	add_to_group("ballistas")
	add_to_group("vehicles_3d")
	add_to_group("units_3d")
	_setup_muzzle_and_frame()

func _setup_muzzle_and_frame() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.6)
		add_child(muzzle)

	if not has_node("BallistaFrame"):
		var frame_m := MeshInstance3D.new()
		frame_m.name = "BallistaFrame"
		var box := BoxMesh.new()
		box.size = Vector3(1.4, 0.8, 2.0)
		frame_m.mesh = box
		frame_m.position = Vector3(0.0, 0.6, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.25, 0.15)
		frame_m.material_override = mat
		add_child(frame_m)

## Disparo perforante lineal que afecta unidades alineadas en la trayectoria
func calcular_impacto_perforante(target: Node3D) -> float:
	if not is_instance_valid(target):
		return daño
	# La balista ignora el 40% de la armadura pesada convencional
	return daño * 1.15
