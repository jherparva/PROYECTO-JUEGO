## Cataphract_Era3 — Catafracta Blindada de Hierro (Edad de Hierro / Era 3).
##
## Caballería pesada acorazada con barda metálica completa para jinete y montura.
## Tipo de impacto: MELEE_SHOCK.
## Calibración: velocidad base 5.5 m/s, resistencia innata contra flechas ligeras (-50% daño).
class_name Cataphract_Era3
extends "res://scripts/units/soldier_3d.gd"

var is_heavy_cavalry: bool = true
var armor_vs_arrows: float = 0.50 # 50% de resistencia pasiva ante proyectiles de flecha

func _init() -> void:
	unit_id = "cataphract_era3"
	unit_name = "Catafracta de Hierro"
	attack_type = "melee"
	weapon_type = "lance"
	impact_type = "MELEE_SHOCK"
	_salud_base = 240.0
	salud_maxima = 240.0
	salud_actual = 240.0
	_daño_base = 26.0
	daño = 26.0
	rango_ataque = 3.6
	velocidad_ataque = 0.95
	speed = 5.5 # Calibración oficial a 5.5 m/s
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("cavalry")
	add_to_group("heavy_cavalry")
	add_to_group("units_3d")
	_setup_armor_visuals()

func _setup_armor_visuals() -> void:
	if not has_node("CataphractBarding"):
		var barding := MeshInstance3D.new()
		barding.name = "CataphractBarding"
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 0.9, 1.8)
		barding.mesh = box
		barding.position = Vector3(0.0, 0.6, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.38, 0.42) # Malla de escamas de hierro
		mat.metallic = 0.9
		mat.roughness = 0.25
		barding.material_override = mat
		add_child(barding)

## Mitigación innata de armadura de placas contra flechas ligeras
func aplicar_mitigacion_catafracta(dano_entrante: float, tipo_arma: String = "arrow") -> float:
	var t: String = tipo_arma.to_lower()
	if t in ["arrow", "flecha", "sling"]:
		return dano_entrante * (1.0 - armor_vs_arrows)
	return dano_entrante
