## Wonder_Catedral_Gotica_Era4 — Gran Catedral Gótica / Maravilla Monumental (Edad Medieval / Era 4).
##
## Hereda directamente de Wonder3D. Requiere un costo colosal de madera, comida y oro.
## Al completarse, inicia el cronómetro síncrono por RPC fiable de 10 minutos para la victoria por Maravilla.
class_name Wonder_Catedral_Gotica_Era4
extends "res://scripts/buildings/wonder_3d.gd"

var costo_construccion: Dictionary = {
	"wood": 1200,
	"food": 1000,
	"gold": 1500
}

func _init() -> void:
	super._init()
	building_name = "Gran Catedral Gótica"
	salud_maxima = 3500.0
	salud_actual = 3500.0
	radio_vision = 50.0

func _ready() -> void:
	super._ready()
	add_to_group("cathedrals")
	_setup_cathedral_visuals()

func _setup_cathedral_visuals() -> void:
	if not has_node("CathedralMainSpire"):
		var spire := MeshInstance3D.new()
		spire.name = "CathedralMainSpire"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 1.8
		cyl.height = 14.0
		spire.mesh = cyl
		spire.position = Vector3(0.0, 7.0, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.70, 0.68) # Piedra labrada gótica
		mat.roughness = 0.7
		spire.material_override = mat
		add_child(spire)

	if not has_node("CathedralBase"):
		var base_m := MeshInstance3D.new()
		base_m.name = "CathedralBase"
		var box := BoxMesh.new()
		box.size = Vector3(8.0, 5.0, 12.0)
		base_m.mesh = box
		base_m.position = Vector3(0.0, 2.5, 0.0)
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.58, 0.56, 0.54)
		base_m.material_override = mat_b
		add_child(base_m)
