## GISoldier_Era8 — Infantería Moderna WWII (Edad Atómica / Era 8).
##
## Infantería armada con fusil semiautomático M1 Garand.
## Posee daño base de 32.0, socket ProjectileMuzzle, cadencia acelerada y
## multiplicador estricto de x1.25 contra infantería ligera de eras pasadas.
class_name GISoldier_Era8
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "gi_soldier_era8"
	unit_name = "Soldado GI WWII"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 210.0
	salud_maxima = 210.0
	salud_actual = 210.0
	_daño_base = 32.0
	daño = 32.0
	rango_ataque = 22.0
	velocidad_ataque = 0.85
	speed = 4.6
	era_entrenada = 8

func _ready() -> void:
	super._ready()
	add_to_group("gi_soldiers")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_gi_visuals()

func _setup_gi_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.6)
		add_child(muzzle)

	if not has_node("HelmetMesh"):
		var helmet := MeshInstance3D.new()
		helmet.name = "HelmetMesh"
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.32
		helmet.mesh = sphere
		helmet.position = Vector3(0.0, 1.75, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.35, 0.22) # Verde oliva militar
		helmet.material_override = mat
		add_child(helmet)
