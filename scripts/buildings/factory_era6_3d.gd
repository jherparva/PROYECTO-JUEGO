## Factory_Era6 — Factoría Pesada con Chimeneas (Edad Industrial / Era 6).
##
## Estructura industrial masiva que hereda directamente de Barracks3D.
## Se habilita si GlobalResourceManager.era_actual >= 6.
## Produce tanques a vapor y transportes mecanizados.
## Emite partículas continuas de humo negro pesado (IndustrialSmokeParticles) desde sus chimeneas superiores.
## Emerge verticalmente desde el 8% de altura pegado al muro real a 1.2m.
class_name Factory_Era6
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "factory"

func _init() -> void:
	super._init()
	building_name = "Factoría Pesada"
	salud_maxima = 1600.0
	salud_actual = 1600.0
	_salud_maxima_base = 1600.0
	radio_vision = 32.0

func _ready() -> void:
	super._ready()
	add_to_group("factories")
	add_to_group("industrial_buildings")
	_setup_factory_visuals()

func _setup_factory_visuals() -> void:
	if not has_node("FactoryMainHall"):
		var hall := MeshInstance3D.new()
		hall.name = "FactoryMainHall"
		var box := BoxMesh.new()
		box.size = Vector3(6.0, 3.8, 6.0)
		hall.mesh = box
		hall.position = Vector3(0.0, 1.9, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.28, 0.26, 0.25) # Ladrillo oscuro
		hall.material_override = mat_h
		add_child(hall)

	if not has_node("Chimney1"):
		var ch1 := MeshInstance3D.new()
		ch1.name = "Chimney1"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.7
		cyl.height = 4.2
		ch1.mesh = cyl
		ch1.position = Vector3(1.8, 4.8, 1.5)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.2, 0.2, 0.2)
		ch1.material_override = mat_c
		add_child(ch1)

		# Partículas continuas de humo negro pesado (sin lag en hilos locales)
		var smoke := CPUParticles3D.new()
		smoke.name = "IndustrialSmokeParticles"
		smoke.emitting = true
		smoke.amount = 32
		smoke.lifetime = 2.5
		smoke.direction = Vector3.UP
		smoke.spread = 15.0
		smoke.gravity = Vector3(0.2, 1.4, 0.0)
		smoke.initial_velocity_min = 1.5
		smoke.initial_velocity_max = 3.0
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		smoke.mesh = sm
		var sm_mat := StandardMaterial3D.new()
		sm_mat.albedo_color = Color(0.12, 0.12, 0.12, 0.85) # Humo negro pesado
		smoke.material_override = sm_mat
		ch1.add_child(smoke)

	if not has_node("Chimney2"):
		var ch2 := MeshInstance3D.new()
		ch2.name = "Chimney2"
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 0.4
		cyl2.bottom_radius = 0.65
		cyl2.height = 3.8
		ch2.mesh = cyl2
		ch2.position = Vector3(-1.8, 4.6, -1.5)
		var mat_c2 := StandardMaterial3D.new()
		mat_c2.albedo_color = Color(0.2, 0.2, 0.2)
		ch2.material_override = mat_c2
		add_child(ch2)
