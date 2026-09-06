## Hussar_Era6 — Húsar a Caballo (Edad Industrial / Era 6).
##
## Caballería ligera ultra veloz (velocidad base 6.8 m/s).
## Tipo de impacto 'Slashing' / 'MELEE_SHOCK'. Multiplicador de x1.40 contra fusileros
## y unidades de rango desprotegidas. Maniobra táctica de flanqueo envolvente a ±65°.
class_name Hussar_Era6
extends "res://scripts/units/soldier_3d.gd"

signal flanqueo_iniciado(target_pos: Vector3, angulo_deg: float)

func _init() -> void:
	unit_id = "hussar_era6"
	unit_name = "Húsar a Caballo"
	attack_type = "melee"
	weapon_type = "sword"
	impact_type = "Slashing"
	is_cavalry = true
	_salud_base = 230.0
	salud_maxima = 230.0
	salud_actual = 230.0
	_daño_base = 26.0
	daño = 26.0
	rango_ataque = 3.2
	velocidad_ataque = 0.8
	speed = 6.8
	era_entrenada = 6

func _ready() -> void:
	super._ready()
	add_to_group("hussars")
	add_to_group("cavalry")
	add_to_group("light_cavalry")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_hussar_visuals()

func _setup_hussar_visuals() -> void:
	if not has_node("SaberBlade"):
		var saber := MeshInstance3D.new()
		saber.name = "SaberBlade"
		var box := BoxMesh.new()
		box.size = Vector3(0.04, 0.08, 0.9)
		saber.mesh = box
		saber.position = Vector3(0.4, 1.1, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.92, 0.95)
		mat.metallic = 0.95
		mat.roughness = 0.2
		saber.material_override = mat
		add_child(saber)

	if not has_node("HorseBody"):
		var horse := MeshInstance3D.new()
		horse.name = "HorseBody"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(0.7, 0.9, 1.7)
		horse.mesh = box_h
		horse.position = Vector3(0.0, 0.7, 0.0)
		var mat_h := StandardMaterial3D.new()
		mat_h.albedo_color = Color(0.35, 0.22, 0.14) # Caballo castaño
		horse.material_override = mat_h
		add_child(horse)

## Calcula la posición táctica de flanqueo envolvente a ±65 grados respecto al objetivo
func calcular_posicion_flanqueo(target_pos: Vector3, distancia: float = 3.0, lado: int = 1) -> Vector3:
	var ang_deg: float = 65.0 * signf(lado if lado != 0 else 1)
	var ang_rad: float = deg_to_rad(ang_deg)
	var dir: Vector3 = (position - target_pos).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	var dir_flanqueo: Vector3 = dir.rotated(Vector3.UP, ang_rad)
	var dest: Vector3 = target_pos + dir_flanqueo * distancia
	flanqueo_iniciado.emit(dest, ang_deg)
	return dest
