## Chariot_Archer_Era2 — Carro de Guerra de Rango (Edad del Cobre / Era 2).
##
## Primer vehículo veloz del juego (velocidad base 6.0 m/s).
## Hereda propiedades físicas de vehículo (ArmorType.CAVALRY / vehículo),
## requiere socket dual 'ProjectileMuzzle' y emite partículas de polvo continuo
## al desplazarse en physics_update.
class_name Chariot_Archer_Era2
extends "res://scripts/units/soldier_3d.gd"

var is_vehicle: bool = true
var dust_particles: GPUParticles3D = null

func _init() -> void:
	unit_id = "chariot_archer_era2"
	unit_name = "Carro de Guerra de Rango"
	attack_type = "ranged"
	weapon_type = "arrow"
	projectile_type = "arrow"
	_salud_base = 180.0
	salud_maxima = 180.0
	salud_actual = 180.0
	_daño_base = 14.0
	daño = 14.0
	rango_ataque = 14.0
	velocidad_ataque = 1.2
	speed = 6.0  # Velocidad base 6.0 m/s
	era_entrenada = 2

func _ready() -> void:
	super._ready()
	add_to_group("vehicles_3d")
	add_to_group("cavalry")
	add_to_group("chariots")
	_setup_dual_projectile_muzzles()
	_setup_dust_particles()

func _setup_dual_projectile_muzzles() -> void:
	# Socket dual ProjectileMuzzle en el arco del placeholder
	if not has_node("ProjectileMuzzle"):
		var muzzle1 := Marker3D.new()
		muzzle1.name = "ProjectileMuzzle"
		muzzle1.position = Vector3(0.3, 1.2, -0.6)
		add_child(muzzle1)

	if not has_node("ProjectileMuzzle_Dual"):
		var muzzle2 := Marker3D.new()
		muzzle2.name = "ProjectileMuzzle_Dual"
		muzzle2.position = Vector3(-0.3, 1.2, -0.6)
		add_child(muzzle2)

func _setup_dust_particles() -> void:
	dust_particles = get_node_or_null("ChariotDustParticles") as GPUParticles3D
	if not is_instance_valid(dust_particles):
		dust_particles = GPUParticles3D.new()
		dust_particles.name = "ChariotDustParticles"
		dust_particles.emitting = false
		dust_particles.amount = 16
		dust_particles.lifetime = 0.5
		dust_particles.position = Vector3(0.0, 0.1, 0.8)
		add_child(dust_particles)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_emit_movement_dust()

func physics_update(delta: float) -> void:
	_emit_movement_dust()

func _emit_movement_dust() -> void:
	if is_instance_valid(dust_particles):
		var is_moving: bool = velocity.length_squared() > 0.2
		if dust_particles.emitting != is_moving:
			dust_particles.emitting = is_moving
