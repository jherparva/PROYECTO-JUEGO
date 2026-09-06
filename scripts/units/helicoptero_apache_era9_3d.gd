## Helicoptero_Apache_Era9 — Helicóptero de Ataque AH-64 Apache (Edad Atómica / Era 9).
##
## Unidad aérea táctica de apoyo cercano a baja/media cota (Y = 7.5m).
## Velocidad de 8.0 m/s. Implementa la maniobra de órbita circular activa:
## al fijar un objetivo terrestre activa 'is_orbiting = true', orbitando en un círculo continuo
## alrededor del blanco mientras efectúa descargas de ametralladora rotatoria sin detenerse.
class_name Helicoptero_Apache_Era9
extends "res://scripts/units/soldier_3d.gd"

signal rafaga_orbita_disparada(pos_objetivo: Vector3, impactos: int)

var altura_vuelo: float = 7.5
var radio_orbita: float = 6.0
var angulo_orbita_actual: float = 0.0
var objetivo_orbitado: Node3D = null
var is_aircraft: bool = true

func _init() -> void:
	unit_id = "helicoptero_apache_era9"
	unit_name = "Helicóptero Apache"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 320.0
	salud_maxima = 320.0
	salud_actual = 320.0
	_daño_base = 25.0
	daño = 25.0
	rango_ataque = 20.0
	velocidad_ataque = 0.6
	speed = 8.0
	era_entrenada = 9

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("air_units")
	add_to_group("aircraft")
	add_to_group("military_units")
	add_to_group("units_3d")
	position.y = altura_vuelo
	_setup_apache_visuals()

func _setup_apache_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, -0.3, -1.8)
		add_child(muzzle)

	if not has_node("Fuselage"):
		var fuse := MeshInstance3D.new()
		fuse.name = "Fuselage"
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 0.9, 4.2)
		fuse.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.22, 0.25, 0.2) # Verde camuflaje oscuro
		fuse.material_override = mat
		add_child(fuse)

	if not has_node("MainRotor"):
		var rotor := MeshInstance3D.new()
		rotor.name = "MainRotor"
		var box_r := BoxMesh.new()
		box_r.size = Vector3(5.2, 0.04, 0.3)
		rotor.mesh = box_r
		rotor.position = Vector3(0.0, 0.6, 0.0)
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.12, 0.12, 0.14)
		rotor.material_override = mat_r
		add_child(rotor)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Mantiene altura media constante
	position.y = altura_vuelo

	# Si se encuentra en órbita activa alrededor de un objetivo, actualiza la trayectoria circular
	if is_orbiting and is_instance_valid(objetivo_orbitado):
		var pos_tgt: Vector3 = objetivo_orbitado.position if objetivo_orbitado.position != Vector3.ZERO else objetivo_orbitado.global_position
		angulo_orbita_actual += (speed / radio_orbita) * delta
		var pos_deseada: Vector3 = calcular_posicion_orbita(pos_tgt, radio_orbita, angulo_orbita_actual)
		position = pos_deseada

## Fija un objetivo terrestre e inicia la maniobra de órbita circular
func iniciar_orbita(target: Node3D, radio: float = 6.0) -> void:
	if not is_instance_valid(target):
		return
	objetivo_orbitado = target
	radio_orbita = radio
	is_orbiting = true

## Detiene la órbita
func detener_orbita() -> void:
	is_orbiting = false
	objetivo_orbitado = null

## Calcula la posición en el perímetro circular según el ángulo
func calcular_posicion_orbita(centro: Vector3, radio: float, angulo: float) -> Vector3:
	return Vector3(
		centro.x + sin(angulo) * radio,
		altura_vuelo,
		centro.z + cos(angulo) * radio
	)

## Dispara una ráfaga continua de ametralladora rotatoria sin detener su desplazamiento
func disparar_rafaga_orbita(target: Node3D) -> int:
	if not is_instance_valid(target):
		return 0

	var disparos: int = 4
	var dmg_por_disparo: float = CombatDamageCalculator.calcular_dano(daño * 0.5, "gun", self, target)
	for i in range(disparos):
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg_por_disparo)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg_por_disparo))

	rafaga_orbita_disparada.emit(target.position if target.position != Vector3.ZERO else target.global_position, disparos)
	return disparos
