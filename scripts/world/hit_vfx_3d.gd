## HitVFX3D — Efecto Visual 3D de Impacto en Combate y Recolección (GDScript 2.0 / Godot 4).
##
## Muestra destellos y partículas 3D de impacto diferenciados según el tipo de material:
## - "madera": Astillas marrones de troncos.
## - "piedra" / "metal": Chispas brillantes naranjas/doradas.
## - "sangre": Salpicaduras de combate orgánico.
## - "plasma": Destellos de energía azul/cian futurista.

class_name HitVFX3D
extends Node3D

@export var tipo_impacto: String = "piedra"
const LIFETIME: float = 0.45

var _timer: float = 0.0
var _mesh_instance: MeshInstance3D = null
var _cpu_particles: CPUParticles3D = null

static func create_hit_vfx(pos: Vector3, parent: Node = null, tipo: String = "piedra") -> HitVFX3D:
	if not is_instance_valid(parent) and Engine.has_singleton("SceneTree"):
		parent = (Engine.get_singleton("SceneTree") as SceneTree).current_scene

	if not is_instance_valid(parent):
		return null

	var vfx := HitVFX3D.new()
	vfx.tipo_impacto = tipo
	parent.add_child(vfx)
	vfx.global_position = pos
	return vfx

static func create_at(parent: Node, pos: Vector3) -> HitVFX3D:
	return create_hit_vfx(pos, parent, "piedra")

func _ready() -> void:
	emitir_impacto(tipo_impacto)

func emitir_impacto(tipo: String) -> void:
	tipo_impacto = tipo

	# 1. Crear malla central emisiva
	if not is_instance_valid(_mesh_instance):
		_mesh_instance = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		_mesh_instance.mesh = sphere
		add_child(_mesh_instance)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true

	match tipo.to_lower():
		"madera":
			mat.albedo_color = Color(0.55, 0.35, 0.15, 0.9)
			mat.emission = Color(0.65, 0.45, 0.2)
			mat.emission_energy_multiplier = 1.8
		"sangre":
			mat.albedo_color = Color(0.85, 0.05, 0.05, 0.95)
			mat.emission = Color(0.9, 0.1, 0.1)
			mat.emission_energy_multiplier = 2.5
		"plasma":
			mat.albedo_color = Color(0.1, 0.85, 1.0, 0.95)
			mat.emission = Color(0.2, 0.9, 1.0)
			mat.emission_energy_multiplier = 4.0
		_: # "piedra", "metal"
			mat.albedo_color = Color(1.0, 0.6, 0.1, 0.95)
			mat.emission = Color(1.0, 0.7, 0.2)
			mat.emission_energy_multiplier = 3.5

	_mesh_instance.material_override = mat

	# 2. Crear emisor de partículas 3D
	_setup_cpu_particles(mat.emission)

func _setup_cpu_particles(particle_color: Color) -> void:
	if is_instance_valid(_cpu_particles):
		_cpu_particles.queue_free()

	_cpu_particles = CPUParticles3D.new()
	_cpu_particles.amount = 12
	_cpu_particles.lifetime = 0.4
	_cpu_particles.one_shot = true
	_cpu_particles.explosiveness = 0.9
	_cpu_particles.direction = Vector3(0, 1, 0)
	_cpu_particles.spread = 180.0
	_cpu_particles.initial_velocity_min = 3.0
	_cpu_particles.initial_velocity_max = 6.0
	_cpu_particles.scale_amount_min = 0.1
	_cpu_particles.scale_amount_max = 0.3

	var p_mesh := SphereMesh.new()
	p_mesh.radius = 0.08
	p_mesh.height = 0.16

	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = particle_color
	p_mat.emission_enabled = true
	p_mat.emission = particle_color
	p_mat.emission_energy_multiplier = 2.0
	p_mesh.material = p_mat

	_cpu_particles.mesh = p_mesh
	add_child(_cpu_particles)
	_cpu_particles.emitting = true

func _process(delta: float) -> void:
	_timer += delta
	var progress := _timer / LIFETIME

	if is_instance_valid(_mesh_instance):
		var s := 1.0 + progress * 2.0
		_mesh_instance.scale = Vector3(s, s, s)

	if _timer >= LIFETIME:
		queue_free()
