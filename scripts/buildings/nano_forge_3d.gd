## NanoForge3D — Forja Nano-Molecular / Inyector de Plasma (Edad Nano-Futurista / Era 11).
##
## Estructura con reactores de fusión fría que emerge verticalmente desde el 8% de altura.
## Hereda directamente de Barracks3D y se encarga del ensamblaje del coloso PlasmaMech.
class_name NanoForge3D
extends "res://scripts/buildings/barracks_3d.gd"

@export var building_type: String = "nano_forge"

func _init() -> void:
	super._init()
	building_name = "Forja Nano-Molecular"
	salud_maxima = 3200.0
	salud_actual = 3200.0
	_salud_maxima_base = 3200.0
	radio_vision = 48.0

func _ready() -> void:
	super._ready()
	building_name = "Forja Nano-Molecular"
	add_to_group("nano_forges")
	add_to_group("military_buildings")
	_setup_nano_forge_visuals()

func _setup_nano_forge_visuals() -> void:
	if not has_node("ForgeMainCore"):
		var core := MeshInstance3D.new()
		core.name = "ForgeMainCore"
		var box := BoxMesh.new()
		box.size = Vector3(7.0, 3.2, 7.0)
		core.mesh = box
		core.position = Vector3(0.0, 1.6, 0.0)
		var mat_c := StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.1, 0.12, 0.16) # Titanio ultra-denso
		mat_c.metallic = 0.95
		mat_c.roughness = 0.15
		core.material_override = mat_c
		add_child(core)

	if not has_node("FusionReactorLeft"):
		var react_l := MeshInstance3D.new()
		react_l.name = "FusionReactorLeft"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.9
		cyl.bottom_radius = 1.1
		cyl.height = 3.8
		react_l.mesh = cyl
		react_l.position = Vector3(-2.6, 1.9, -2.6)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.0, 0.5, 1.0)
		mat_r.emission_enabled = true
		mat_r.emission = Color(0.0, 0.8, 1.0)
		mat_r.emission_energy_multiplier = 3.0
		react_l.material_override = mat_r
		add_child(react_l)

	if not has_node("FusionReactorRight"):
		var react_r := MeshInstance3D.new()
		react_r.name = "FusionReactorRight"
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 0.9
		cyl2.bottom_radius = 1.1
		cyl2.height = 3.8
		react_r.mesh = cyl2
		react_r.position = Vector3(2.6, 1.9, 2.6)
		var mat_r2 := StandardMaterial3D.new()
		mat_r2.albedo_color = Color(0.0, 0.5, 1.0)
		mat_r2.emission_enabled = true
		mat_r2.emission = Color(0.0, 0.8, 1.0)
		mat_r2.emission_energy_multiplier = 3.0
		react_r.material_override = mat_r2
		add_child(react_r)
