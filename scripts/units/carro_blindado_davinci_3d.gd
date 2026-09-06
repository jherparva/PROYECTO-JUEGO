## Carro_Blindado_DaVinci — Vehículo Blindado Cónico de Leonardo (Edad del Renacimiento / Era 5).
##
## Vehículo perimetral cónico de madera reforzada con cañones integrados en 360 grados.
## Dispara ráfagas balísticas en 4 direcciones simultáneas desde sus sockets ('Muzzle_N', 'Muzzle_S', 'Muzzle_E', 'Muzzle_W').
## Cuenta con mitigación pasiva innata del -20% a todo daño físico recibido mediante 'aplicar_mitigacion_blindaje()'.
class_name Carro_Blindado_DaVinci
extends "res://scripts/units/soldier_3d.gd"

signal rafaga_omnidireccional_disparada(direcciones: int)

var porcentaje_mitigacion: float = 0.20 # -20% de daño recibido
var is_vehicle: bool = true

func _init() -> void:
	unit_id = "carro_blindado_davinci"
	unit_name = "Carro Blindado Da Vinci"
	is_cavalry = true
	attack_type = "ranged"
	weapon_type = "cannon"
	impact_type = "SIEGE"
	projectile_type = "bullet"
	_salud_base = 340.0
	salud_maxima = 340.0
	salud_actual = 340.0
	_daño_base = 28.0
	daño = 28.0
	rango_ataque = 16.0
	velocidad_ataque = 2.0
	speed = 3.8
	era_entrenada = 5

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("vehicles")
	add_to_group("vehicles_3d")
	add_to_group("davinci_tanks")
	add_to_group("units_3d")
	_setup_davinci_visuals()

func _setup_davinci_visuals() -> void:
	# 4 Sockets balísticos en cruz (N, S, E, W)
	if not has_node("Muzzle_N"):
		var m_n := Marker3D.new()
		m_n.name = "Muzzle_N"
		m_n.position = Vector3(0.0, 0.8, -1.5)
		add_child(m_n)

	if not has_node("Muzzle_S"):
		var m_s := Marker3D.new()
		m_s.name = "Muzzle_S"
		m_s.position = Vector3(0.0, 0.8, 1.5)
		add_child(m_s)

	if not has_node("Muzzle_E"):
		var m_e := Marker3D.new()
		m_e.name = "Muzzle_E"
		m_e.position = Vector3(1.5, 0.8, 0.0)
		add_child(m_e)

	if not has_node("Muzzle_W"):
		var m_w := Marker3D.new()
		m_w.name = "Muzzle_W"
		m_w.position = Vector3(-1.5, 0.8, 0.0)
		add_child(m_w)

	if not has_node("ConicalHull"):
		var hull := MeshInstance3D.new()
		hull.name = "ConicalHull"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 1.6
		cyl.height = 1.6
		hull.mesh = cyl
		hull.position = Vector3(0.0, 0.9, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.30, 0.18) # Madera de roble reforzada con planchas de hierro
		mat.roughness = 0.8
		hull.material_override = mat
		add_child(hull)

## Dispara ráfagas simultáneas en las 4 direcciones cardinales (N, S, E, W)
func disparar_rafaga_omnidireccional() -> int:
	var sockets: Array[String] = ["Muzzle_N", "Muzzle_S", "Muzzle_E", "Muzzle_W"]
	var count: int = 0
	for s_name in sockets:
		if has_node(s_name):
			count += 1
	rafaga_omnidireccional_disparada.emit(count)
	print("Carro_Blindado_DaVinci '%s': ¡Salva perimetral disparada desde %d troneras simultáneas!" % [name, count])
	return count

## Mitigación pasiva innata del -20% a todo daño físico recibido
func aplicar_mitigacion_blindaje(dano_entrante: float) -> float:
	var dano_mitigado: float = dano_entrante * (1.0 - porcentaje_mitigacion)
	return maxf(1.0, dano_mitigado)
