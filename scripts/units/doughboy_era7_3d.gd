## Doughboy_Infanteria_Era7 — Infante de Trinchera (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## Infantería de trinchera con impacto balístico 'GUN' y daño base de 30.0.
## Incorpora resistencia innata en la FSM: mitiga un 20% del daño balístico si se encuentra
## en reposo / Idle simulando resguardo en parapeto o trinchera (aplicar_mitigacion_trinchera).
class_name Doughboy_Infanteria_Era7
extends "res://scripts/units/soldier_3d.gd"

var esta_en_trinchera: bool = true

func _init() -> void:
	unit_id = "doughboy_era7"
	unit_name = "Doughboy de Trinchera"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 190.0
	salud_maxima = 190.0
	salud_actual = 190.0
	_daño_base = 30.0
	daño = 30.0
	rango_ataque = 22.0
	velocidad_ataque = 1.6
	speed = 4.3
	era_entrenada = 7

func _ready() -> void:
	super._ready()
	add_to_group("doughboys")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_doughboy_visuals()

func _setup_doughboy_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.25, 1.2, -1.0)
		add_child(muzzle)

	if not has_node("BrodieHelmet"):
		var helmet := MeshInstance3D.new()
		helmet.name = "BrodieHelmet"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.42
		cyl.height = 0.16
		helmet.mesh = cyl
		helmet.position = Vector3(0.0, 1.7, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.32, 0.35, 0.24) # Verde caqui militar
		mat.metallic = 0.5
		helmet.material_override = mat
		add_child(helmet)

	if not has_node("SpringfieldRifle"):
		var rifle := MeshInstance3D.new()
		rifle.name = "SpringfieldRifle"
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.1, 1.3)
		rifle.mesh = box
		rifle.position = Vector3(0.25, 1.15, -0.4)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.26, 0.18, 0.12)
		rifle.material_override = mat_r
		add_child(rifle)

## Determina si la unidad está en reposo o a resguardo en trinchera
func esta_en_idle_trinchera() -> bool:
	return velocity.length_squared() < 0.1 or postura_actual == Postura.MANTENER_TERRENO or esta_en_trinchera

## Aplica la mitigación innata del -20% a proyectiles balísticos en reposo
func aplicar_mitigacion_trinchera(dano_entrante: float, tipo_arma: String = "gun") -> float:
	var w := tipo_arma.to_lower()
	var es_balistico: bool = w in ["gun", "bullet", "rifle", "machinegun", "arrow", "crossbow", "gatling"]
	if esta_en_idle_trinchera() and es_balistico:
		return dano_entrante * 0.80 # Mitigación del 20%
	return dano_entrante
